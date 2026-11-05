# Question Generation — daily quiz + model tests (batch 2, items 8/9)

Status: generation path IMPLEMENTED; book-question pool NOT YET LIVE.
Read this before changing any quiz/model-test question source.

## 0. The one rule that matters

A generated quiz/model test must never present a question as
something it is not. Today that means two hard lines:

1. The practice bank (ids `mq`/`sq`/`mm`/`sm`) is a HAND-WRITTEN
   practice set. It is NEVER labelled a book question, and its
   scores are bank scores, not book scores.
2. Book questions (`book_questions` rows) carry `question_text`
   ONLY — no options, no verified answer. Turning one into a
   scored MCQ would require inventing options and an answer key,
   which would fake a score. So book rows are NEVER converted
   into `QuizItem`s in this codebase until a verified-options
   source exists (see §5).

## 1. How generation works today

```
pool (scorable QuizItems) ──► selectQuestions() ──► GeneratedSet
   ▲                              seed + chapter coverage
   │                              dedupe, no repeats in a set
   └─ practice bank ONLY, today (source = bankFallback)
```

- Selector: `lib/core/services/question_generation.dart`
  (`QuestionGenerationService.selectQuestions`). It dedupes by id,
  groups by a caller-supplied chapter key, shuffles each chapter
  deterministically from the seed (djb2 hash + LCG — Dart's
  `hashCode` is deliberately NOT used, it is not stable across
  runs), then deals round-robin across chapters: the first round
  covers every chapter before any chapter repeats. A set therefore
  never repeats a question, and with `count >= chapters` it always
  covers every chapter in the pool.
- Daily quiz: `practiceService.dailyQuizFor()` / async
  `practiceService.generateDailyQuiz()` — 5 questions, seed =
  `daily-<class>-<subject>-<yyyy-mm-dd>` (class from
  `profileService.loadSchoolClass()`, default 6). Same day = same
  set; a new day = a new set; no day repeats within itself.
- Model tests: `practiceService.modelItemsFor()` /
  `practiceService.modelTests()` — fixed count per subject
  (maths 10, science 8), fixed seed per test id
  (`model-mt-<subject>`), so the same test is the same questions
  on every run. English stays locked (no supplied book, empty
  items, Start disabled) — unchanged.
- Entry points (UI): `/practice` daily + weak cards and
  `/practice-tab` quiz tab call `generateDailyQuiz()`; the quiz
  screen's deep-link fallback uses `dailyQuizFor()`. Model list
  and tab model cards use `modelTests()` (same selector).
- Labelling: both practice cards carry the subtitle
  "অনুশীলন ব্যাংক · বইয়ের প্রশ্ন নয়" /
  "Practice bank · not book questions", and
  `PracticeSession.quizSource` records `bankFallback` for the
  running set. When the pool switches (§5), the subtitle and the
  session value switch WITH it — never before.

## 2. Weak-topic revision (item 8)

- Source: `practiceService.weakRevisionItems()`, surfaced on
  `ProgressSummary.weakItems` (via `progress_service`).
- Definition: every saved attempt (quiz AND model), newest run
  first, every answer whose chosen option differs from the
  item's `correctIndex`, deduped by question id, resolved to a
  real `QuizItem`. Unresolvable wrong ids (a future book id with
  no scorable item yet) are SKIPPED, never replaced by an
  unrelated question.
- UI rule (both practice screens): `weakItems` empty AND no weak
  chapters → honest empty state ("এখনো কোনো ভুল নেই") and the
  revision button is DISABLED. `weakItems` non-empty → the button
  is enabled and starts a quiz with EXACTLY those items
  (`PracticeSession.quizIsRevision = true`). The old behaviour —
  the weak card starting a generic subject quiz — is removed.
- Subtitle shows the real count plus the top weak chapter, e.g.
  "৩টি ভুল প্রশ্ন · গণিত · পরিমাপ ও অনুপাত". No count is ever
  invented: it is the length of the actual wrong-answer list.

## 3. The book-question path (Supabase, implemented but not live)

- Client fetch: `questionGeneration.fetchBookQuestions()` —
  Edge Function Mode D, POST
  `{ generateQuiz: true, subject, classId, language }`.
- Server: `supabase/functions/explain-question/index.ts`, Mode D
  block (added this batch, SOURCE ONLY — NOT yet deployed).
  It reads `book_questions` with the service role, supplied books
  only, max 500 rows, ordered by page/problem, public fields only
  (`bookId`, `chapterNumber`, `chapterTitle`, `page`, `problem`,
  verbatim `questionText`). `source_link` is never selected.
- Why not a direct client query: migration `002_books.sql`
  gives `book_questions` NO client read policy on purpose. Any
  "just add a policy" fix would let anyone scrape the index and
  is forbidden by `BOOK_IMPORT_CONTRACT.md` §0.
