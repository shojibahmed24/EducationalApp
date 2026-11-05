# Book Import Contract — how future books/guides reach the AI

Status: Phase 2 (C2). This contract is the single rule for getting
any new textbook, guide book, or class into the app so that lesson,
chat, and quiz explanations can be grounded in it. If an import does
not follow this contract, the app must keep saying "not in the book
index" for that content — never fake grounding for it.

## 0. The one rule that matters

The app NEVER reads `book_questions` from the client. Migration
`002_books.sql` gives that table no client read policy on purpose.
The only reader is the Edge Function
`supabase/functions/explain-question/` (service role), which returns
one matched question's public fields — or, in Mode C, the full list
of matched questions on one printed page — to a signed-in user.
Therefore
**an import is only "done" when the Edge Function can find the
question** — inserting rows is not enough; verify with the curl
check in the Edge Function README after every import.

## 1. Tables and columns (migration 002 — do not change lightly)

| Table | Who reads it | Key columns |
|---|---|---|
| `books` | Server only (no client policy) | `id, class_id, subject_id, language ('bn'/'en'), title, supplied, source_link` |
| `books_public` | App (view, hides `source_link`) | `id, class_id, subject_id, language, title, supplied` |
| `chapters` | Signed-in clients | `id, book_id, number, title_bn, title_en` |
| `book_questions` | Edge Function only | `id, book_id, chapter_id, page_number, problem_number, question_text` |

Hard constraints:

- `books.source_link` is SERVER-ONLY. Never select it in the Edge
  Function, never return it, never put a signed/storage URL in any
  client-visible response.
- `book_questions` has NO `answer_text` / `solution_text` column
  today. The AI *generates* the explanation from the question +
  chapter context; the import stores the question only. Do NOT
  invent answers during import. (If worked solutions are ever
  wanted as stored data, that needs a new migration adding a
  nullable column — until then, solutions stay AI-generated.)
- `book_questions` has NO `language` column: a question's language
  is its book's `language`. A Bangla question must link to a `bn`
  book row, an English question to an `en` book row. Never mix.
- Never add a client read policy to `books` or `book_questions`
  to "make the app work". That would let anyone scrape the index
  and defeat the whole design (see `MIGRATIONS_README.md`).

## 2. ID conventions (follow the Class 6 import exactly)

- Book: `class{class}-{subject}[-{slug}]-{bn|en}`
  e.g. `class6-math-bn`, `class6-bangla-anandopath-en`.
  One row per language edition, even when the same PDF serves both
  (9 Class 6 files are byte-identical across folders — upload once,
  reference twice; see `supabase/book_import_map.json`).
- Subject: the `subjects.id` from migration 002 (`math`, `science`,
  `bangla`, `english`, `bgs`, `ict`) plus the extra subjects added
  by `supabase/book_import.sql` (e.g. `physical`, `islam`, `hindu`).
  A new subject needs a `subjects` row FIRST, or the book FK fails.
- Chapter: `{book_id}-ch{number}`
  e.g. `class6-math-bn-ch3`. `number` is the book's own chapter
  number, NOT a renumbering. Both `title_bn` and `title_en` are
  required on every chapter row (the app shows one row per language).
- Question: `{book_id}-ch{number}-p{page}-q{problem}`
  e.g. `class6-math-bn-ch3-p45-q7`. When a question has no printed
  problem number (e.g. a worked example inside the text), use
  `problem_number = NULL` and id suffix `-e{n}` in reading order
  (e.g. `-e1`, `-e2`). The Edge Function's
  Mode A requires a numeric problem, so unnumbered items are
  reachable today only via Mode B text search — record that limit
  in the import log instead of forcing a fake number.

## 3. Page numbers — printed page, not PDF page

- `page_number` = the page number PRINTED in the book.
- NCTB PDFs are image-only scans (`pdftotext` returns 0 bytes):
  text comes from OCR or visual reading, never from a guessed
  extraction. Keep a per-book import log OUTSIDE the database
  (PDF filename, PDF-page offset to printed page, OCR tool +
  settings) so a later import can be re-checked.
- When the bn and en editions paginate differently (they do for
  math/science/bgs/ict), import each edition's questions against
  ITS OWN printed pages. Never copy page numbers across editions.

## 4. Question text — verbatim, complete, clean

- `question_text` = the book's wording, verbatim and complete
  (numbers, units, and names included). Do not paraphrase, shorten,
  or "fix" the question — the Edge Function matches quiz wording
  against this text, and the AI is shown this text as ground truth.
- Strip OCR artefacts (page headers/footers, running heads) but
  never strip part of the question itself. If OCR is uncertain on
  a character, mark the row for human review; do not silently ship
  a corrupted question.
- One row per question. Multi-part questions (`(ক)`, `(খ)` …)
  become one row per part when each part has its own number, else
  one row with the full text and `problem_number = NULL`.

## 5. Guides and non-textbook material

Guides are welcome, but they must NOT break the app's chapter lists:

- A guide is NOT a second `books` row for the same class/subject/
  language — that would duplicate chapters in the app (which lists
  chapters per subject book) and split one subject's questions
  across two chapter sequences.
- Instead, guide questions are imported as `book_questions` rows
  linked to the TEXTBOOK's `chapter_id` (same `book_id` as the
  textbook), with the guide named in the import log only.
