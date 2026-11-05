# Yes Sir AI — Pre-APK Audit Report (2026-10-28)

## Original crash
- Release APK installed, but closed immediately on launch.
- Root cause (verified): `google_mobile_ads` in pubspec, with NO AdMob
  APPLICATION_ID in AndroidManifest and NO Dart usage. The plugin's
  MobileAdsInitProvider auto-initializes at startup and crashes without
  an App ID.
- Fix applied: google_mobile_ads removed from pubspec.yaml (verified
  gone from pubspec, pubspec.lock, Dart code, AndroidManifest).

## CRITICAL — no other verified launch blocker found
1. Supabase init: guarded by AppConfig.supabaseConfigured + try/catch,
   falls back to DEMO mode. Current build has no dart-defines, so DEMO.
2. Splash flow: only SharedPreferences reads, 2.5s delay, mounted check,
   no network call, no throw path.
3. In-app purchase: only touched in paywall buy()/restore(), not startup.
   No manifest value needed.
4. Voice/AI: only from VoiceTutorScreen / lesson/chat, not startup.
5. Remaining plugins: go_router, flutter_riverpod, supabase_flutter,
   in_app_purchase, shared_preferences (+ transitive app_links,
   url_launcher, path_provider). None needs a manifest App ID/API key,
   none auto-initializes into a crash at startup.
6. Assets: NO Image.asset/AssetImage/rootBundle reference existed in
   Dart code, so no missing-asset crash path (before logo fix).
7. String `!` assertions: splash keys and onboarding-1 keys verified
   present in both bn and en maps.
8. SDK: minSdk 23, targetSdk 35, compileSdk 35. TECNO SPARK 40 Pro is
   above minSdk 23.
9. Manifest: MainActivity exported, LAUNCHER intent-filter, NormalTheme
   meta-data correct, no provider/meta-data with empty value.
10. flutter analyze: No issues found.

## Limitation (honest)
Static audit only, not run on a device. A native crash outside Dart
(e.g. wrong ABI) cannot be ruled out from here — NOT a guess, unknown.
arm64 APK verified to contain lib/arm64-v8a/libapp.so + libflutter.so.

## Logo fix (applied after audit, with audit warning observed)
- User logo pack was never used; app showed a code-drawn robot avatar.
- Fix: user-pack Android res copied as launcher icons; splash now uses
  assets/logo/yes-sir-ai-icon.png (512px, verified PNG); pubspec assets
  section added together with the real PNG files, so splash cannot hit
  an asset-not-found crash. Unused robot_avatar import removed.
- Warning honored: asset + pubspec entry were added together.

## MINOR — does not block launch, fix before Play
1. android/build.gradle.kts still points only at the local Maven repo
   (/home/hatch/workspace/_maven-repo). Outside the VM, or if that repo
   is wiped, the build fails. Restore google(), mavenCentral(),
   gradlePluginPortal() for a PC build.
2. android/local.properties contains VM SDK paths; delete before any
   PC zip.
3. Release signing uses the debug keystore. Installs fine for testing,
   Play Store will not accept it; a real keystore is needed before Play.
4. Hind Siliguri font is referenced in app_theme.dart but no fonts
   section / .ttf is bundled. No crash — system font fallback, Bangla
   may look different.

## Status
Final release build (ads removed + logo added) is running. New APK link
will be delivered when it finishes; uninstall the old APK first.
