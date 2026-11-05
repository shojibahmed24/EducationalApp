// Chat stimulus + context (2026-11-01, fixed 2026-11-03): a
// creative part's question text alone is unprovable — its
// উদ্দীপক must reach the AI prompt. The 2026-11-03 fix changed
// HOW it rides: as its own labeled field, owned by exactly one
// question id — never fused into the question line, never
// leaking from another question. Covers: LessonSelection
// carries + preserves stimulusText/stimulusQuestionId/
// guideOptions, withChatStimulus ownership + options overlay,
// the honest no-context replies, and the answer holder's
// effective-stimulus pick (part wins, holder fallback).
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/backend_models.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/core/services/explanation_service.dart';
import 'package:yes_sir_ai/features/learn/chat_greeting.dart';
import 'package:yes_sir_ai/features/learn/guide_answer_holder.dart';
import 'package:yes_sir_ai/features/learn/guide_chat_grounding.dart';
import 'package:yes_sir_ai/features/learn/lesson_selection.dart';
import 'package:yes_sir_ai/l10n/pages/chat_strings.dart';

const _part = 'প্রমাণ কর যে, 3xy(x²+y²)=54।';
const _stim = 'x⁴+x²y²+y⁴=27, x²+xy+y²=9';
const _qid = 'pilot3-creative-002';

GroundedContext _ctx(
  String questionText, {
  String stimulusText = '',
  List<String> options = const [],
  String questionType = 'creative',
  String answerKey = '',
}) =>
    GroundedContext(
      bookTitle: 'গণিত',
      chapterTitle: 'অধ্যায় ৩',
      subject: 'math',
      schoolClass: 9,
      chapterNumber: 3,
      page: 0,
      problem: 0,
      questionText: questionText,
      source: 'guide',
      guideQuestionId: _qid,
      questionType: questionType,
      answerKey: answerKey,
      options: options,
      stimulusText: stimulusText,
    );

LessonSelection _sel({
  String? stimulus,
  String? owner,
  List<String> options = const [],
}) =>
    LessonSelection(
      subject: 'math',
      chapter: 3,
      page: 0,
      problem: 0,
      schoolClass: 9,
      guideQuestionId: _qid,
      stimulusText: stimulus,
      stimulusQuestionId: owner,
      guideOptions: options,
    );

GuideBankQuestion _q(String? stimulus) => GuideBankQuestion(
      id: _qid,
      questionText: _part,
      questionType: 'creative',
      stimulusText: stimulus,
    );

