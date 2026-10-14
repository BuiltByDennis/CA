import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BuyerDashboard extends StatelessWidget {
  const BuyerDashboard({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Buyer')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          FilledButton.icon(
            icon: const Icon(Icons.qr_code_scanner, size: 28),
            label: const Text('Scan for Receipt'),
            onPressed: () => context.go('/buyer/scan'),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.history),
            label: const Text('My Receipts (History)'),
            onPressed: () => context.go('/buyer/history'),
          ),
          const SizedBox(height: 24),
          const Card(child: ListTile(
            leading: Icon(Icons.verified),
            title: Text('Every scanned receipt is signature-checked offline.'),
            subtitle: Text('First time with a seller? Scan their Seller Key QR once so your phone can verify them.'),
          )),
        ]),
      );
}
