import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_info.dart';
import '../../core/i18n/strings.dart';
import '../../core/models.dart';
import '../../core/supabase_config.dart';
import '../../core/sync/sync_service.dart';
import 'session_service.dart';

/// One account — the user decides which type they are (plan §2).
/// A user can add/switch modes later; mode is per-profile, not per-login.
class RolePickerScreen extends StatelessWidget {
  const RolePickerScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(tr('welcome')), actions: [
          IconButton(icon: const Icon(Icons.lock), tooltip: 'Lock app',
              onPressed: () { SessionService.lock(); context.go('/'); }),
        ]),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (SessionService.currentUser != null)
              Padding(padding: const EdgeInsets.only(bottom: 8),
                  child: Chip(label: Text('${SessionService.currentUserName} · ${SessionService.currentRole}'))),
            Text(tr('howUse'),
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(tr('oneAccount')),
            const SizedBox(height: 12),
            Row(children: [
              Text('${tr('language')}: '),
              ChoiceChip(label: const Text('English'),
                  selected: LanguageService.code.value == 'en',
                  onSelected: (_) => LanguageService.set('en')),
              const SizedBox(width: 8),
              ChoiceChip(label: const Text('Twi'),
                  selected: LanguageService.code.value == 'tw',
                  onSelected: (_) => LanguageService.set('tw')),
            ]),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.help_outline),
              label: const Text('Help & Feedback'),
              onPressed: () => context.go('/help'),
            ),
            const SizedBox(height: 16),
            const Center(child: Text(appBuildLabel, style: TextStyle(color: Colors.grey, fontSize: 12))),
            const SizedBox(height: 24),
            Card(child: ListTile(
              leading: const Icon(Icons.cloud_outlined),
              title: Text(SupabaseConfig.isConfigured
                  ? 'Supabase: configured (sync features from Phase 3)'
                  : 'Supabase: not configured — app works fully offline'),
              subtitle: const Text('See docs/CONNECT_SUPABASE.md to connect your project.'),
            )),
            if (SupabaseConfig.isConfigured)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.sync),
                  label: Text(tr('syncNow')),
                  onPressed: () async {
                    final report = await SyncService.syncNow();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(report.message)));
                    }
                  },
                ),
              ),
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
                  label: Text(switch (mode) {
                    UserMode.buyer => tr('buyer'),
                    UserMode.sellerIntegrated => tr('sellerIntegrated'),
                    UserMode.sellerManual => tr('sellerManual'),
                  }),
                  onPressed: () => context.go(mode.dashboardRoute),
                ),
              ),
          ],
        ),
      );
}