- What the async generators do with the fetch today:
  `generateDailyQuiz()` / `generateModelTest()` call it and carry
  the row count on `GeneratedSet.bookQuestionsIndexed` — and
  still return bank items. The fetch result is availability
  information, not questions for the quiz, because §0 line 2
  forbids converting text-only rows into scored items. When the
  function is undeployed/unconfigured or the index is empty, the
  fetch returns null and generation proceeds on the bank alone —
  no crash, no fake "book" label.
- DEMO note: in DEMO (no Supabase) there is NO local book pool
  to select from. The staging JSON under
  `supabase/book_questions/` is import staging, NOT runtime data:
  it is not bundled into the app, and it also contains no options
  or answers, so bundling it would not make book MCQs possible.
  The DEMO scorable pool is the labelled bank. The 2-question
  local index in `learn_service.dart` is a lesson gate, not a quiz
  pool, and is not used for generation.

## 4. Current state (2026-10-28, this batch)

- DONE: deterministic selector + daily/model generation over the
  bank; weak revision from real wrong answers on both practice
  screens; fallback labelling on cards + session; Mode D client +
  server code + README checks; unit + widget tests
  (`test/question_generation_test.dart`,
  `test/practice_start_test.dart`).
- NOT DONE / BLOCKED (not bugs — missing inputs):
  1. `book_questions` rows have NOT landed in the database yet
     (see `BOOK_IMPORT_CONTRACT.md` §9). Mode D honestly returns
     `not-indexed` until they do.
  2. Mode D is NOT deployed (deploy needs the user's Supabase
     project + service-role key via the secure flow; see the
     Edge Function README). Until redeploy, the fetch returns
     null even with a configured app.
  3. NO verified-options source exists: no `question_options`
     table/column, no verified answer key for book rows. This is
     the actual blocker for scored book MCQs — not the selector,
     not the fetch.
  4. Chapter granularity of the bank is coarse: `chapterOf()`
     maps all maths bank items to one label and all science items
     to one label, so "chapter coverage" over the bank is one
     group per subject today. Real per-chapter coverage activates
     automatically when a pool with real chapter keys
     (`BookQuestion.chapterKey`) becomes scorable.

## 5. Switch-over checklist (do ALL of these, in order, before any
   quiz is ever labelled a book quiz)

1. [ ] `book_questions` rows imported per `BOOK_IMPORT_CONTRACT.md`
       (checklist §7), verified with the Mode D curl check.
2. [ ] Edge Function redeployed with Mode D (Mode A–C behaviour
       unchanged; verify with all four curl checks).
3. [ ] A verified-options source exists AND is verified: either
       a migration adding verified options + answer key to the
       book-question data (human-checked, not AI-guessed), or a
       documented, verified AI-distractor pipeline whose answers
       are checked before they can score a student. AI-generated
       options must be labelled AI-generated until verified;
       unverified AI answers must never decide a score.
4. [ ] The scorable pool passed to `selectQuestions()` changes
       from the bank to that verified pool, `GeneratedSet.source`
       becomes `QuestionSource.book`, and the practice-card
       subtitles change from the bank note to the book label —
       in the same change, never separately.
5. [ ] Tests updated: selector tests over the new pool shape,
       fallback tests proving the bank label returns the moment
       the book pool is unavailable, and weak-revision tests
       proving unresolvable ids are skipped, not substituted.
6. [ ] Until ALL of the above hold, the bank stays the pool and
       stays labelled. No intermediate state may present bank
       questions as book questions, for any subject, even if one
       subject's book pool is ready and another's is not (in that
       case the ready subject uses the book pool and the other
       stays labelled bank — per-subject source, recorded on the
       set, never a global "book mode" flag).

## 6. Files

- `lib/core/services/question_generation.dart` — selector,
  `BookQuestion`, `GeneratedSet`, Mode D client.
- `lib/core/services/practice_service.dart` — bank pools,
  `dailyQuizFor`, `modelItemsFor`, `modelTests`,
  `generateDailyQuiz`, `generateModelTest`, `weakRevisionItems`.
- `lib/core/services/question_bank.dart` — DEMO bank solution
  texts (moved out of `practice_service` to keep it ≤250 lines).
- `lib/core/services/progress_service.dart` — `weakItems` on
  `ProgressSummary`.
- `lib/features/practice/practice_screen.dart`,
  `lib/features/practice/practice_tab_screen.dart` — daily +
  weak cards (real starts, honest empty state).
- `lib/features/practice/practice_store.dart` —
  `PracticeSession.quizSource` / `quizIsRevision`.
- `lib/features/practice/quiz_question_screen.dart` — deep-link
  fallback now uses `dailyQuizFor()` (one line, still 250 lines).
- NOT touched: model-test exam/results screens, home/search/
  settings screens, `book_questions` extraction files
  (`supabase/book_questions/`, `supabase/tools/`).