- If a guide question genuinely belongs to no textbook chapter,
  hold it out of the import and record it as an open item — do not
  invent a chapter for it.
- Future option (needs a migration, not this contract): a `kind`
  column on `books` (`textbook` | `guide`) plus Edge Function
  ordering (textbook first). Until that migration lands, the rule
  above is the only allowed guide path.

## 6. New classes (beyond Class 6)

Same pattern, new `class_id`:

1. `classes` row already seeded for 1–10 by migration 002.
2. Book rows `class{class}-{subject}[-{slug}]-{bn|en}` with
   `supplied = true` ONLY when the PDF was actually supplied and
   its chapters imported. `supplied = false` keeps the subject
   locked in the app — never set it `true` early.
3. Chapter rows, then question rows, per sections 2–4.
4. The app currently defaults lesson/search flows to Class 6
   (`schoolClass = 6` in the services); a new class needs the
   app's class selection wired to it before its books are
   advertised to students. Importing rows alone does not launch
   a class.

## 7. Import checklist (run every time, in order)

1. [ ] Source PDF supplied; filename + edition recorded in the log.
2. [ ] `subjects` row exists for the subject (else FK fails).
3. [ ] Book row(s) inserted via service role / SQL Editor — never
   from the app, never with a client key.
4. [ ] Chapter rows inserted with both titles; count matches the
   book's table of contents.
5. [ ] Question rows inserted: spot-check at least 5 per chapter
   against the PDF (wording, page, problem number).
6. [ ] Row counts recorded: books / chapters / questions per book.
7. [ ] Edge Function curl check (see its README) returns
   `found: true` for a sampled real question AND `found: false`
   for a deliberately absent one.
8. [ ] App check in DEMO-independent order: search the exact
   question → lesson opens with the book's wording; quiz
   explanation for a matching bank question comes back live
   (needs `OPENROUTER_API_KEY` at build time) or honestly DEMO.
9. [ ] No client policy was added to `books` / `book_questions`;
   `source_link` appears in no client response.

## 8. What the AI does with an imported question (the same path)

Lesson, chat, and quiz all flow through
`lib/core/services/explanation_service.dart`:

1. Resolve: Edge Function Mode A (position), Mode B (wording),
   or Mode C (page listing: `book_id` + printed page -> all
   questions on that page, used by the `/book-lookup` screen).
2. If not found: the UI says so plainly and asks for the exact
   question / a book photo. No guess, no substitute question.
3. If found: OpenRouter receives book title, chapter title/number,
   page, problem, and the VERBATIM `question_text` (plus the
   student's typed follow-up in chat), and is instructed to use
   only that context.
4. If no `OPENROUTER_API_KEY`: the grounded text shows labelled
   DEMO. If the Edge Function is not deployed: lesson/chat fall
   back to the chapters check (chapter-only honesty), and quiz
   falls back to the labelled DEMO bank — until the function is
   live, at which point live-but-unmatched means "not in the
   index", never the bank.

## 9. Current state (2026-10-28, Phase 2)

- Class 6: 44 book rows + 462 chapters imported (per PROBLEMS.md
  audit); `book_questions` rows are the remaining import — until
  they land, the Edge Function honestly returns `not-indexed` and
  the app keeps its no-guess behaviour. That is the system working
  as designed, not a bug to work around with a client policy.
- Edge Function source: `supabase/functions/explain-question/`
  (deploy steps in its README; service-role key via secure vault).
  Mode C (page listing, `{ listByPage: true, bookId, page }` ->
  `questions[]`, public fields only) added 2026-10-28 in SOURCE
  ONLY — NOT yet deployed. App side wired the same day: new
  `/book-lookup` screen (`lib/features/learn/book_lookup_screen.dart`,
  strings in `lib/l10n/pages/book_lookup_strings.dart`, Mode C
  client in `lib/core/services/book_lookup_service.dart`) with
  subject (Class 6, from `books_public`) + printed page -> verbatim
  question list -> tap -> verbatim question + AI explanation via
  the existing `explanation_service` (DEMO vs live labelled), plus
  a Mode B question-text search box on the same screen. Until the
  function is redeployed AND `book_questions` rows land, the screen
  honestly reports "no questions indexed for this page yet".
- This contract's summary is also appended to
  `BACKEND_DETAILS_LIST.md` (the backend plug-in checklist).

## 10. Question generation from this index (batch 2, items 8/9)

- Full contract: `QUESTION_GENERATION.md` (project root).
- Daily quiz (5, seeded per day) and model tests (maths 10,
  science 8, fixed seed) are SELECTED by
  `question_generation.selectQuestions()` — deterministic,
  chapter-covering, no repeats in a set — from the only scorable
  pool available today, the labelled practice bank.
- Book rows are fetchable via Edge Function Mode D
  (`generateQuiz: true`, source only, NOT yet deployed), but
  they carry `question_text` ONLY — no options, no verified
  answer — so they are never converted into scored MCQs. The
  switch-over checklist in `QUESTION_GENERATION.md` §5 (rows
  landed + Mode D deployed + a VERIFIED options source) must
  all hold before any quiz is labelled a book quiz.
- Weak-topic revision comes from the user's actual wrong
  answers (`practiceService.weakRevisionItems()` /
  `ProgressSummary.weakItems`), never a generic quiz.
