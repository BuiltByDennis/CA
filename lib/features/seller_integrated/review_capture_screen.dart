import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import '../../core/db/app_db.dart';
import '../../core/models.dart';
import '../../core/ocr/receipt_parser.dart';
import '../../core/seller_key_service.dart';
import '../../core/branches/branch_logic.dart';
import '../../core/services.dart';
import '../auth/session_service.dart';
import '../seller_manual/new_receipt_screen.dart' show IssuedQrScreen;

/// Review & Approve (Phase 2): the human-in-the-loop screen.
/// The captured photo + raw OCR text are one tap away for comparison; the
/// extracted fields are editable; lines the parser could not validate are
/// highlighted "check this". [Approve & Issue QR] signs with the seller's
/// key and saves to History.
class ReviewCaptureScreen extends StatefulWidget {
  const ReviewCaptureScreen({
    super.key,
    required this.imagePath,
    required this.parsed,
    required this.rawText,
  });
  final String? imagePath;
  final ParsedReceipt parsed;
  final String rawText;
  @override
  State<ReviewCaptureScreen> createState() => _ReviewCaptureScreenState();
}

class _Row {
  _Row(ParsedItem i)
      : name = TextEditingController(text: i.name),
        qty = TextEditingController(text: '${i.qty}'),
        price = TextEditingController(
            text: (i.unitPricePesewas / 100).toStringAsFixed(2)),
        needsCheck = i.needsCheck;
  final TextEditingController name;
  final TextEditingController qty;
  final TextEditingController price;
  bool needsCheck;
  int get qtyVal => int.tryParse(qty.text) ?? 0;
  int get priceVal => ((double.tryParse(price.text) ?? 0) * 100).round();
  int get amount => qtyVal * priceVal;
  void dispose() { name.dispose(); qty.dispose(); price.dispose(); }
}

class _ReviewCaptureScreenState extends State<ReviewCaptureScreen> {
  late final List<_Row> _rows;
  late final TextEditingController _originalNo;
  late final TextEditingController _buyer;
  late final TextEditingController _tax;
  late final TextEditingController _discount;
  String _payment = 'Cash';
  bool _issuing = false;

  @override
  void initState() {
    super.initState();
    _rows = widget.parsed.items.map(_Row.new).toList();
    if (_rows.isEmpty) {
      _rows.add(_Row(ParsedItem(
          name: '', qty: 1, unitPricePesewas: 0, amountPesewas: 0, rawLine: '')));
    }
    _originalNo = TextEditingController(text: widget.parsed.receiptNo ?? '');
    _buyer = TextEditingController();
    _tax = TextEditingController(
        text: (widget.parsed.taxPesewas / 100).toStringAsFixed(2));
    _discount = TextEditingController(
        text: (widget.parsed.discountPesewas / 100).toStringAsFixed(2));
    _payment = widget.parsed.paymentMethod ?? 'Cash';
  }

  @override
  void dispose() {
    for (final r in _rows) { r.dispose(); }
    _originalNo.dispose(); _buyer.dispose(); _tax.dispose(); _discount.dispose();
    super.dispose();
  }

  int get _itemsTotal => _rows.fold(0, (s, r) => s + r.amount);
  int get _taxVal => ((double.tryParse(_tax.text) ?? 0) * 100).round();
  int get _discountVal => ((double.tryParse(_discount.text) ?? 0) * 100).round();
  int get _total => _itemsTotal + _taxVal - _discountVal;

