import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/i18n/strings.dart';
import '../../core/models.dart';
import '../shared/onboarding_card.dart';
import '../../core/staff/staff_logic.dart' as staff_logic;
import '../auth/session_service.dart';

class ManualDashboard extends StatelessWidget {
  const ManualDashboard({super.key});
  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) { if (!didPop) context.go('/home'); },
        child: Scaffold(
        appBar: AppBar(title: Text(tr('sellerManual'))),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const OnboardingCard(mode: UserMode.sellerManual),
          const SizedBox(height: 12),
          if (staff_logic.canIssue(SessionService.currentRole))
            FilledButton.icon(
              icon: const Icon(Icons.add_circle, size: 28),
              label: Text(tr('newReceipt')),
              onPressed: () => context.push('/seller-manual/new'),
            ),
          if (staff_logic.canIssue(SessionService.currentRole)) const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.history),
            label: Text(tr('receiptHistory')),
            onPressed: () => context.push('/seller-manual/history'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.design_services),
            label: Text(tr('myReceiptDesign')),
            onPressed: () => context.push('/seller-manual/design'),
          ),
          const SizedBox(height: 12),
          if (staff_logic.canManageVerification(SessionService.currentRole))
            OutlinedButton.icon(
              icon: const Icon(Icons.verified_outlined),
              label: Text(tr('businessVerification')),
              onPressed: () => context.push('/seller-manual/verify'),
            ),
          if (staff_logic.canViewAnalytics(SessionService.currentRole)) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.bar_chart),
              label: Text(tr('analytics')),
              onPressed: () => context.push('/seller/analytics'),
            ),
          ],
          if (staff_logic.canViewAnalytics(SessionService.currentRole)) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.receipt_long),
              label: const Text('Tax Report & Exports'),
              onPressed: () => context.push('/seller/tax'),
            ),
          ],
          if (staff_logic.canManageStaff(SessionService.currentRole)) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.people_outline),
              label: Text(tr('staff')),
              onPressed: () => context.push('/seller/staff'),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.key),
            label: Text(tr('mySellerKey')),
            onPressed: () => context.push('/seller-manual/key'),
          ),
        ]),
      ));
}
