// Server-side generation proxy (2026-10-30: keys moved server-side).
// The app NEVER calls OpenRouter directly and NEVER holds the key:
// both call sites POST their already-built prompts to the
// explain-question Edge Function (Mode GEN), which calls OpenRouter
// with its function secret. Prompt construction stays here (the
// locked grounding rules live in Dart); only the key and the HTTP
// call moved server-side. GenResult.keyMissing tells callers the
// Edge secret is not set, so the UI shows an honest error instead
// of a fabricated answer. Null text = call failed / empty reply.
// Provider option (2026-11-04): saved provider (openrouter
// default, or gemini) is sent to Edge Mode GEN with every call.
// Class/file name unchanged: still the single choke point for
// all AI text; only the provider field was added.
// Attribution (2026-11-04): GenResult now also carries the
// provider + model the Edge response itself reported. A
// response without those fields (stale deploy) stays
// 'unknown' — never inferred from the saved setting.
import 'dart:convert';
import 'dart:io';

import '../models/backend_models.dart';
import 'ai_provider_service.dart';
import 'app_config.dart';
import 'structured_prompts.dart';

/// Attribution from the Edge response itself — never the
/// provider the user merely selected. 'unknown' means the
/// Edge deploy predates attribution (it answered, but did
/// not say with what); callers must show that honestly,
/// never guess 'gemini' from the saved setting.
class GenResult {
  final String? text;
  final bool keyMissing;

  /// 'openrouter' | 'gemini' | 'unknown'.
  final String provider;

  /// Model that actually answered, or null when unknown.
  final String? model;
  const GenResult({
    this.text,
    this.keyMissing = false,
    this.provider = 'unknown',
    this.model,
  });
}

class OpenRouterClient {
  /// Raw chat call with a caller-built system + user prompt.
  /// Used by the structured solution path, which owns its prompt
  /// contract and parses the reply itself. The caller guarantees
  /// grounded context.
  Future<GenResult> chatRaw({
    required String systemPrompt,
    required String userPrompt,
  }) =>
      _generate(systemPrompt: systemPrompt, userPrompt: userPrompt);

