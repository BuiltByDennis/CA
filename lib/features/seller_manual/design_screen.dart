import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/design/receipt_design.dart';
import '../../core/services.dart';

/// Design Your Receipt (Phase 6) — a real editor (this screen was a Phase 0
/// placeholder until now): display name, footer note, layout style, and the
/// defaults the New Receipt form starts from. Saved on-device.
class DesignReceiptScreen extends StatefulWidget {
  const DesignReceiptScreen({super.key});
  @override
  State<DesignReceiptScreen> createState() => _DesignReceiptScreenState();
}

class _DesignReceiptScreenState extends State<DesignReceiptScreen> {
  final _name = TextEditingController();
  final _footer = TextEditingController();
  bool _taxDefault = false;
  String _payment = 'Cash';
  int _style = 0;
  bool _loaded = false;
  String? _logoPath;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await DesignStore.load();
    final profile = await AppServices.db.getProfile();
    if (!mounted) return;
    setState(() {
      _name.text = d?.businessDisplayName ?? profile?.businessName ?? '';
      _footer.text = d?.footerNote ?? 'Thank you for your business!';
      _taxDefault = d?.applyTaxByDefault ?? false;
      _payment = d?.defaultPayment ?? 'Cash';
      _style = d?.style ?? 0;
      _logoPath = d?.logoPath;
      _loaded = true;
    });
  }

  Future<void> _pickLogo() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final ext = picked.path.contains('.') ? picked.path.split('.').last : 'png';
    final dest = File('${dir.path}/business_logo.$ext');
    await dest.writeAsBytes(await picked.readAsBytes());
    if (mounted) setState(() => _logoPath = dest.path);
  }

  Future<void> _save() async {
    await DesignStore.save(ReceiptDesign(
      businessDisplayName: _name.text.trim().isEmpty ? null : _name.text.trim(),
      footerNote: _footer.text.trim(),
      applyTaxByDefault: _taxDefault,
      defaultPayment: _payment,
      style: _style,
      logoPath: _logoPath,
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt design saved. New receipts will use it.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Design Your Receipt')),
        body: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : ListView(padding: const EdgeInsets.all(20), children: [
                TextField(controller: _name,
                    decoration: const InputDecoration(
                        labelText: 'Business name on receipts',
                        helperText: 'Shown on the QR receipt, shares and printed slips.')),
                const SizedBox(height: 12),
                TextField(controller: _footer, maxLines: 2,
                    decoration: const InputDecoration(
                        labelText: 'Footer note',
                        helperText: 'e.g. Thank you / returns policy / MoMo number.')),
                const SizedBox(height: 16),
                const Text('Business logo', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_logoPath != null && File(_logoPath!).existsSync())
                  Column(children: [
                    Image.file(File(_logoPath!), height: 84),
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove logo'),
                      onPressed: () => setState(() => _logoPath = null),
                    ),
                  ])
                else
                  OutlinedButton.icon(
                    icon: const Icon(Icons.upload),
                    label: const Text('Upload logo'),
                    onPressed: _pickLogo,
                  ),
                const Text('Shown on your receipt screen and shares. A square PNG with a transparent or white background looks best.',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                const Text('Layout style', style: TextStyle(fontWeight: FontWeight.bold)),
                RadioGroup<int>(
                  groupValue: _style,
                  onChanged: (v) => setState(() => _style = v ?? 0),
                  child: const Column(children: [
                    RadioListTile<int>(value: 0, title: Text('Classic — clean and simple')),
                    RadioListTile<int>(value: 1, title: Text('Compact — fits small thermal paper')),
                    RadioListTile<int>(value: 2, title: Text('Bold header — big business name')),
                  ]),
                ),
                const Divider(height: 32),
                const Text('New Receipt defaults', style: TextStyle(fontWeight: FontWeight.bold)),
                SwitchListTile(
                  title: const Text('Apply tax presets by default'),
                  subtitle: const Text('VAT / NHIL / GETFund — confirm rates with your accountant.'),
                  value: _taxDefault, onChanged: (v) => setState(() => _taxDefault = v),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _payment,
                  decoration: const InputDecoration(labelText: 'Default payment method'),
                  items: const ['Cash', 'MoMo', 'Bank', 'Card']
                      .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (m) => setState(() => _payment = m ?? 'Cash'),
                ),
                const SizedBox(height: 20),
                FilledButton(onPressed: _save, child: const Text('Save design')),
              ]),
      );
}
