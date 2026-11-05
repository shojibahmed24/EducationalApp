// Route: /lesson/chat — TextChatScreen (AI Doubt Solver).
// TEXT ONLY, no voice. Replies are lesson-grounded; unindexed
// lessons say so plainly, never guess. No bKash: Play only.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/chat_marks.dart';
import '../../core/services/explanation_service.dart';
import '../../core/services/local_store.dart';
import '../../core/services/profile_service.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/chat_strings.dart';
import '../../l10n/pages/lesson_strings.dart';
import 'chat_greeting.dart';
import 'chat_message.dart';
import 'chat_structured_reply.dart';
import 'guide_chat_grounding.dart';
import 'learn_store.dart';
import 'lesson_selection.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_question_card.dart';
import 'widgets/mock_data.dart';
import '../../theme/themed_scaffold.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _messages = <ChatMsg>[];
  final _saved = <String>{};
  bool _thinking = false;
  int _replyCount = 0;
  // Greeting name from the saved profile; null = greet nameless.
  String? _displayName;
  // Chat font size (B7); labels reuse lesson strings.
  double _fontSize = 15;

  LessonSelection get _sel => LessonSelectionHolder.current;

  void _smaller() => setState(() => _fontSize = (_fontSize - 1).clamp(12, 24));
  void _larger() => setState(() => _fontSize = (_fontSize + 1).clamp(12, 24));

  @override
  void initState() {
    super.initState();
    LearnStore.savedIds().then((ids) {
      if (mounted) setState(() => _saved.addAll(ids));
    });
    // Profile name for the greeting only; failures greet nameless.
    profileService.loadProfile().then((p) {
      if (mounted) setState(() => _displayName = greetingFirstName(p));
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _subjectName(String id, bool bn) => subjectNameFor(id, bn);

  Future<void> _send(bool bn, Map<String, String> s) async {
    final text = _controller.text.trim();
    if (text.isEmpty || _thinking) return;
    _controller.clear();
    setState(() {
      _messages.add(ChatMsg(text, true));
      _thinking = true;
    });
    // Dispatch: guide selections resolve via Mode G (never the
    // textbook index); textbook selections keep the old dispatch.
    final schoolClass = resolveChatSchoolClass(
      selectionClass: _sel.schoolClass,
      profileClass: await profileService.loadSchoolClass(),
    );
    final resolved = await resolveChatGrounding(_sel, schoolClass, bn);
    final grounding = resolved.grounding;
    // 2026-11-03 chat fix: missing context/options -> honest
    // reply, NEVER a model call (no wrong-passage answers).
    final honest = honestGuideChatReply(resolved, s);
    String reply;
    String? saveId;
    if (!grounding.found) {
      reply = resolved.isGuide
          ? s['guideNotFound']!
          : '${s['outsideLesson']!}\n${s['notIndexedDetail']!}';
    } else if (honest != null) {
      reply = honest;
    } else {
      // Marks-bearing message -> structured path with the marks
      // budget; null (marks-less, or structured yielded nothing)
      // keeps the plain path exactly as before.
      final structuredReply = await structuredChatReply(
        grounding: grounding, bangla: bn, userQuestion: text);
      if (structuredReply != null) {
        reply = structuredReply;
      } else {
        final res = await explanationService.explain(
          grounding: grounding, style: 'simple', bangla: bn,
          userQuestion: text, marksOverride: parseUserMarks(text));
        reply = chatReplyFromPlainResult(res, s);
      }
      saveId = 'chat:${_sel.key}:$_replyCount';
    }
    if (!mounted) return;
    setState(() {
      _thinking = false;
      _replyCount++;
      _messages.add(ChatMsg(reply, false, saveId));
    });
  }

  Future<void> _toggleSave(String id, bool bn, Map<String, String> s) async {
    final nowSaved = await LearnStore.toggleSaved(id);
    if (nowSaved) await LocalStore.saveQuestion(id);
    if (!mounted) return;
    setState(() {
      if (nowSaved) {
        _saved.add(id);
      } else {
        _saved.remove(id);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(nowSaved ? s['savedQ']! : s['unsavedQ']!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? chatStringsBn : chatStringsEn;
        final ls = bn ? lessonStringsBn : lessonStringsEn;
        final contextLine = chatQuestionLine(_sel, _subjectName(_sel.subject, bn), bn);
        final greeting = buildChatGreeting(name: _displayName, s: s, questionLine: contextLine);
        final all = <ChatMsg>[ChatMsg(greeting, false), ..._messages];
        return ThemedScaffold(
          calm: true,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go(_sel.returnTo),
            ),
            title: Text(s['title']!),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contextLine,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    // Guide chats show the exact question above
                    // the messages (2026-11-03 chat fix).
                    if (_sel.guideQuestionId != null)
                      ChatQuestionCard(sel: _sel, s: s),
                    TextButton(
                      onPressed: () => context.go(_sel.returnTo),
                      child: Text(s['viewQuestion']!),
                    ),
                    Row(children: [
                      TextButton(onPressed: _smaller, child: Text(ls['fontSmaller']!)),
                      TextButton(onPressed: _larger, child: Text(ls['fontLarger']!)),
                    ]),
                    // Tip string is area-lesson-only, not for others.
                    if (_sel.key == 'math|3|45|5')
                      Text(
                        s['tip']!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: all.length + (_thinking ? 1 : 0),
                  itemBuilder: (c, i) {
                    if (i >= all.length) {
                      return ChatBubble(
                        text: s['aiThinking']!,
                        isUser: false,
                        fontSize: _fontSize,
                      );
                    }
                    final m = all[i];
                    return ChatBubble(
                      text: m.text,
                      isUser: m.isUser,
                      fontSize: _fontSize,
                      saveLabel: s['saveQ'],
                      isSaved: m.saveId != null && _saved.contains(m.saveId),
                      onSave: m.saveId == null
                          ? null
                          : () => _toggleSave(m.saveId!, bn, s),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      s['textOnly']!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: s['hint'],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onSubmitted: (_) => _send(bn, s),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () => _send(bn, s),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