  /// Full-context call. userQuestion is the student's typed
  /// follow-up (chat) or null. Prompt built exactly as before;
  /// only the transport changed (Edge proxy, no client key).
  Future<GenResult> explain({
    required GroundedContext ctx,
    required String style,
    required bool bangla,
    String? userQuestion,
  }) async {
    final followUp = (userQuestion ?? '').trim();
    final userContent = StringBuffer()
      ..writeln('Book: ${ctx.bookTitle}')
      ..writeln('Chapter ${ctx.chapterNumber}: ${ctx.chapterTitle}')
      ..writeln('Page ${ctx.page}, Question ${ctx.problem}')
      ..writeln('Book question (verbatim): ${ctx.questionText}');
    // 2026-11-03 chat fix: the old prompt carried ONLY the
    // question line (plus chapter chunks) — no options, no key,
    // and a stimulus fused into the question text. A bare-word
    // MCQ ("shriek") therefore read as "only stimulus given, no
    // question". Every field is now its own labeled block via
    // the shared helpers (same wording as the structured prompt).
    final stimBlock = stimulusPromptBlock(ctx);
    if (stimBlock.isNotEmpty) userContent.write(stimBlock);
    userContent.write(optionsPromptBlock(ctx));
    if (ctx.answerKey.isNotEmpty) {
      final correct = ctx.correctOptionText;
      userContent.writeln('Verified correct answer: ${ctx.answerKey}'
          '${correct == null ? '' : " — exact text: '$correct'"}');
    }
    // Phase 3 chunk grounding: at most 3 chunks, each cited
    // with its own book page range. Chunks are OCR chapter
    // text for context only — never quoted to the student
    // as verbatim book proof beyond the question itself.
    final chunks = ctx.chunkTexts.take(3).toList();
    if (chunks.isNotEmpty) {
      userContent.writeln(
          'Book chapter text for this question (same book and chapter):');
      for (var i = 0; i < chunks.length; i++) {
        final range = i < ctx.chunkPageRanges.length
            ? ctx.chunkPageRanges[i]
            : '';
        userContent.writeln(
            'Chunk ${i + 1}${range.isNotEmpty ? ' (pages $range)' : ''}: ${chunks[i]}');
      }
      userContent.writeln(
          'Base the explanation on the question and this chapter text.');
    } else {
      // Honest fallback: no chapter text exists for this
      // question, so the prompt must NOT claim it. The
      // explanation is grounded in the verbatim question
      // only (or chapter-only where a real chapter exists).
      userContent.writeln(
          'No chapter text is available for this question. '
          'Explain ONLY from the verbatim book question above, '
          'and do NOT claim chapter-text grounding.');
    }
    if (followUp.isNotEmpty) {
      userContent.writeln('Student follow-up question: $followUp');
    }
    userContent.writeln('Explain in style: $style.');
    return _generate(
      systemPrompt: 'You are a school teacher. Explain ONLY the '
          'given textbook question, in the requested style, in '
          '${bangla ? 'Bangla' : 'English'}. '
          '${bangla ? 'Write EVERYTHING in Bangla, in easy simple '
          'words a class 9 student understands. ' : ''}'
          'Write every math '
          'formula in LaTeX wrapped in \$...\$ delimiters so it '
          'renders as typeset math, never caret-text. Use only the book '
          'context given. Do not invent a different question. '
          'When options are listed, quote them EXACTLY as '
          'written; never paraphrase, substitute, or invent '
          'option wording. '
          'Never claim chapter-text grounding when no chapter '
          'text was given. If the context is not enough to '
          'answer, say so plainly instead of guessing. '
          'QUESTION SCOPE (verbatim-first chat rule, 2026-10-31): '
          'answer ONLY this question and what is needed to '
          'understand it (its terms, formulas, and prerequisite '
          'ideas). If the student asks about anything else — '
          'another subject, another question, general knowledge, '
          'personal chat, or writing work for them — politely '
          'refuse in the same language and redirect them to '
          'this question. Never answer off-topic questions, '
          'even partially.',
      userPrompt: userContent.toString(),
    );
  }

  /// POST prompts to Edge Mode GEN. Non-200 / bad body / empty
  /// text = generic failure; the Edge's 'openrouter-key-missing'
  /// and 'gemini-key-missing' errors map to keyMissing so
  /// callers report them honestly.
  /// Per-call cap (2026-11-01 diagnosis): one GEN call is capped
  /// at 55s total, so a slow free-model call fails fast enough
  /// for the caller's trimmed retry to still run inside the
  /// screen's 120s explanation window. The client is closed on
  /// ALL paths (including timeout) via finally — previously a
  /// timeout/hang leaked the HttpClient, since close() only ran
  /// after a successful response body.
  Future<GenResult> _generate({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final url = AppConfig.explainEndpoint;
    if (url.isEmpty) return const GenResult();
    // Saved provider (openrouter default); a failed read also
    // yields openrouter inside the service, never a crash.
    final provider = await aiProviderService.load();
    final client = HttpClient();
    try {
      return await _generateInner(
        client: client,
        url: url,
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        provider: provider,
      ).timeout(const Duration(seconds: 55));
    } catch (_) {
      return const GenResult();
    } finally {
      client.close();
    }
  }

  Future<GenResult> _generateInner({
    required HttpClient client,
    required String url,
    required String systemPrompt,
    required String userPrompt,
    required String provider,
  }) async {
    final req = await client.postUrl(Uri.parse(url));
    req.headers.set('Authorization', 'Bearer ${AppConfig.supabaseAnonKey}');
    req.headers.set('apikey', AppConfig.supabaseAnonKey);
    req.headers.set('Content-Type', 'application/json');
    req.add(utf8.encode(jsonEncode({
      'generate': true,
      'systemPrompt': systemPrompt,
      'userPrompt': userPrompt,
      'provider': provider,
    })));
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    final data = jsonDecode(body);
    if (data is Map<String, dynamic>) {
      if (data['error'] == 'openrouter-key-missing' ||
          data['error'] == 'gemini-key-missing') {
        return const GenResult(keyMissing: true);
      }
      if (res.statusCode == 200 && data['generated'] == true) {
        final text = data['text'];
        if (text is String && text.isNotEmpty) {
          final provider = data['provider'];
          final model = data['model'];
          return GenResult(
            text: text,
            provider: provider is String && provider.isNotEmpty
                ? provider
                : 'unknown',
            model: model is String && model.isNotEmpty ? model : null,
          );
        }
      }
    }
    return const GenResult();
  }
}

final openRouterClient = OpenRouterClient();
