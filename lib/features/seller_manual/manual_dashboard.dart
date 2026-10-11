import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/models.dart';
import '../../core/receipt_signer.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
        ]),
      );
}

class DesignReceiptScreen extends StatelessWidget {
  const DesignReceiptScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Design Your Receipt')),
        body: ListView(padding: const EdgeInsets.all(20), children: const [
          Text('Set at signup, editable any time:', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          ListTile(leading: Icon(Icons.store), title: Text('1. Business name, contact, location')),
          ListTile(leading: Icon(Icons.image), title: Text('2. Logo or photo of your shop sign')),
          ListTile(leading: Icon(Icons.style), title: Text('3. Template style (3 clean layouts)')),
          ListTile(leading: Icon(Icons.percent), title: Text('4. Tax setup — VAT toggle + Ghana presets')),
          ListTile(leading: Icon(Icons.payments), title: Text('5. Payment methods: Cash / MoMo / Bank / Card')),
          ListTile(leading: Icon(Icons.notes), title: Text('6. Footer note — thank you / returns policy')),
          ListTile(leading: Icon(Icons.preview), title: Text('Live preview on a sample receipt')),
        ]),
      );
}

/// Phase 0 demo of the Phase 1 heart: build a receipt, sign it, show the QR.
/// Phase 1 replaces the sample data with the real item/price input form.
class NewReceiptScreen extends StatefulWidget {
  const NewReceiptScreen({super.key});
  @override State<NewReceiptScreen> createState() => _NewReceiptScreenState();
}
class _NewReceiptScreenState extends State<NewReceiptScreen> {
  String? _qr;
  @override
  void initState() { super.initState(); _issue(); }
  Future<void> _issue() async {
    final signer = await ReceiptSigner.generate();
    final qr = await signer.signReceipt(Receipt.sample());
    if (mounted) setState(() => _qr = qr);
  }
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('New Receipt')),
        body: Center(child: _qr == null
            ? const CircularProgressIndicator()
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                QrImageView(data: _qr!, size: 260),
                const SizedBox(height: 16),
                Text('Sample signed receipt · ${formatGhs(Receipt.sample().totalPesewas)}'),
                const Padding(padding: EdgeInsets.all(16),
                    child: Text('Phase 1: item + price input fields replace this sample. '
                        'The buyer scans this QR and verifies it offline.',
                        textAlign: TextAlign.center)),
              ])),
      );
}