void main() {
  test('LessonSelection keeps chat fields through copyWith', () {
    final sel = _sel(stimulus: _stim, owner: _qid, options: ['a', 'b']);
    final copy = sel.copyWith(schoolClass: 9);
    expect(copy.stimulusText, _stim);
    expect(copy.stimulusQuestionId, _qid);
    expect(copy.guideOptions, ['a', 'b']);
    expect(copy.copyWith(stimulusText: 'অন্য').stimulusText, 'অন্য');
    final plain = LessonSelection(subject: 'math', chapter: 3, page: 0, problem: 0);
    expect(plain.stimulusText, isNull);
    expect(plain.stimulusQuestionId, isNull);
    expect(plain.guideOptions, isEmpty);
    expect(plain.copyWith().stimulusText, isNull);
  });

  test('withChatStimulus carries owned stimulus as its own field', () {
    final grounding = Grounding(context: _ctx(_part), reason: 'found');
    final out = withChatStimulus(grounding, _sel(stimulus: _stim, owner: _qid));
    expect(out.reason, 'found');
    // Question line untouched — the old fuse is gone.
    expect(out.context!.questionText, _part);
    expect(out.context!.stimulusText, _stim);
    expect(out.context!.bookTitle, 'গণিত');
    expect(out.context!.guideQuestionId, _qid);
    expect(out.context!.questionType, 'creative');
  });

  test('withChatStimulus ignores a stimulus owned by another question', () {
    final grounding = Grounding(context: _ctx(_part), reason: 'found');
    final out = withChatStimulus(
      grounding,
      _sel(stimulus: _stim, owner: 'some-other-question'),
    );
    expect(identical(out, grounding), isTrue);
    expect(out.context!.stimulusText, isEmpty);
    expect(out.context!.questionText, _part);
  });

  test('withChatStimulus leaves grounding alone without stimulus', () {
    final grounding = Grounding(context: _ctx(_part), reason: 'found');
    expect(identical(withChatStimulus(grounding, _sel()), grounding), isTrue);
    expect(
      identical(withChatStimulus(grounding, _sel(stimulus: '')), grounding),
      isTrue,
    );
    expect(
      identical(withChatStimulus(grounding, _sel(stimulus: '  ')), grounding),
      isTrue,
    );
  });

  test('withChatStimulus keeps Mode G stimulus over the selection one', () {
    final grounding = Grounding(
      context: _ctx(_part, stimulusText: 'সার্ভারের উদ্দীপক'),
      reason: 'found',
    );
    final out = withChatStimulus(grounding, _sel(stimulus: _stim, owner: _qid));
    expect(out.context!.stimulusText, 'সার্ভারের উদ্দীপক');
    expect(out.context!.questionText, _part);
  });

  test('withChatStimulus overlays selection options; Mode G wins', () {
    final noModeG = Grounding(context: _ctx(_part), reason: 'found');
    final overlaid = withChatStimulus(
      noModeG,
      _sel(options: ['opt-a', 'opt-b']),
    );
    expect(overlaid.context!.options, ['opt-a', 'opt-b']);
    final withModeG = Grounding(
      context: _ctx(_part, options: ['mode-g-a']),
      reason: 'found',
    );
    final kept = withChatStimulus(
      withModeG,
      _sel(options: ['opt-a', 'opt-b']),
    );
    expect(kept.context!.options, ['mode-g-a']);
  });

  test('honestGuideChatReply: usable context returns null', () {
    final resolved = ChatGrounding(
      withChatStimulus(
        Grounding(context: _ctx(_part), reason: 'found'),
        _sel(stimulus: _stim, owner: _qid),
      ),
      true,
    );
    expect(honestGuideChatReply(resolved, chatStringsBn), isNull);
  });

  test('honestGuideChatReply: empty question text is not a model call', () {
    final resolved = ChatGrounding(
      Grounding(context: _ctx('  '), reason: 'found'),
      true,
    );
    expect(
      honestGuideChatReply(resolved, chatStringsBn),
      chatStringsBn['guideChatNoContext'],
    );
  });

  test('honestGuideChatReply: option-less MCQ is not a model call', () {
    final resolved = ChatGrounding(
      Grounding(context: _ctx('shriek', questionType: 'mcq'), reason: 'found'),
      true,
    );
    expect(
      honestGuideChatReply(resolved, chatStringsBn),
      chatStringsBn['guideChatNoOptions'],
    );
  });

  test('honestGuideChatReply: textbook selections are untouched', () {
    final resolved = ChatGrounding(
      Grounding(context: _ctx(''), reason: 'found'),
      false,
    );
    expect(honestGuideChatReply(resolved, chatStringsBn), isNull);
  });

  test('chatQuestionLine never prints chapter 0', () {
    final sel = LessonSelection(
      subject: 'english',
      chapter: 0,
      page: 0,
      problem: 0,
    );
    final line = chatQuestionLine(sel, 'ইংরেজি', true);
    expect(line, 'ইংরেজি');
    expect(line.contains('০'), isFalse);
  });

  test('holder chatStimulus: part wins, holder is fallback', () {
    GuideAnswerHolder.stimulusText = 'হোল্ডার শর্ত';
    expect(GuideAnswerHolder.chatStimulus(_q(_stim)), _stim);
    expect(GuideAnswerHolder.chatStimulus(_q('')), 'হোল্ডার শর্ত');
    expect(GuideAnswerHolder.chatStimulus(_q(null)), 'হোল্ডার শর্ত');
    GuideAnswerHolder.stimulusText = '';
    expect(GuideAnswerHolder.chatStimulus(_q(null)), '');
  });
}
