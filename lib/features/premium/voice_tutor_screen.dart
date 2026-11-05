// Route: /voice — PREMIUM-ONLY and ISOLATED.
// Voice call lives ONLY here, never in lesson, practice, quiz
// or text chat. Premium gate FIRST: a non-premium user sees
// only the paywall gate, never the call UI — except the DEMO
// test path (item 7): in DEMO mode with the Settings DEMO test
// switch ON, the gate opens for testing and the session is
// labelled DEMO test, never real premium. Then the 30-min
// budget is checked before starting. Start runs a real timer;
// End counts the elapsed minutes (rounded up, min 1) against
// the budget and persists them. Live transport is unwired and no
// key lives in the app, so every session is a local DEMO practice
// session, labelled as such and never presented as a Gemini call.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/ai_voice_service.dart';
import '../../core/services/billing_service.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/premium_strings.dart';
import '../../theme/app_theme.dart';

class VoiceTutorScreen extends StatefulWidget {
  const VoiceTutorScreen({super.key});
  @override
  State<VoiceTutorScreen> createState() => _VoiceTutorScreenState();
}

class _VoiceTutorScreenState extends State<VoiceTutorScreen> {
  bool _loading = true;
  // Gate, not a premium claim: true via real premium OR via the
  // DEMO-only test switch (item 7). _isDemoTestGate tracks the
  // test path separately so the screen can label it as DEMO
  // test, never as real premium.
  bool _isPremium = false;
  bool _isDemoTestGate = false;
  bool _inCall = false;
  bool _isDemo = true;
  int _remaining = 0;
  int _elapsedSec = 0;
  int _sessionCapMin = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final premium = await billingService.isPremium();
    final demoTest = await billingService.isDemoVoiceTestEnabled();
    final budget = await aiVoiceService.budget();
    if (!mounted) return;
    setState(() {
      _isPremium = premium || demoTest;
      _isDemoTestGate = demoTest && !premium;
      _remaining = budget.remaining;
      _loading = false;
    });
  }

  int get _usedMin {
    if (_elapsedSec <= 0) return 0;
    final m = (_elapsedSec + 59) ~/ 60;
    return m > _sessionCapMin ? _sessionCapMin : m;
  }

  String get _clock {
    final m = (_elapsedSec ~/ 60).toString().padLeft(2, '0');
    final sec = (_elapsedSec % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  Future<void> _start() async {
    final s = isBangla ? premiumStringsBn : premiumStringsEn;
    final state = await aiVoiceService.startCall();
    if (!mounted) return;
    if (state == VoiceState.notPremium) {
      context.push('/premium');
      return;
    }
    if (state == VoiceState.noMinutes) {
      await _refresh();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s['exhausted']!)));
      return;
    }
    final budget = await aiVoiceService.budget();
    if (!mounted) return;
    setState(() {
      _inCall = true;
      _isDemo = state == VoiceState.demo;
      _elapsedSec = 0;
      _sessionCapMin = budget.remaining;
      _remaining = budget.remaining;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSec++);
      if (_elapsedSec >= _sessionCapMin * 60) _end(auto: true);
    });
  }

  Future<void> _end({bool auto = false}) async {
    final s = isBangla ? premiumStringsBn : premiumStringsEn;
    _timer?.cancel();
    final minutes = _usedMin;
    setState(() => _inCall = false);
    if (minutes > 0) await aiVoiceService.endCall(minutes);
    await _refresh();
    if (!mounted) return;
    if (minutes > 0 || auto) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text("${s['callEnded']!} $minutes ${s['minutesUnit']!}")));
    }
  }

  Future<void> _backHome() async {
    if (_inCall) await _end();
    if (!mounted) return;
    context.go('/home');
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_inCall && _usedMin > 0) aiVoiceService.endCall(_usedMin);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = isBangla ? premiumStringsBn : premiumStringsEn;
    if (_loading) {
      return Scaffold(
          appBar: AppBar(title: Text(s['voiceTitle']!)),
          body: const Center(child: CircularProgressIndicator()));
    }
    if (!_isPremium) {
      return Scaffold(
        appBar: AppBar(title: Text(s['voiceTitle']!)),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mic_off, size: 64, color: AppTheme.error),
                const SizedBox(height: 16),
                Text(s['notPremium']!,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                    onPressed: () => context.push('/premium'),
                    child: Text(s['goPremium']!)),
                const SizedBox(height: 12),
                OutlinedButton(
                    onPressed: () => context.go('/home'),
                    child: Text(s['backHome']!)),
              ]),
        ),
      );
    }
    final exhausted = !_inCall && _remaining <= 0;
    return Scaffold(
      appBar: AppBar(title: Text(s['voiceTitle']!)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(s['voiceSub']!,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              CircleAvatar(
                  radius: 64,
                  backgroundColor:
                      _inCall ? AppTheme.success : AppTheme.primary,
                  child: Icon(_inCall ? Icons.mic : Icons.mic_none,
                      size: 56, color: Colors.white)),
              const SizedBox(height: 16),
              if (_inCall) ...[
                Text(_clock,
                    style: Theme.of(context).textTheme.displayLarge,
                    textAlign: TextAlign.center),
                Text(
                    _isDemo ? s['callActiveDemo']! : s['callActiveLive']!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(_isDemo ? s['demoPracticeNote']! : s['liveNote']!,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center),
              ] else if (exhausted)
                Text(s['exhausted']!,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center)
              else
                Column(children: [
                  Text(
                      "${s['remainingLabel']!}: $_remaining ${s['minutesUnit']!} ${s['perMonth']!}",
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center),
                  if (_isDemoTestGate) ...[
                    const SizedBox(height: 8),
                    Text(s['demoTestGateNote']!,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center),
                  ],
                ]),
              const SizedBox(height: 24),
              if (!exhausted)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _inCall ? AppTheme.error : AppTheme.primary,
                      foregroundColor: Colors.white),
                  onPressed: _inCall ? () => _end() : _start,
                  child: Text(_inCall ? s['endCall']! : s['startCall']!),
                ),
              const SizedBox(height: 12),
              OutlinedButton(
                  onPressed: _backHome, child: Text(s['backHome']!)),
            ]),
      ),
    );
  }
}
