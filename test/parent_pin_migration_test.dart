import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yes_sir_ai/features/parent/parent_pin_store.dart';

/// Legacy v1 hash, replicated here only to seed a pre-migration device.
String fnv1a(String pin) {
  var h = 0x811c9dc5;
  for (final c in ('yes-sir-ai-parent-pin-v1$pin').codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h.toRadixString(16).padLeft(8, '0');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('legacy v1 PIN verifies once, then migrates to v2', () async {
    SharedPreferences.setMockInitialValues({
      'parent_pin_hash_v1': fnv1a('1234'),
    });
    final store = ParentPinStore();
    expect(await store.hasPin(), isTrue);
    expect(await store.verify('1234'), isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('parent_pin_hash_v1'), isNull);
    expect(prefs.getString('parent_pin_hash_v2'), startsWith('v2:'));
    // Second unlock uses v2 only.
    expect(await store.verify('1234'), isTrue);
    expect(await store.verify('0000'), isFalse);
  });

  test('wrong v1 guess does not migrate anything', () async {
    SharedPreferences.setMockInitialValues({
      'parent_pin_hash_v1': fnv1a('1234'),
    });
    final store = ParentPinStore();
    expect(await store.verify('9999'), isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('parent_pin_hash_v1'), fnv1a('1234'));
    expect(prefs.getString('parent_pin_hash_v2'), isNull);
  });

  test('new setPin writes v2 only, clearPin removes both', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ParentPinStore();
    await store.setPin('5678');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('parent_pin_hash_v1'), isNull);
    expect(prefs.getString('parent_pin_hash_v2'), startsWith('v2:'));
    expect(await store.verify('5678'), isTrue);
    await store.clearPin();
    expect(await store.hasPin(), isFalse);
  });
}
