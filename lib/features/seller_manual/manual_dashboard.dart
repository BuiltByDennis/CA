import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ManualDashboard extends StatelessWidget {
  const ManualDashboard({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Seller — Manual Receipts')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          FilledButton.icon(
            icon: const Icon(Icons.add_circle, size: 28),
            label: const Text('New Receipt'),
            onPressed: () => context.go('/seller-manual/new'),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.history),
            label: const Text('Receipt History'),
            onPressed: () => context.go('/seller-manual/history'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.design_services),
            label: const Text('My Receipt Design'),
            onPressed: () => context.go('/seller-manual/design'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.verified_outlined),
            label: const Text('Business Verification'),
            onPressed: () => context.go('/seller-manual/verify'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.key),
            label: const Text('My Seller Key (for buyers)'),
            onPressed: () => context.go('/seller-manual/key'),
          ),
        ]),
      );
}

class DesignReceiptScreen extends StatelessWidget {
  const DesignReceiptScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Design Your Receipt')),
        body: ListView(padding: const EdgeInsets.all(20), children: const [
          Text('Set at signup, editable any time (full editor lands with business registration in Phase 3):',
              style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          ListTile(leading: Icon(Icons.store), title: Text('1. Business name, contact, location')),
          ListTile(leading: Icon(Icons.image), title: Text('2. Logo or photo of your shop sign')),
          ListTile(leading: Icon(Icons.style), title: Text('3. Template style (3 clean layouts)')),
          ListTile(leading: Icon(Icons.percent), title: Text('4. Tax setup — VAT toggle + Ghana presets')),
          ListTile(leading: Icon(Icons.payments), title: Text('5. Payment methods: Cash / MoMo / Bank / Card')),
          ListTile(leading: Icon(Icons.notes), title: Text('6. Footer note — thank you / returns policy')),
        ]),
      );
}
