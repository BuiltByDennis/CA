import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/db/app_db.dart';
import '../../core/models.dart';
import '../../core/seller_key_service.dart';
import '../../core/services.dart';
import '../auth/session_service.dart';
import '../../core/tax_presets.dart';
import '../../core/sync/sync_payloads.dart';
import '../../core/staff/staff_logic.dart' as staff_logic;
import '../../core/printing/print_service.dart';
import '../printing/printer_screen.dart';

/// Real New Receipt form (Phase 1): buyer, items, tax presets, payment —
/// totals in pesewas, signed with the seller's persistent device key, saved
/// to the local DB, and shown as a QR for the buyer to scan.
class NewReceiptScreen extends StatefulWidget {
  const NewReceiptScreen({super.key});
  @override
  State<NewReceiptScreen> createState() => _NewReceiptScreenState();
}

class _ItemRow {
  final name = TextEditingController();
  final qty = TextEditingController(text: '1');
  final price = TextEditingController(); // in GH₵, converted to pesewas
  void dispose() { name.dispose(); qty.dispose(); price.dispose(); }
}

class _NewReceiptScreenState extends State<NewReceiptScreen> {
  final _buyer = TextEditingController();
  final _rows = <_ItemRow>[_ItemRow()];
  String _payment = 'Cash';
  bool _applyTax = false;
  bool _issuing = false;

  @override
  void dispose() {
    _buyer.dispose();
    for (final r in _rows) { r.dispose(); }
    super.dispose();
  }

  int get _subtotal {
    var s = 0;
    for (final r in _rows) {
      final q = int.tryParse(r.qty.text) ?? 0;
      final p = (double.tryParse(r.price.text) ?? 0) * 100;
      s += q * p.round();
    }
    return s;
  }

  List<TaxLine> get _taxLines => !_applyTax
      ? const []
      : taxPresets
          .map((t) => TaxLine(
              name: t.name,
              ratePercent: t.ratePercent,
              amountPesewas: (_subtotal * t.ratePercent / 100).round()))
          .toList();

  int get _total => _subtotal + _taxLines.fold(0, (s, t) => s + t.amountPesewas);

  Future<void> _issue() async {
    final items = <ReceiptItem>[];
    for (final r in _rows) {
      final q = int.tryParse(r.qty.text) ?? 0;
      final p = ((double.tryParse(r.price.text) ?? 0) * 100).round();
      if (r.name.text.trim().isNotEmpty && q > 0 && p > 0) {
        items.add(ReceiptItem(name: r.name.text.trim(), qty: q, unitPricePesewas: p));
      }
    }
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add at least one item with qty and price.')));
      return;
    }
    setState(() => _issuing = true);
    final profile = await AppServices.db.getProfile();
    final businessId = profile?.businessId ?? 'biz-demo';
    final businessName = profile?.businessName ?? profile?.name ?? 'My Business';
    final seq = await AppServices.db.issuedCount() + 1;
    final receipt = Receipt(
      id: SellerKeyService.newReceiptId(),
      receiptNo: 'CA-${DateTime.now().year}-${seq.toString().padLeft(4, '0')}',
      sellerBusinessId: businessId,
      sellerName: businessName,
      buyerName: _buyer.text.trim().isEmpty ? null : _buyer.text.trim(),
      items: items,
      taxLines: _taxLines,
      totalPesewas: _total,
      issuedAt: DateTime.now().toUtc(),
      source: 'manual',
      paymentMethod: _payment,
    );
    final signer = await SellerKeyService.signerFor(businessId);
    final qr = await signer.signReceipt(receipt);
    final sellerVerified =
        (await AppServices.db.getVerification())?.status == 'verified';
    await AppServices.db.saveReceipt(
      ReceiptsCompanion.insert(
        id: receipt.id, receiptNo: receipt.receiptNo, sellerBusinessId: businessId,
        sellerName: businessName, buyerName: Value(receipt.buyerName),
        totalPesewas: receipt.totalPesewas, paymentMethod: _payment,
        issuedAtUnix: receipt.issuedAt.millisecondsSinceEpoch ~/ 1000,
        source: 'manual', qrText: qr, direction: 'issued',
        cashierName: Value(SessionService.currentUserName),
        verified: const Value(true),
      ),
      items.map((i) => ReceiptItemsCompanion.insert(
          receiptId: receipt.id, name: i.name, qty: i.qty,
          unitPricePesewas: i.unitPricePesewas)).toList(),
    );
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => IssuedQrScreen(
            qr: qr, receipt: receipt, sellerVerified: sellerVerified)));
    setState(() => _issuing = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('New Receipt')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          TextField(controller: _buyer,
              decoration: const InputDecoration(labelText: 'Buyer name (optional)')),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            for (final f in favouriteItemNames.take(6))
              ActionChip(label: Text(f), onPressed: () => setState(() {
                    final row = _rows.firstWhere(
                        (r) => r.name.text.isEmpty, orElse: () { final n = _ItemRow(); _rows.add(n); return n; });
                    row.name.text = f;
                  })),
          ]),
          const Divider(height: 32),
          for (var i = 0; i < _rows.length; i++)
            Row(children: [
              Expanded(flex: 5, child: TextField(controller: _rows[i].name,
                  decoration: const InputDecoration(labelText: 'Item'))),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: TextField(controller: _rows[i].qty,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Qty'),
                  onChanged: (_) => setState(() {}))),
              const SizedBox(width: 8),
              Expanded(flex: 3, child: TextField(controller: _rows[i].price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Price GH₵'),
                  onChanged: (_) => setState(() {}))),
              IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _rows.length == 1 ? null : () => setState(() => _rows.removeAt(i).dispose())),
            ]),
          TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add item'),
              onPressed: () => setState(() => _rows.add(_ItemRow()))),
          SwitchListTile(
            title: const Text('Apply tax presets (VAT / NHIL / GETFund)'),
            subtitle: const Text('Preset rates — confirm with your accountant.'),
            value: _applyTax, onChanged: (v) => setState(() => _applyTax = v),
          ),
          DropdownButtonFormField<String>(
            initialValue: _payment,
            decoration: const InputDecoration(labelText: 'Payment method'),
            items: const ['Cash', 'MoMo', 'Bank', 'Card']
                .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (m) => setState(() => _payment = m ?? 'Cash'),
          ),
          const SizedBox(height: 16),
          Text('Subtotal: ${formatGhs(_subtotal)}'),
          for (final t in _taxLines) Text('${t.name} (${t.ratePercent}%): ${formatGhs(t.amountPesewas)}'),
          Text('TOTAL: ${formatGhs(_total)}',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          FilledButton(
              onPressed: _issuing ? null : _issue,
              child: const Text('Issue Receipt & Show QR')),
        ]),
      );
}

