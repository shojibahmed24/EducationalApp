# Registration wizard - integration notes (UI only)

- Individual routes (integration agent adds these to lib/router/app_router.dart;
  this agent did NOT edit the router):
  /register/welcome, /register/name, /register/gender, /register/class,
  /register/medium, /register/school, /register/contact, /register/password,
  /register/otp, /register/goal, /register/guardian, /register/review,
  /register/success -> /home (existing route).
- OR mount RegistrationWizard at /register; it slides between steps.
- Data: lib/features/registration/registration_data.dart (local mock
  ValueNotifier). TODO backend: replace with Supabase Auth + profile insert
  on Step 12 confirm; OTP/password are mock-only here, never sent.
- Language: every step has a toggle in RegScaffold (AppBar, বাংলা/English)
  via lib/l10n/language_provider.dart; every step has its strings file in
  lib/l10n/pages/reg_stepXX_strings.dart (bn + en together).
- Gender and class appear ONLY in this wizard, nowhere else in the app.
- Style: AppTheme only (Warm Paper Scholar from Stitch DESIGN.md).
- No file in this folder exceeds 250 lines (see line counts in delivery).
