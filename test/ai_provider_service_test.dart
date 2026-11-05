// AI provider preference (2026-11-04): default openrouter,
// saved gemini sticks, unknown values normalise to openrouter.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yes_sir_ai/core/services/ai_provider_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('default is openrouter when nothing is saved', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await aiProviderService.load(), AiProviderService.openRouter);
  });

  test('saved gemini sticks across loads', () async {
    SharedPreferences.setMockInitialValues({});
    await aiProviderService.save(AiProviderService.gemini);
    expect(await aiProviderService.load(), AiProviderService.gemini);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(AiProviderService.prefsKey),
      AiProviderService.gemini,
    );
  });

  test('unknown saved value normalises to openrouter', () async {
    SharedPreferences.setMockInitialValues(
      {AiProviderService.prefsKey: 'bogus-model'},
    );
    expect(await aiProviderService.load(), AiProviderService.openRouter);
    await aiProviderService.save('bogus-model');
    expect(await aiProviderService.load(), AiProviderService.openRouter);
  });
}
