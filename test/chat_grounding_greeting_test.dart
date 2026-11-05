// Chat grounding + greeting: the class-7 questionId path and
// the nameless / nickname greeting. Pure helpers only — no live
// Edge, no widget harness. Question ids are real ids from the
// task; question wording is never asserted (no verbatim text).
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/features/learn/chat_greeting.dart';
import 'package:yes_sir_ai/features/learn/lesson_selection.dart';
import 'package:yes_sir_ai/l10n/pages/chat_strings.dart';
import 'package:yes_sir_ai/l10n/pages/profile_strings.dart';

/// The failing question: class 7 maths ch.3, p.48, problem 15.
LessonSelection class7Selection() => LessonSelection(
      subject: 'math',
      chapter: 3,
      page: 48,
      problem: 15,
      questionId: 'class7-math-bn-ch3-p48-e15',
      schoolClass: 7,
    );

void main() {
  test('class-7 selection carries schoolClass + questionId', () {
    final sel = class7Selection();
    expect(sel.schoolClass, 7);
    expect(sel.questionId, 'class7-math-bn-ch3-p48-e15');
    expect(sel.chapter, 3);
    expect(sel.page, 48);
    expect(sel.problem, 15);
  });

  test('questionId selection uses the by-id grounding path', () {
    expect(useQuestionIdGrounding(class7Selection()), isTrue);
    expect(
      useQuestionIdGrounding(
        LessonSelection(subject: 'math', chapter: 3, page: 45, problem: 5),
      ),
      isFalse,
    );
  });

  test('copyWith stamps the class and preserves questionId', () {
    final stamped = LessonSelection(
      subject: 'math',
      chapter: 3,
      page: 48,
      problem: 15,
      questionId: 'class7-math-bn-ch3-p48-e15',
    ).copyWith(schoolClass: 7);
    expect(stamped.schoolClass, 7);
    expect(stamped.questionId, 'class7-math-bn-ch3-p48-e15');
    expect(stamped.copyWith().schoolClass, 7);
  });

  test('chat school class: selection wins, else profile, else 6', () {
    expect(
      resolveChatSchoolClass(selectionClass: 7, profileClass: 6),
      7,
    );
    expect(
      resolveChatSchoolClass(selectionClass: null, profileClass: 7),
      7,
    );
    // 6 only when NO class is known anywhere (last resort).
    expect(
      resolveChatSchoolClass(selectionClass: null, profileClass: null),
      6,
    );
  });

  test('greetingFirstName: nickname first token wins', () {
    expect(
      greetingFirstName({'nickname': 'Maya Akter', 'full_name': 'Other'}),
      'Maya',
    );
    expect(
      greetingFirstName({'nickname': '  ', 'full_name': 'Karim Uddin'}),
      'Karim',
    );
  });

  test('greetingFirstName: no usable name -> null, never invented', () {
    expect(greetingFirstName(null), isNull);
    expect(greetingFirstName({}), isNull);
    expect(
      greetingFirstName({'nickname': '', 'full_name': '   '}),
      isNull,
    );
  });

  test('nameless greeting contains no name and no Rafi', () {
    for (final s in [chatStringsBn, chatStringsEn]) {
      expect(s['greetingNamed'], isNot(contains('Rafi')));
      expect(s['greetingPlain'], isNot(contains('Rafi')));
      final greeting = buildChatGreeting(
        name: null,
        s: s,
        questionLine: 'Maths · Chapter 3 · Page 48 · Question 15',
      );
      expect(greeting, isNot(contains('Rafi')));
      expect(greeting, isNot(contains('{name}')));
      expect(greeting, contains('Page 48'));
      expect(greeting, contains(s['greetingPrompt']!));
    }
    // The old hardcoded strings are gone from both maps.
    expect(chatStringsBn.containsKey('aiHello'), isFalse);
    expect(chatStringsEn.containsKey('aiHello'), isFalse);
  });

  test('named greeting uses the nickname first token', () {
    final name = greetingFirstName(
      {'nickname': 'Maya Akter', 'full_name': 'Maya Akter'},
    );
    final greeting = buildChatGreeting(
      name: name,
      s: chatStringsEn,
      questionLine: 'Maths · Chapter 3',
    );
    expect(greeting, contains('Hello Maya!'));
    expect(greeting, isNot(contains('{name}')));
    expect(greeting, isNot(contains('Akter')));
  });

  test('profile fallback is generic, not a person name', () {
    expect(profileStringsBn['student'], 'শিক্ষার্থী');
    expect(profileStringsEn['student'], 'Student');
  });

  test('question line omits unknown page/problem (never 0)', () {
    final line = chatQuestionLine(
      LessonSelection(
        subject: 'math',
        chapter: 3,
        page: 0,
        problem: 0,
        questionId: 'class7-math-bn-ch3-p48-e15',
        schoolClass: 7,
      ),
      'গণিত',
      true,
    );
    expect(line, contains('অধ্যায় ৩'));
    expect(line, isNot(contains('পৃষ্ঠা')));
    expect(line, isNot(contains('প্রশ্ন')));
    expect(line, isNot(contains('০')));
    final full = chatQuestionLine(class7Selection(), 'গণিত', true);
    expect(full, 'গণিত · অধ্যায় ৩ · পৃষ্ঠা ৪৮ · প্রশ্ন ১৫');
  });
}
