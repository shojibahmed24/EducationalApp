// Minimal POST helper for Edge Functions (default:
// explain-question; pass [endpoint] for guide-bank).
// Shared by services that resolve grounding without duplicating
// the HttpClient boilerplate. Null = unreachable / non-200 /
// bad body. No secret is ever logged or echoed.
// Timeout: every network stage is capped at 30 seconds, and
// the client is closed on ALL paths (success, error, timeout)
// via finally, so a hung network can never leave a lesson,
// chat, or book lookup spinning forever.
import 'dart:convert';
import 'dart:io';

import 'app_config.dart';

Future<Map<String, dynamic>?> edgePost(Map<String, dynamic> body,
    {String? endpoint}) async {
  final url = endpoint ?? AppConfig.explainEndpoint;
  if (url.isEmpty) return null;
  final client = HttpClient();
  try {
    final req = await client
        .postUrl(Uri.parse(url))
        .timeout(const Duration(seconds: 30));
    req.headers.set('Authorization', 'Bearer ${AppConfig.supabaseAnonKey}');
    req.headers.set('apikey', AppConfig.supabaseAnonKey);
    req.headers.set('Content-Type', 'application/json');
    req.add(utf8.encode(jsonEncode(body)));
    final res = await req.close().timeout(const Duration(seconds: 30));
    final text =
        await res.transform(utf8.decoder).join().timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) return null;
    final data = jsonDecode(text);
    return data is Map<String, dynamic> ? data : null;
  } catch (_) {
    return null;
  } finally {
    client.close();
  }
}
