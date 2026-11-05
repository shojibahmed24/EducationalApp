// Saved-question cloud sync (Phase 16, M10). Same pattern as
// profile_service: the LOCAL list is always the source of truth and
// is written first by the caller; these calls only ATTEMPT a
// Supabase saved_questions write and swallow failures, so local
// data is kept on failure. No attempt is made without a signed-in
// Supabase user: the demo 'demo-user' id is not a uuid and would
// violate the table's user_id FK / RLS (auth.uid() = user_id).
// Table (004_progress_subscriptions.sql): saved_questions with a
// unique (user_id, question_id) pair.
import 'supabase_client.dart';

class SavedSyncService {
  Future<void> syncSave(String questionId) async {
    final client = supabaseOrNull;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) return;
    try {
      await client.from('saved_questions').upsert(
          {'user_id': uid, 'question_id': questionId},
          onConflict: 'user_id, question_id');
    } catch (_) {}
  }

  Future<void> syncUnsave(String questionId) async {
    final client = supabaseOrNull;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) return;
    try {
      await client
          .from('saved_questions')
          .delete()
          .eq('user_id', uid)
          .eq('question_id', questionId);
    } catch (_) {}
  }
}

final savedSyncService = SavedSyncService();
