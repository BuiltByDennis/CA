import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router.dart';
import 'core/theme.dart';

/// CA — Scan-to-Receive Electronic Receipts.
/// Offline-first: issuing and scanning NEVER require internet.
/// Supabase is used only for account backup, business verification and
/// the verified-seller public-key registry (Phase 3). It is deliberately
/// NOT initialised at startup, so the app launches fully offline.
void main() => runApp(const ProviderScope(child: CaApp()));

class CaApp extends StatelessWidget {
  const CaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'CA Receipts',
        theme: caTheme(),
        routerConfig: caRouter,
      );
}
