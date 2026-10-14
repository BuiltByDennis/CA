import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/i18n/strings.dart';
import '../../core/models.dart';
import '../shared/onboarding_card.dart';

class BuyerDashboard extends StatelessWidget {
  const BuyerDashboard({super.key});
  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) { if (!didPop) context.go('/home'); },
        child: Scaffold(
        appBar: AppBar(title: Text(tr('buyer'))),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const OnboardingCard(mode: UserMode.buyer),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.qr_code_scanner, size: 28),
            label: Text(tr('scanForReceipt')),
            onPressed: () => context.push('/buyer/scan'),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.history),
            label: Text(tr('myReceipts')),
            onPressed: () => context.push('/buyer/history'),
          ),
          const SizedBox(height: 24),
          Card(child: ListTile(
            leading: const Icon(Icons.verified),
            title: Text(tr('buyerTagline')),
            subtitle: const Text('First time with a seller? Scan their Seller Key QR once so your phone can verify them.'),
          )),
        ]),
      ));
}
