import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/i18n/strings.dart';
import '../../core/staff/staff_logic.dart' as staff_logic;
import '../auth/session_service.dart';

class IntegratedDashboard extends StatelessWidget {
  const IntegratedDashboard({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(tr('sellerIntegrated'))),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          if (staff_logic.canCapture(SessionService.currentRole))
            FilledButton.icon(
              icon: const Icon(Icons.document_scanner, size: 28),
              label: Text(tr('captureReceipt')),
              onPressed: () => context.go('/seller-integrated/capture'),
            ),
          if (staff_logic.canCapture(SessionService.currentRole)) const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.history),
            label: Text(tr('receiptHistory')),
            onPressed: () => context.go('/seller-integrated/history'),
          ),
          const SizedBox(height: 12),
          if (staff_logic.canManageVerification(SessionService.currentRole))
            OutlinedButton.icon(
              icon: const Icon(Icons.verified_outlined),
              label: Text(tr('businessVerification')),
              onPressed: () => context.go('/seller-integrated/verify'),
            ),
          if (staff_logic.canViewAnalytics(SessionService.currentRole)) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.bar_chart),
              label: Text(tr('analytics')),
              onPressed: () => context.go('/seller/analytics'),
            ),
          ],
          if (staff_logic.canManageStaff(SessionService.currentRole)) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.people_outline),
              label: Text(tr('staff')),
              onPressed: () => context.go('/seller/staff'),
            ),
          ],
          const SizedBox(height: 24),
          const Card(child: ListTile(
            leading: Icon(Icons.fact_check),
            title: Text('You always approve before a QR is issued.'),
            subtitle: Text('OCR extracts — you confirm. Nothing is issued automatically.'),
          )),
        ]),
      );
}

