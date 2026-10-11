import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase connection — configured at build/run time, NEVER hard-coded.
///
/// Connect your project (see docs/CONNECT_SUPABASE.md):
///   1. Run supabase/schema.sql in your project's SQL Editor.
///   2. Copy Project URL + *publishable/anon* key (Settings -> API).
///      NEVER put the service_role key in the app or share it in chat.
///   3. Put both in dart_defines.json (from dart_defines.example.json, gitignored)
///      and run:  flutter run --dart-define-from-file=dart_defines.json
///
/// The app is offline-first: with no config, Supabase features (backup,
/// verification, key registry) are simply off and everything else works.
class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  static Future<bool> init() async {
    if (!isConfigured) return false;
    try {
      await Supabase.initialize(url: url, publishableKey: anonKey);
      return true;
    } catch (_) {
      return false; // offline or bad config must never block the app
    }
  }

  static SupabaseClient? get clientOrNull {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
}
