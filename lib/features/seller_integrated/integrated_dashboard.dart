import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class IntegratedDashboard extends StatelessWidget {
  const IntegratedDashboard({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Seller — Receipt System')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          FilledButton.icon(
            icon: const Icon(Icons.document_scanner, size: 28),
            label: const Text('Capture Receipt'),
            onPressed: () => context.go('/seller-integrated/capture'),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.history),
            label: const Text('Receipt History'),
            onPressed: () => context.go('/seller-integrated/history'),
          ),
          const SizedBox(height: 24),
          const Card(child: ListTile(
            leading: Icon(Icons.fact_check),
            title: Text('You always approve before a QR is issued.'),
            subtitle: Text('OCR extracts — you confirm. Nothing is issued automatically.'),
          )),
        ]),
      );
}

