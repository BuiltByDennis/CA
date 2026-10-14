import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/models.dart';
import '../../core/supabase_config.dart';
import 'session_service.dart';

/// One account — the user decides which type they are (plan §2).
/// A user can add/switch modes later; mode is per-profile, not per-login.
class RolePickerScreen extends StatelessWidget {
  const RolePickerScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('CA — Welcome'), actions: [
          IconButton(icon: const Icon(Icons.lock), tooltip: 'Lock app',
              onPressed: () { SessionService.lock(); context.go('/'); }),
        ]),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('How will you use CA?',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('One account. Pick one to start — you can add the others later.'),
            const SizedBox(height: 24),
            Card(child: ListTile(
              leading: const Icon(Icons.cloud_outlined),
              title: Text(SupabaseConfig.isConfigured
                  ? 'Supabase: configured (sync features from Phase 3)'
                  : 'Supabase: not configured — app works fully offline'),
              subtitle: const Text('See docs/CONNECT_SUPABASE.md to connect your project.'),
            )),
            const SizedBox(height: 16),
            for (final mode in UserMode.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: FilledButton.icon(
                  icon: Icon(switch (mode) {
                    UserMode.buyer => Icons.qr_code_scanner,
                    UserMode.sellerIntegrated => Icons.document_scanner,
                    UserMode.sellerManual => Icons.edit_note,
                  }),
                  label: Text(mode.label),
                  onPressed: () => context.go(mode.dashboardRoute),
                ),
              ),
          ],
        ),
      );
}
