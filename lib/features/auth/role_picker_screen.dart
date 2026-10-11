import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/models.dart';

/// One account — the user decides which type they are (plan §2).
/// A user can add/switch modes later; mode is per-profile, not per-login.
class RolePickerScreen extends StatelessWidget {
  const RolePickerScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('CA — Welcome')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('How will you use CA?',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('One account. Pick one to start — you can add the others later.'),
            const SizedBox(height: 24),
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