class IssuedQrScreen extends StatelessWidget {
  const IssuedQrScreen(
      {super.key, required this.qr, required this.receipt, this.sellerVerified = true});
  final String qr;
  final Receipt receipt;
  final bool sellerVerified;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Receipt ${receipt.receiptNo}')),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          QrImageView(data: qr, size: 280),
          const SizedBox(height: 12),
          Text('${receipt.sellerName} · ${formatGhs(receipt.totalPesewas)}',
              style: Theme.of(context).textTheme.titleMedium),
          const Padding(padding: EdgeInsets.all(16),
              child: Text('Ask the buyer to scan this with CA. It is signed and '
                  'verifies offline. First time? The buyer should scan your '
                  'Seller Key QR once (Seller dashboard → My Seller Key).',
                  textAlign: TextAlign.center)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.print),
            label: const Text('Print QR Slip (for buyers without a smartphone)'),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PrinterScreen(slip: SlipData(
                      businessName: receipt.sellerName,
                      receiptNo: receipt.receiptNo,
                      dateText: receipt.issuedAt.toLocal().toString(),
                      totalText: slipMoney(receipt.totalPesewas),
                      itemLines: receipt.items
                          .map((i) => '${i.qty} x ${i.name}  ${slipMoney(i.amountPesewas)}')
                          .toList(),
                      qrText: qr,
                      cashierName: SessionService.currentUserName,
                    )))),
          ),
          if (!sellerVerified)
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16),
                child: Card(color: Color(0xFFFFF8E1), child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Your business is not verified yet, so buyers '
                      'will not see the Verified badge for this receipt. '
                      'Complete Business Verification from your dashboard to earn it.',
                      textAlign: TextAlign.center),
                ))),
        ])),
      );
}

class SellerKeyScreen extends StatefulWidget {
  const SellerKeyScreen({super.key});
  @override
  State<SellerKeyScreen> createState() => _SellerKeyScreenState();
}

class _SellerKeyScreenState extends State<SellerKeyScreen> {
  String? _qr;
  String? _pub;
  final _import = TextEditingController();

  Future<void> _exportBackup() async {
    final profile = await AppServices.db.getProfile();
    final businessId = profile?.businessId ?? 'biz-demo';
    final seed = await SellerKeyService.seedFor(businessId);
    if (seed == null || !mounted) return;
    final backup = exportKeyBackup(seed);
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Signing-key backup'),
        content: SelectableText(
            '$backup\n\nTreat this like a password: anyone with it can '
            'issue receipts as your business. Store it somewhere safe '
            '(not in a public chat). On a new phone, paste it under '
            'Import to restore this same key.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done')),
        ],
      ),
    );
  }

  Future<void> _importBackup() async {
    final seed = parseKeyBackup(_import.text);
    if (seed == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('That does not look like a CAKEYBACKUP1 key backup.')));
      return;
    }
    final profile = await AppServices.db.getProfile();
    final businessId = profile?.businessId ?? 'biz-demo';
    await SellerKeyService.importSeed(businessId, seed);
    _import.clear();
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Key restored. New receipts now sign with the restored key.')));
    }
  }
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final profile = await AppServices.db.getProfile();
    final businessId = profile?.businessId ?? 'biz-demo';
    final name = profile?.businessName ?? 'My Business';
    final signer = await SellerKeyService.signerFor(businessId);
    final pub = await signer.publicKeyBase64Url();
    if (mounted) {
      setState(() {
        _pub = pub;
        _qr = SellerKeyService.pairingQr(businessId, pub, name);
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('My Seller Key')),
        body: _qr == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(children: [
                QrImageView(data: _qr!, size: 260),
                const SizedBox(height: 12),
                const Padding(padding: EdgeInsets.all(16),
                    child: Text('Buyers scan this once so their phone can verify '
                        'your receipts offline. From Phase 3 this key is also '
                        'published in the Supabase verified-seller registry.',
                        textAlign: TextAlign.center)),
                SelectableText(_pub ?? '', textAlign: TextAlign.center),
                const Divider(height: 32),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Changing phones? Back up this signing key — '
                        'without it, receipts you already issued cannot be '
                        'matched to a key on a new phone.',
                        textAlign: TextAlign.center)),
                const SizedBox(height: 8),
                if (staff_logic.canExportKey(SessionService.currentRole))
                  OutlinedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Export Key Backup'),
                    onPressed: _exportBackup,
                  )
                else
                  const Text('Key backup export is owner-only.'),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _import,
                    decoration: const InputDecoration(
                        labelText: 'Paste a CAKEYBACKUP1… backup to restore'),
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.upload),
                  label: const Text('Import Key Backup'),
                  onPressed: _importBackup,
                ),
                const SizedBox(height: 24),
              ]),
      );
}
