import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router.dart';
import 'core/i18n/strings.dart';
import 'core/supabase_config.dart';
import 'core/theme.dart';

/// CA — Scan-to-Receive Electronic Receipts.
/// Offline-first: issuing and scanning NEVER require internet.
/// Supabase (when configured via dart-defines) is only for backup,
/// business verification and the verified-seller key registry.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init(); // no-op when not configured; never blocks offline use
  await LanguageService.init();
  runApp(const ProviderScope(child: CaApp()));
}

class CaApp extends StatelessWidget {
  const CaApp({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
        valueListenable: LanguageService.code,
        builder: (context, lang, _) => MaterialApp.router(
          title: 'CA Receipts',
          theme: caTheme(),
          routerConfig: caRouter,
        ),
      );
}
