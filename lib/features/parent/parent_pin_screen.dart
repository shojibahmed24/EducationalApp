// Route: /parent-pin
// Real PIN gate (local): if no PIN was ever set, the user sets one
// (enter twice, must match); if a PIN was set, only that PIN opens
// /parent-dashboard, and only via the session flag: success calls
// parentSession.markVerified() and the router redirect blocks the
// dashboard without that flag. Forgot PIN NEVER erases the old PIN
// and never opens the dashboard: without an identity check (account
// password / Supabase re-auth, not yet configured) reset is refused
// with an honest message. After 5 wrong PINs the keypad locks for
// 5 minutes (persisted, so restarting the app does not reset it).
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/parent_strings.dart';
import '../../theme/app_theme.dart';
import 'parent_pin_store.dart';
import 'parent_session.dart';

class ParentPinScreen extends StatefulWidget {
  const ParentPinScreen({super.key});
  @override
  State<ParentPinScreen> createState() => _ParentPinScreenState();
}

class _ParentPinScreenState extends State<ParentPinScreen> {
  String _pin = '';
  String? _firstPin;
  bool? _hasPin;
  String? _error;
  DateTime? _lockoutUntil;
  Timer? _lockTimer;

  bool get _settingUp => _hasPin == false;
  bool get _confirming => _firstPin != null;
  bool get _locked =>
      _lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!);

  @override
  void initState() {
    super.initState();
    parentPinStore.hasPin().then((v) {
      if (mounted) setState(() => _hasPin = v);
    });
    parentPinStore.lockoutUntil().then((until) {
      if (mounted && until != null) _startLockTimer(until);
    });
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    super.dispose();
  }

  void _startLockTimer(DateTime until) {
    _lockTimer?.cancel();
    setState(() => _lockoutUntil = until);
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      if (DateTime.now().isAfter(until)) {
        _lockTimer?.cancel();
        await parentPinStore.clearFailures();
        if (mounted) setState(() { _lockoutUntil = null; _error = null; });
      } else {
        setState(() {});
      }
    });
  }

  String _lockedText(Map<String, String> s) {
    final left = _lockoutUntil!.difference(DateTime.now());
    final t = '${left.inMinutes}:${(left.inSeconds % 60).toString().padLeft(2, '0')}';
    return s['pinLocked']!.replaceAll('{t}', t);
  }

  Future<void> _onComplete(String entered) async {
    final s = isBangla ? parentStringsBn : parentStringsEn;
    if (_settingUp && !_confirming) {
      setState(() { _firstPin = entered; _pin = ''; _error = null; });
      return;
    }
    if (_settingUp && _confirming) {
      if (entered != _firstPin) {
        setState(() { _firstPin = null; _pin = ''; _error = s['pinMismatch']!; });
        return;
      }
      await parentPinStore.setPin(entered);
      parentSession.markVerified();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s['pinSet']!)));
      context.push('/parent-dashboard');
      return;
    }
    if (await parentPinStore.verify(entered)) {
      await parentPinStore.clearFailures();
      parentSession.markVerified();
      if (!mounted) return;
      context.push('/parent-dashboard');
    } else {
      final until = await parentPinStore.recordFailure();
      if (!mounted) return;
      if (until != null) {
        _startLockTimer(until);
      } else {
        final left =
            ParentPinStore.maxAttempts - await parentPinStore.failedCount();
        setState(() {
          _pin = '';
          _error =
              '${s['pinWrong']!} ${s['pinAttemptsLeft']!.replaceAll('{n}', '$left')}';
        });
      }
    }
  }

  void _press(String d) {
    if (_locked) return;
    setState(() {
      if (d == 'back') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else if (_pin.length < 4) {
        _pin += d;
      }
    });
    if (_pin.length == 4) _onComplete(_pin);
  }

  // Forgot PIN: NO reset from the device. The old PIN stays in
  // place; only a future server-side re-auth reset may change it.
  Future<void> _forgot() async {
    final s = isBangla ? parentStringsBn : parentStringsEn;
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(s['pinForgotBlockedTitle']!),
        content: Text(s['pinForgotBlockedBody']!),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text(s['pinForgotBlockedOk']!)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = isBangla ? parentStringsBn : parentStringsEn;
    if (_hasPin == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final sub = _settingUp
        ? (_confirming ? s['pinConfirmSub']! : s['pinSetupSub']!)
        : s['pinSub']!;
    final errorText = _locked ? _lockedText(s) : _error;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
        title: Text(s['pinTitle']!),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.lock, size: 56, color: AppTheme.primary),
            const SizedBox(height: 12),
            Text(sub,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                  4,
                  (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.primary)),
                        alignment: Alignment.center,
                        child: Text(i < _pin.length ? '•' : '',
                            style: const TextStyle(fontSize: 28)),
                      )),
            ),
            const SizedBox(height: 8),
            if (errorText != null)
              Text(errorText,
                  style: const TextStyle(color: AppTheme.error),
                  textAlign: TextAlign.center)
            else
              Text(s['pinHint']!,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                childAspectRatio: 1.6,
                children: [
                  for (final d in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'back'])
                    if (d.isEmpty)
                      const SizedBox()
                    else
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: ElevatedButton(
                            onPressed: _locked ? null : () => _press(d),
                            child: Text(d == 'back' ? '⌫' : d,
                                style: const TextStyle(fontSize: 20))),
                      ),
                ],
              ),
            ),
            if (!_settingUp)
              TextButton(onPressed: _forgot, child: Text(s['pinForgot']!)),
            Text(s['pinSecure']!,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
