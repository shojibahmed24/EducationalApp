# Guide Bank AI-explanation fix — code prep (2026-11-03)

Code prep ONLY: no DB write, no deploy, no zip, no commit, no password
used. Edge deploy + fresh APK are still needed before the user sees
any of this on the phone (see §6).

## 1. Root causes (traced in code, not guessed)

### Bug 1 — first load: "cannot determine" planning fragment as explanation

The Mode G call path dropped the options. Edge
`supabase/functions/explain-question/index.ts` selected only
`id, book_id, chapter_id, question_text, question_type, marks,
answer_key` from `guide_questions` (plus separate try/catch fetches for
solution, stimulus, explanation, corrections, prose link) and returned
NO `options` field at all. App side, `structured_explanation_service`
`_guideContextFrom` never read options, `GroundedContext` had no
options field, and `structured_prompts` `structuredUserPrompt` wrote
only question text + key + hidden solution + chunks. So for the
`shriek` MCQ the model received the bare word + key `ii` and nothing
else, answered honestly that context was insufficient, and the app
rendered that planning fragment (summary + steps + "Cannot
determine") as if it were an explanation.

### Bug 2 — second load: English output + invented option text

Same missing options, plus a weak language instruction. The system
prompt said only "Write in Bangla" once, keyed to the UI language.
With no options in the prompt, the model wrote "Option ii (scream)"
— paraphrasing instead of quoting the stored text "cries out
sharply". "Scream" is not among the options.

### Bug 3 — auto-generation

`guide_answer_screen.dart` `_load()` ran `explainStructured` in
`initState` right after grounding arrived, so the screen showed
"ব্যাখ্যা তৈরি হচ্ছে…" without being asked. The grouped creative
view did the same per part (`defaultCreativePartLoader` ran
`explainStructured` after stage-1).

### Chat bug — tutor got stimulus but no question, no options, no key

The plain chat prompt (`openrouter_client.explain`) carried ONLY
book/chapter/page headers + `Book question (verbatim):
${questionText}` + chapter chunks. It never carried options,
answerKey, guideUnitText, or stimulusRef. The old `withChatStimulus`
FUSED the selection's stimulus INTO questionText
(`"উদ্দীপক: <stim>\nshriek"`), so a bare-word MCQ read as "only
stimulus given, no specific question" — exactly what the tutor
replied. The structured chat prompt carried the key but still no
options. Two further defects: `withChatStimulus` silently DROPPED
`guideExplanation` when rebuilding context, and `chatQuestionLine`
always printed "অধ্যায় <n>" even for chapter 0 (hence
"ইংরেজি · অধ্যায় ০" for set-based English opens).

Correction to an earlier hypothesis (user-confirmed 2026-11-03):
this was NOT a stale-context leak from a previous question. The
user opened chat for the same `shriek` question; its stimulus
reached the AI, but the options and the question itself did not.
File evidence: the collection row for `shriek`
(`eng1-p019-mcq-q1-set1-a`) carries `stimulus_text` null and only a
`stimulus_ref` label ("Unit-01 Lesson-01 seen passage (Mr. Moti)"),
while the Amin/Sonabhan prose text in the files belongs to
different rows (`eng1-p458-story-*`, Story appreciation set 1).
Whether the live row's backfilled stimulus text is the
Unit-01 Lesson-01 passage (whose p077 rows carry an Ameen/Sonabhan
reference) could NOT be verified here — no DB access in this task
— but the fix does not depend on it: every field is now labeled
separately in the prompt, and a stimulus can only enter a chat
when its owner id matches the resolved question.

## 2. What changed

### Edge — `supabase/functions/explain-question/`

- `index.ts`: Mode G now fetches the row's `options` in a separate
  try/catch (same pre-migration-safe pattern as stimulus/explanation)
  and returns `options` in the JSON. A server without the column
  answers `[]` instead of failing Mode G.
- `grounding.ts`: new pure `normalizeGuideOptions()` (same semantics
  as guide-bank's `optionsToArray`: string array as-is, Bengali-key
  object in ক/খ/গ/ঘ/ঙ order, anything else `[]`).
- `grounding.test.ts`: 4 new tests (string array, Bengali-key
  object, null/string/number → `[]`, empty stays empty).

### App — grounding model

- NEW `lib/core/models/grounded_context.dart`: `GroundedContext`
  moved out of `backend_models.dart` (which re-exports it, so all
  existing imports work) with new fields `options`, `stimulusText`,
  `stimulusRef`, plus getters `mcqOptionsMissing`,
  `correctOptionIndex` (Bengali letters AND roman i/ii/iii/iv/v,
  positional), `correctOptionText` (exact text or null — never
  invented).
- `structured_explanation_service.dart`: `_guideContextFrom` reads
  `options`/`stimulusText`/`stimulusRef` from Mode G.
  `StructuredStatus`/`StructuredAttempt` moved to `solution_model.dart`
  (they are models, not service logic); the service re-exports them.

### App — prompts (Bangla + verbatim, shared wording)

- NEW shared helpers in `structured_prompts.dart`:
  `stimulusPromptBlock()` (labeled context block, never fused),
  `optionsPromptBlock()` (verbatim options with BOTH label systems,
  e.g. `খ (ii). cries out sharply`, or the honest NONE line for an
  option-less MCQ), `correctOptionLabel()`. Both the structured and
  the plain chat prompt use them — one wording, tested once.
- Structured system prompt: Bangla now means "Write EVERYTHING in
  Bangla, in easy simple words a class 9 student understands.
  Never write any part of the explanation in English." plus an
  explicit OPTIONS RULE (quote exactly, never paraphrase /
  substitute / invent; name the correct option by exact text +
  label; no options → state plainly that they are missing).
- Plain chat prompt (`openrouter_client.dart`): same stimulus /
  options / key blocks + the Bangla easy-words clause + the verbatim
  options rule in the system prompt.

### App — on-demand explanation (no auto-generation)

- `guide_explanation_section.dart`: NEW `ExplanationSectionInput`
  bundle (`requested`, `pending`, `unavailable`, `onRequest`,
  `onRetry`). Order: option-less MCQ → honest note (no call);
  not requested → "ব্যাখ্যা দেখুন" button; requested + pending →
  loading row; then the existing result / prose / failed branches.
  Retry re-requests the explanation (no grounding refetch).
- `guide_answer_screen.dart`: `_load()` resolves grounding ONLY and
  stores it + Mode G options. NEW `_requestExplanation()` runs
  ONLY on tap/retry (reloads grounding first if missing, chains
  into the explanation in the same tap; option-less MCQ never
  calls the model — second lock beside the section note).
- `guide_answer_screen_body.dart` (NEW): the screen's `_body`
  construction + Mode G key mapping + chips + the bundle, moved out
  to keep the screen under the 250-line rule. Also homes
  `openGuideChat` / `guideGroupBody` / `goGuideBack`.
- Grouped creative view, same rule: `guide_creative_part_loader.dart`
  no longer runs `explainStructured` (returns stage-1 + grounding;
  NEW `runCreativePartExplanation()` runs only on tap);
  `guide_creative_answer_view.dart` requests per part on tap
  (reload-then-chain on missing grounding); `CreativePartState`
  moved to the loader file; the stimulus header moved to
  `guide_creative_stimulus_header.dart`.

### App — chat context (full, owned, honest)

- `lesson_selection.dart`: NEW `guideOptions` (verbatim list-row
  options) + `stimulusQuestionId` (owner of the stimulus),
  preserved through `copyWith`.
- `guide_chat_grounding.dart`: `withChatStimulus` rewritten as an
  overlay, not a prepend — stimulus applies ONLY when
  `stimulusQuestionId == guideQuestionId` (legacy selections
  without an owner fall back to the selection's own question id);
  Mode G stimulus wins over the selection's; selection options
  fill in when Mode G returns none; `guideExplanation` + `marks`
  are carried through (previously dropped). NEW
  `honestGuideChatReply()`: missing question text →
  `guideChatNoContext`; option-less MCQ → `guideChatNoOptions`;
  both shown INSTEAD of a model call.
- `guide_answer_screen_body.dart` `openGuideChat`: passes
  `guideOptions: q.options` + `stimulusQuestionId: q.id` whenever a
  stimulus rides along (group parts: the group stimulus is owned
  by the tapped part).
- `chat_screen.dart`: `_send` short-circuits to the honest reply
  (no model call); guide chats show a NEW `ChatQuestionCard`
  (label + question text + verbatim options) above the messages.
- `chat_greeting.dart`: `chatQuestionLine` omits the chapter part
  when chapter is 0 — no more "অধ্যায় ০".

### l10n (Bn + En)

- `guide_bank_strings`: `viewExplanation`, `explanationUnavailableOptions`.
- `chat_strings`: `guideChatNoContext`, `guideChatNoOptions`, `chatForQuestion`.

## 3. One-word MCQ correction list (separate prep, same task)

The redo parse dropped the instruction sentence for 14 MCQ rows,
leaving bare words as `question_text`. Prepared, NOT written:

- `english/_work/ONE_WORD_MCQ_CORRECTIONS.md` (table: id, test,
  key unchanged, current + proposed `question_text`, original
  source, status/note) + `ONE_WORD_MCQ_CORRECTIONS.json` (same rows,
  machine-readable).
- Verified: exactly 14 one-word MCQ rows in the whole redo file,
  all Unit-01 Lesson-01 seen passage (Mr. Moti), main-01 × 12 +
  main-02 × 2; each matched to its `questions.json` original by
  word + all four options (12 exact, 2 explained by OCR noise in
  the original only: mix "Oi" = Oil, announce "৪" = a).
- 13 ready (proposed text = the original's clean English
  instruction, options + keys UNCHANGED); 1 EYE-CHECK PENDING:
  `quack` — the original instruction itself is garbled
  ("What docs …", option i "tosing"), so "What does …" is an
  inference that MUST be confirmed against the printed scan
  before any write.

## 4. Line counts (all ≤ 250)

Tightest files after the change: `guide_answer_screen` 237,
`guide_creative_answer_view` 244, `chat_screen` 250,
`guide_answer_body` 247, `structured_explanation_service` 242,
`backend_models` 182 (was 254), `grounded_context` 118,
`guide_answer_screen_body` 147, `guide_explanation_section` 128,
`guide_creative_part_loader` 124, `guide_creative_stimulus_header`
51, `chat_question_card` 42. No whole-file `dart format` was run.

## 5. Verification (all green)

- `flutter analyze` on all 26 touched lib + test files: NO issues
  (one intermediate error — export placed after declarations —
  and one unused-import warning were found and fixed; final run
  is clean).
- `flutter test` on the 6 touched test files: 47 passed, 0 failed
  (12 rewritten chat-stimulus + 10 new on-demand/prompt tests +
  4 body-fallback + 2 body-stimulus + 8 creative-view + 11 pilot).
- `deno test` explain-question: 11 passed, 0 failed (7 existing +
  4 new `normalizeGuideOptions` tests).
- `deno check` explain-question: the same 11 PRE-EXISTING errors
  as before (lines 278, 520, 670–673, 764–771 — old code); NONE on
  new lines.
- Full `flutter test`: 474 passed, 0 failed ("All tests passed!").
- Full `deno test` (explain-question + guide-bank): 64 passed,
  0 failed.
- The 14-row correction files were verified by re-reading both
  files (JSON parses: 14 rows, 13 ready + 1 pending).

## 6. What still needs Edge deploy + fresh APK (NOT done here)

- Deploy `supabase/functions/explain-question` (needs a fresh
  user-supplied Supabase token at that time — tokens do not
  persist across sessions). Until then, Mode G returns no
  `options`, so the app falls back to the list row's options for
  the explanation guard and the chat overlay; the on-demand UI,
  Bangla prompt rules, and honest states are all client-side and
  work with a fresh APK even before the deploy.
- Fresh APK build on the user's PC (VM cannot build it) from the
  current code, then phone checks: (a) answer screen shows
  verbatim cards immediately and NO "ব্যাখ্যা তৈরি হচ্ছে…" until
  "ব্যাখ্যা দেখুন" is tapped; (b) tapped explanation is Bangla,
  easy words, options quoted verbatim, correct option by exact
  text; (c) chat from the question shows the question card, no
  "অধ্যায় ০", and explains with options + key; (d) an option-less
  MCQ shows the honest note in both places and never calls the
  model.
- No DB write was made or is needed for this fix. The 14-row
  question-text corrections are a SEPARATE future guarded batch
  (after the quack eye-check), not part of this deploy.
