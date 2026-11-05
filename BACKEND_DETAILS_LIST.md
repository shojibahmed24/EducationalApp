# Yes Sir AI - backend details to supply at the end (~10 minutes)

Give these to Muse at the end. Do NOT paste real keys in a normal
chat message if a secure vault / secure flow is offered - use that.
Until these arrive, the app runs in DEMO mode on local mock data.

## 1. Supabase (user opens the account)
- [ ] SUPABASE_URL - e.g. https://<project-ref>.supabase.co
- [ ] SUPABASE_ANON_KEY (public anon key, safe for the app build)
- [ ] SUPABASE_SERVICE_ROLE_KEY - SECURE VAULT ONLY, never in chat.
  Needed only for the book-index import + Play verification server,
  NOT baked into the app binary.
- [ ] Confirm the 5 migration files in supabase/migrations/ have been
  run in order (see supabase/MIGRATIONS_README.md).

## 2. Google authentication
- [ ] GOOGLE_OAUTH_CLIENT_ID (Android OAuth client)
- [ ] Supabase Dashboard -> Authentication -> Providers -> Google:
  enabled, with the same client id/secret.
- [ ] Android SHA-1 fingerprint registered in Google Cloud, if asked.

## 3. AI keys (service keys, secure flow preferred)
- [ ] OPENROUTER_API_KEY - for text chat / lesson explanations.
  Exact text model id to pin in the Edge Function env: TBD by user.
- [ ] GEMINI_API_KEY - for Gemini Live premium voice.
  Exact Gemini Live model id to pin: TBD by user.

## 4. Google Play (after the app is built, NOT before)
- [ ] Play Console developer account (in the user's own name).
- [ ] Subscription product created in Play Console:
  product id `yes_sir_ai_premium_monthly`, price $5/month.
- [ ] Developer name for the Play listing (TBD - do not invent one).

## 10-minute plug-in steps (once the above arrive)
1. Run: flutter run --dart-define=SUPABASE_URL=... \
   --dart-define=SUPABASE_ANON_KEY=... \
   --dart-define=GOOGLE_OAUTH_CLIENT_ID=... \
   --dart-define=OPENROUTER_API_KEY=... \
   --dart-define=GEMINI_API_KEY=... \
   --dart-define=PLAY_SUBSCRIPTION_PRODUCT_ID=yes_sir_ai_premium_monthly
2. Confirm the DEMO banner disappears on the login screen.
3. Test: sign up -> profile row in Supabase -> login -> lesson ->
   paywall -> voice gate (premium only, 30 min/month).
4. Do NOT add a bKash button, do NOT store audio, do NOT write
   subscription_entitlements from the app.

## What is already done (no keys needed)
- Supabase client + AuthService + ProfileService (DEMO fallback)
- Books / learn (no-guess gate) / practice / progress services
- OpenRouter text service, Gemini voice gate, Play Billing service
- 5 migration SQL files with RLS, in run order

## Phase 2 (C2) — book-grounded AI explanations (2026-10-28)

Summary of `BOOK_IMPORT_CONTRACT.md` (the full contract lives there;
this section is only the plug-in checklist for it).

- Architecture: the app NEVER reads `book_questions` from the
  client (no client RLS policy, by design). The Edge Function
  `supabase/functions/explain-question/` reads it with the
  service-role key and returns one matched question's public fields
  (book/chapter titles, page, problem, verbatim question text) to
  a signed-in user. It never returns `source_link`.
- [ ] Deploy the Edge Function (steps in its README):
  `supabase link`, `supabase secrets set
  SUPABASE_SERVICE_ROLE_KEY=<via secure vault only>`,
  `supabase functions deploy explain-question`. Keep `verify_jwt`
  true. The app derives the endpoint from `SUPABASE_URL`
  (`.../functions/v1/explain-question`); override only with
  `--dart-define=EXPLAIN_FUNCTION_URL=...`.
- [ ] Build with `--dart-define=OPENROUTER_API_KEY=...` (secure
  flow; never in a file or in chat). Without it, grounded answers
  show labelled DEMO; without the deployed function, lesson/chat
  fall back to the chapters check and quiz to the labelled DEMO
  bank — both honest, neither a guessed answer.
- [ ] Import `book_questions` rows per the contract (verbatim
  question text, PRINTED page numbers, ids
  `{book_id}-ch{n}-p{page}-q{problem}`; guides link to the
  textbook's `chapter_id`, never as second book rows; never add a
  client read policy to `books`/`book_questions`).
- [ ] Verify after deploy + import: Edge curl returns `found: true`
  for a real imported question and `found: false` for an absent
  one; then in-app: Search exact question -> lesson opens with the
  book wording; quiz check -> live AI explanation (or honest DEMO /
  "not in the book index" when the lookup misses).
- Current state: Class 6 books (44) + chapters (462) are imported;
  `book_questions` rows are still the pending import, so until
  they land the Edge Function honestly returns `not-indexed`.
- App code path: `lib/core/services/explanation_service.dart`
  (resolve + OpenRouter with full book context) ->
  `ai_text_service.dart` (lesson adapter) ->
  `lesson_screen.dart`, `chat_screen.dart` (typed follow-up IS
  sent to the AI), `quiz_question_screen.dart` (book lookup by
  question wording; live-but-unmatched is never the DEMO bank).

