// Parent PIN, local only. The PIN is never stored as plain text.
// MIGRATION (2026-10-31, dual-verify + lazy rehash): old installs
// hold a v1 hash (FNV-1a, 32-bit, fixed salt). New PINs are stored
// as v2: per-PIN random salt + iterated SHA-256 (256-bit, no shared
// salt, no rainbow-table shortcut). verify() accepts a v1 hash AND,
// on a correct v1 match only, rewrites it as v2 and deletes v1 —
// existing PINs keep working, no forced reset, and after one
// successful unlock no v1 hash remains on the device. A wrong v1
// guess never migrates anything.
// Honest limit, unchanged by v2: a 4-digit PIN has only 10,000
// values, so the real brute-force gate is still the persisted
// attempt limit below, not the hash. Once a server-verified parent
// flow exists, this local hash must stop being the gate (see
// BACKEND_DETAILS_LIST.md). There is deliberately NO in-app
// forgot-PIN erase: a forgotten PIN must never be erasable from
// the device with no identity check. clearPin() below is
// DIFFERENT: it runs only on sign-out (Phase 16, M11), so the next
// account must set its own PIN instead of inheriting the previous
// parent's PIN. It is never called from the forgot-PIN path, which
// stays blocked.
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ParentPinStore {
  static const _key = 'parent_pin_hash_v1';
  static const _keyV2 = 'parent_pin_hash_v2';
  static const _salt = 'yes-sir-ai-parent-pin-v1';
  static const _failKey = 'parent_pin_fail_count_v1';
  static const _lockKey = 'parent_pin_locked_until_ms_v1';

  /// Failed verifies before a timed lockout. Setup/confirm
  /// mismatches (no PIN set yet) are NOT counted.
  static const maxAttempts = 5;

  /// Lockout after [maxAttempts] consecutive failures.
  static const lockout = Duration(minutes: 5);

  /// Iterations for the v2 hash. Small input, once per unlock;
  /// 1,000 rounds is negligible on a phone and still slows a
  /// bulk offline guess far below a single SHA-256.
  static const _v2Iterations = 1000;

  static String _hashV1(String pin) {
    var h = 0x811c9dc5;
    for (final c in (_salt + pin).codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h.toRadixString(16).padLeft(8, '0');
  }

  static String _hashV2(String pin, List<int> salt) {
    var bytes = <int>[...salt, ...utf8.encode(pin)];
    for (var i = 0; i < _v2Iterations; i++) {
      bytes = sha256.convert(bytes).bytes;
    }
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static String _encodeV2(String pin) {
    final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final saltHex =
        salt.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return 'v2:$saltHex:${_hashV2(pin, salt)}';
  }

  static bool _matchesV2(String stored, String pin) {
    final parts = stored.split(':');
    if (parts.length != 3 || parts[0] != 'v2') return false;
    final saltHex = parts[1];
    if (saltHex.length != 32) return false;
    final salt = <int>[];
    for (var i = 0; i < saltHex.length; i += 2) {
      final byte = int.tryParse(saltHex.substring(i, i + 2), radix: 16);
      if (byte == null) return false;
      salt.add(byte);
    }
    return _hashV2(pin, salt) == parts[2];
  }

  Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyV2) != null ||
        prefs.getString(_key) != null;
  }

  Future<bool> verify(String pin) async {
    if (pin.length != 4) return false;
    final prefs = await SharedPreferences.getInstance();
    final storedV2 = prefs.getString(_keyV2);
    if (storedV2 != null) return _matchesV2(storedV2, pin);
    final storedV1 = prefs.getString(_key);
    if (storedV1 == null || storedV1 != _hashV1(pin)) return false;
    // Correct v1 match only: lazy rehash to v2, then drop v1.
    await prefs.setString(_keyV2, _encodeV2(pin));
    await prefs.remove(_key);
    return true;
  }

  /// Phase 16 (M11): sign-out only. Removes the PIN hash and any
  /// failure/lockout state, so the next account starts PIN-less.
  /// NOT used by forgot-PIN (that path stays blocked by design).
  Future<void> clearPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove(_keyV2);
    await clearFailures();
  }

  Future<void> setPin(String pin) async {
    assert(pin.length == 4);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyV2, _encodeV2(pin));
    await prefs.remove(_key);
    await clearFailures();
  }

  Future<int> failedCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_failKey) ?? 0;
  }

  Future<DateTime?> lockoutUntil() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_lockKey);
    if (ms == null) return null;
    final until = DateTime.fromMillisecondsSinceEpoch(ms);
    if (DateTime.now().isAfter(until)) return null;
    return until;
  }

  /// Records one failed verify. Returns the lockout end time when
  /// this failure trips the limit, else null. An expired lockout
  /// resets the counter before counting, so a later failure
  /// starts a fresh run of [maxAttempts].
  Future<DateTime?> recordFailure() async {
    final prefs = await SharedPreferences.getInstance();
    final oldLock = prefs.getInt(_lockKey);
    var count = prefs.getInt(_failKey) ?? 0;
    if (oldLock != null &&
        DateTime.now()
            .isAfter(DateTime.fromMillisecondsSinceEpoch(oldLock))) {
      count = 0;
      await prefs.remove(_lockKey);
    }
    count += 1;
    await prefs.setInt(_failKey, count);
    if (count < maxAttempts) return null;
    final until = DateTime.now().add(lockout);
    await prefs.setInt(_lockKey, until.millisecondsSinceEpoch);
    return until;
  }

  Future<void> clearFailures() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_failKey);
    await prefs.remove(_lockKey);
  }
}

final parentPinStore = ParentPinStore();
