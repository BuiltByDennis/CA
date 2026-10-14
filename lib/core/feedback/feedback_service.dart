import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';

// Pilot feedback (Phase 6): sends to the Supabase `feedback` table when a
// backend is configured (needs schema_v3 + anonymous sign-ins, same setup
// as sync). When that's unavailable the screen offers the share-sheet
// fallback instead — feedback must never be silently lost in a pilot.

enum FeedbackResult { sent, notConfigured, failed }

class FeedbackService {
  static String buildDiagnostics({
    required String mode,
    required int issued,
    required int received,
    required String? verificationStatus,
    required bool supabaseConfigured,
  }) =>
      'mode=$mode; issued=$issued; received=$received; '
      'verification=${verificationStatus ?? 'not started'}; '
      'supabase=${supabaseConfigured ? 'configured' : 'not configured'}';

  static Future<FeedbackResult> send({
    required String category,
    required String message,
    required String diagnostics,
    required String mode,
  }) async {
    if (!SupabaseConfig.isConfigured) return FeedbackResult.notConfigured;
    try {
      final client = Supabase.instance.client;
      if (client.auth.currentUser == null) {
        await client.auth.signInAnonymously();
      }
      await client.from('feedback').insert({
        'user_id': client.auth.currentUser?.id,
        'category': category,
        'message': message,
        'diagnostics': diagnostics,
        'app_mode': mode,
      });
      return FeedbackResult.sent;
    } catch (_) {
      return FeedbackResult.failed;
    }
  }
}