  Future<void> _approve() async {
    final items = <ReceiptItem>[];
    for (final r in _rows) {
      if (r.name.text.trim().isNotEmpty && r.qtyVal > 0 && r.priceVal > 0) {
        items.add(ReceiptItem(
            name: r.name.text.trim(), qty: r.qtyVal, unitPricePesewas: r.priceVal));
      }
    }
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add or fix at least one item first.')));
      return;
    }
    setState(() => _issuing = true);
    final profile = await AppServices.db.getProfile();
    final businessId = profile?.businessId ?? 'biz-demo';
    final businessName = profile?.businessName ?? profile?.name ?? 'My Business';
    final seq = await AppServices.db.issuedCount() + 1;
    // Discount rides as a negative line in tx so buyer-side sum checks hold
    // (items + tx == total). Noted in docs/PHASE2_NOTES.md.
    final taxLines = <TaxLine>[
      if (_taxVal > 0) TaxLine(name: 'Tax (from receipt)', ratePercent: 0, amountPesewas: _taxVal),
      if (_discountVal > 0) TaxLine(name: 'Discount', ratePercent: 0, amountPesewas: -_discountVal),
    ];
    final receipt = Receipt(
      id: SellerKeyService.newReceiptId(),
      receiptNo: 'CA-${DateTime.now().year}-${seq.toString().padLeft(4, '0')}',
      sellerBusinessId: businessId,
      sellerName: businessName,
      buyerName: _buyer.text.trim().isEmpty ? null : _buyer.text.trim(),
      items: items,
      taxLines: taxLines,
      totalPesewas: _total,
      issuedAt: DateTime.now().toUtc(),
      source: 'captured',
      paymentMethod: _payment,
    );
    final signer = await SellerKeyService.signerFor(businessId);
    final qr = await signer.signReceipt(receipt);
    final sellerVerified =
        (await AppServices.db.getVerification())?.status == 'verified';
    final branch = await BranchService.activeBranchName();
    await AppServices.db.saveReceipt(
      ReceiptsCompanion.insert(
        id: receipt.id, receiptNo: receipt.receiptNo, sellerBusinessId: businessId,
        sellerName: businessName, buyerName: Value(receipt.buyerName),
        totalPesewas: receipt.totalPesewas, paymentMethod: _payment,
        issuedAtUnix: receipt.issuedAt.millisecondsSinceEpoch ~/ 1000,
        source: 'captured', qrText: qr, direction: 'issued',
        cashierName: Value(SessionService.currentUserName),
        branchName: Value(branch),
        verified: const Value(true),
        originalReceiptNo:
            Value(_originalNo.text.trim().isEmpty ? null : _originalNo.text.trim()),
      ),
      items.map((i) => ReceiptItemsCompanion.insert(
          receiptId: receipt.id, name: i.name, qty: i.qty,
          unitPricePesewas: i.unitPricePesewas)).toList(),
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => IssuedQrScreen(
            qr: qr, receipt: receipt, sellerVerified: sellerVerified)));
  }

  @override
  Widget build(BuildContext context) {
    final parsedTotal = widget.parsed.totalPesewas;
    final mismatch = parsedTotal != null && (parsedTotal - _total).abs() > 1;
    return Scaffold(
      appBar: AppBar(title: const Text('Review & Approve')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ExpansionTile(
          title: const Text('Captured receipt & raw text (tap to compare)'),
          children: [
            if (widget.imagePath != null)
              Image.file(File(widget.imagePath!), height: 260, fit: BoxFit.contain),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SelectableText(widget.rawText,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            ),
          ],
        ),
        if (widget.parsed.warnings.isNotEmpty)
          Card(
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Please check:', style: TextStyle(fontWeight: FontWeight.bold)),
                for (final warn in widget.parsed.warnings) Text('• $warn'),
              ]),
            ),
          ),
        const SizedBox(height: 8),
        TextField(controller: _originalNo,
            decoration: const InputDecoration(
                labelText: 'Original receipt no. (from your system)')),
        TextField(controller: _buyer,
            decoration: const InputDecoration(labelText: 'Buyer name (optional)')),
        if (widget.parsed.sellerName != null)
          Padding(padding: const EdgeInsets.only(top: 8),
              child: Text('Receipt header read as: ${widget.parsed.sellerName}')),
        if (widget.parsed.dateTime != null)
          Padding(padding: const EdgeInsets.only(top: 4),
              child: Text('Receipt date read as: ${widget.parsed.dateTime}')),
        const Divider(height: 28),
        for (var i = 0; i < _rows.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _rows[i].needsCheck ? Colors.amber.shade50 : null,
              border: Border.all(
                  color: _rows[i].needsCheck ? Colors.amber : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(children: [
              if (_rows[i].needsCheck)
                const Row(children: [
                  Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                  SizedBox(width: 6),
                  Text('Check this line — qty × price did not match the amount.',
                      style: TextStyle(fontSize: 12)),
                ]),
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
                    decoration: const InputDecoration(labelText: 'Unit GH₵'),
                    onChanged: (_) => setState(() {}))),
                IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _rows.length == 1
                        ? null
                        : () => setState(() => _rows.removeAt(i).dispose())),
              ]),
              Align(alignment: Alignment.centerRight,
                  child: Text('= ${formatGhs(_rows[i].amount)}')),
            ]),
          ),
        TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add item'),
            onPressed: () => setState(() => _rows.add(_Row(ParsedItem(
                name: '', qty: 1, unitPricePesewas: 0, amountPesewas: 0, rawLine: ''))))),
        Row(children: [
          Expanded(child: TextField(controller: _tax,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Tax total GH₵'),
              onChanged: (_) => setState(() {}))),
          const SizedBox(width: 12),
          Expanded(child: TextField(controller: _discount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Discount GH₵'),
              onChanged: (_) => setState(() {}))),
        ]),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _payment,
          decoration: const InputDecoration(labelText: 'Payment method'),
          items: const ['Cash', 'MoMo', 'Bank', 'Card']
              .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
          onChanged: (m) => setState(() => _payment = m ?? 'Cash'),
        ),
        const SizedBox(height: 16),
        Text('Items: ${formatGhs(_itemsTotal)}'),
        if (parsedTotal != null)
          Text('Printed total on receipt: ${formatGhs(parsedTotal)}',
              style: TextStyle(
                  color: mismatch ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold)),
        Text('CA total: ${formatGhs(_total)}',
            style: Theme.of(context).textTheme.headlineSmall),
        if (mismatch)
          const Text('Totals differ — fix the items/tax above before approving.',
              style: TextStyle(color: Colors.red)),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _issuing ? null : _approve,
          child: const Text('Approve & Issue QR'),
        ),
        const SizedBox(height: 8),
        const Text('Approving creates a new signed CA receipt. Your original '
            'receipt number is kept on the record for reference.',
            textAlign: TextAlign.center),
      ]),
    );
  }
}
