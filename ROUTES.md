# Yes Sir AI — Route map (UI phase, no backend yet)

Router: `lib/router/app_router.dart` (19 lines) assembles per-group files:
`router/auth_routes.dart`, `router/registration_routes.dart`,
`router/learn_routes.dart`, `router/practice_routes.dart`,
`router/profile_routes.dart`. All router files are under 250 lines.
Initial location: `/splash`.

## Auth (8)
| Route | Screen file |
|---|---|
| /splash | lib/features/auth/splash_screen.dart (SplashScreen) |
| /onboarding-1 | lib/features/auth/onboarding_step1_screen.dart |
| /onboarding-2 | lib/features/auth/onboarding_step2_screen.dart |
| /onboarding-3 | lib/features/auth/onboarding_step3_screen.dart |
| /login | lib/features/auth/login_screen.dart (LoginScreen) |
| /forgot-password | lib/features/auth/forgot_password_screen.dart |
| /otp | lib/features/auth/otp_screen.dart |
| /reset-password | lib/features/auth/reset_password_screen.dart |

## Registration wizard (13)
| Route | Screen file |
|---|---|
| /register/welcome | lib/features/registration/steps/step01_welcome.dart |
| /register/name | lib/features/registration/steps/step02_name.dart |
| /register/gender | lib/features/registration/steps/step03_gender.dart |
| /register/class | lib/features/registration/steps/step04_class.dart |
| /register/medium | lib/features/registration/steps/step05_medium.dart |
| /register/school | lib/features/registration/steps/step06_school.dart |
| /register/contact | lib/features/registration/steps/step07_contact.dart |
| /register/password | lib/features/registration/steps/step08_password.dart |
| /register/otp | lib/features/registration/steps/step09_otp.dart |
| /register/goal | lib/features/registration/steps/step10_goal.dart |
| /register/guardian | lib/features/registration/steps/step11_guardian.dart |
| /register/review | lib/features/registration/steps/step12_review.dart |
| /register/success | lib/features/registration/steps/step13_success.dart |

## Home + Learn (7)
| Route | Screen file |
|---|---|
| /home | lib/features/home/home_screen.dart (HomeScreen) |
| /home/subjects | lib/features/home/subjects_screen.dart |
| /home/subjects/:subjectId/chapters | lib/features/learn/chapters_screen.dart (subjectId param, default 'math'; e.g. /home/subjects/math/chapters) |
| /search | lib/features/learn/search_screen.dart |
| /lesson | lib/features/learn/lesson_screen.dart |
| /lesson/chat | lib/features/learn/chat_screen.dart |
| /lesson/no-match | lib/features/learn/no_match_screen.dart |

## Practice + Books + Progress (12)
| Route | Screen file |
|---|---|
| /practice | lib/features/practice/practice_screen.dart |
| /practice-tab | lib/features/practice/practice_tab_screen.dart |
| /quiz | lib/features/practice/quiz_question_screen.dart |
| /quiz-results | lib/features/practice/quiz_results_screen.dart |
| /model-tests | lib/features/practice/model_test_list_screen.dart |
| /model-test-exam | lib/features/practice/model_test_exam_screen.dart |
| /model-test-results | lib/features/practice/model_test_results_screen.dart |
| /books | lib/features/books/book_library_screen.dart |
| /books/viewer | lib/features/books/book_page_viewer_screen.dart |
| /progress | lib/features/progress/progress_screen.dart |
| /achievements | lib/features/progress/achievements_screen.dart |
| /saved | lib/features/progress/saved_questions_screen.dart |

## Profile + Parent + Premium (9)
| Route | Screen file |
|---|---|
| /profile | lib/features/profile/profile_screen.dart |
| /settings | lib/features/profile/settings_screen.dart |
| /notifications | lib/features/profile/notifications_screen.dart |
| /help | lib/features/profile/help_faq_screen.dart |
| /about | lib/features/profile/about_screen.dart |
| /parent-pin | lib/features/parent/parent_pin_screen.dart |
| /parent-dashboard | lib/features/parent/parent_dashboard_screen.dart |
| /premium | lib/features/premium/premium_paywall_screen.dart |
| /voice | lib/features/premium/voice_tutor_screen.dart |

Total: 49 unique routes, 0 duplicates. All 47 `context.go/push` targets
found in screen files resolve to a route above (the param chapters route
covers /home/subjects/math/chapters).

## Fixes made by integration (not by changing screen designs)
1. Login "new account" link pointed to non-existent `/registration` — fixed
   in login_screen.dart to `/register/welcome` (wizard entry).
2. BookPageViewer "View Explanation" button pointed to `/practice` —
   fixed in book_page_viewer_screen.dart to `/lesson`.
3. Global themeMode wired: `lib/theme/theme_mode.dart` (new, 7 lines)
   holds `themeModeNotifier`; `lib/app.dart` now listens to it;
   SettingsScreen night/day selection sets it (day/sepia -> light, because
   AppTheme has no sepia theme — sepia falling back to light is a known
   limitation, not a silent change of design). Settings font-size and
   class-change remain local UI-only state, as built.

## Not verified
- No `flutter analyze` / `flutter build` run: no Dart/Flutter toolchain
  in this VM. Brace/paren/bracket balance is 0 (balanced) on every file
  created or edited here, and on all 49 routes, but a compile pass is
  still owed before calling this verified.
- No backend calls added: all screens remain UI-only with // TODO backend
  mocks, as instructed. No pubspec dependencies changed, no screen colours
  or strings files changed.
