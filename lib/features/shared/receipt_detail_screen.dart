import 'package:flutter/material.dart';
import '../../core/db/app_db.dart';
import '../../core/models.dart';
import '../../core/printing/print_service.dart';
import '../../core/receipt_signer.dart';
import '../../core/share_receipt.dart';
import '../printing/printer_screen.dart';

/// Receipt detail (Phase 6 polish) — tap any History row: full items, tax
/// breakdown, payment + MoMo status/reference, cashier, and actions
/// (share; print for issued receipts). Data comes from the signed payload,
/// so what you see is exactly what was issued/scanned.
class ReceiptDetailScreen extends StatelessWidget {
  const ReceiptDetailScreen({super.key, required this.row});
  final ReceiptRow row;

  @override
  Widget build(BuildContext context) {
    final payload = ReceiptSigner.decodePayloadUnverified(row.qrText);
    Receipt? receipt;
    if (payload != null) {
      try {
        receipt = Receipt.fromPayload(payload);
      } catch (_) {}
    }
    final r = receipt;
    return Scaffold(
      appBar: AppBar(title: Text('Receipt ${row.receiptNo}')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(row.sellerName, style: Theme.of(context).textTheme.titleLarge),
        Text('${row.direction == 'issued' ? 'Issued to' : 'Received from'} '
            '${row.direction == 'issued' ? (row.buyerName ?? 'Walk-in buyer') : row.sellerName}'),
        Text(DateTime.fromMillisecondsSinceEpoch(row.issuedAtUnix * 1000).toLocal().toString()),
        const SizedBox(height: 6),
        Wrap(spacing: 8, children: [
          Chip(
            label: Text(row.verified ? 'Verified ✓' : 'Unverified'),
            backgroundColor: row.verified ? Colors.green.shade100 : Colors.orange.shade100,
          ),
          Chip(label: Text(row.paymentMethod)),
          if (row.paymentStatus != null)
            Chip(label: Text(row.paymentStatus == 'pending' ? 'MoMo pending' : 'Paid')),
        ]),
        if (row.paymentReference != null)
          Text('MoMo transaction ID: ${row.paymentReference}'),
        if (row.cashierName != null) Text('Served by: ${row.cashierName}'),
        if (row.originalReceiptNo != null)
          Text('Original receipt no: ${row.originalReceiptNo}'),
        const Divider(height: 28),
        if (r == null)
          const Text('This receipt could not be decoded for detail view. '
              'Its total and status above are from your records.')
        else ...[
          const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
          for (final i in r.items)
            ListTile(
              title: Text(i.name),
              subtitle: Text('${i.qty} × ${formatGhs(i.unitPricePesewas)}'),
              trailing: Text(formatGhs(i.amountPesewas)),
            ),
          if (r.taxLines.isNotEmpty) ...[
            const Text('Taxes & adjustments', style: TextStyle(fontWeight: FontWeight.bold)),
            for (final t in r.taxLines)
              ListTile(title: Text(t.name), trailing: Text(formatGhs(t.amountPesewas))),
          ],
          const Divider(),
          ListTile(
            title: const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text(formatGhs(r.totalPesewas),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.share),
            label: const Text('Share Receipt'),
            onPressed: () => shareReceiptQr(context, receipt: r, qr: row.qrText),
          ),
          if (row.direction == 'issued') ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.print),
              label: const Text('Print QR Slip'),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => PrinterScreen(slip: SlipData(
                        businessName: r.sellerName,
                        receiptNo: r.receiptNo,
                        dateText: r.issuedAt.toLocal().toString(),
                        totalText: slipMoney(r.totalPesewas),
                        itemLines: r.items
                            .map((i) => '${i.qty} x ${i.name}  ${slipMoney(i.amountPesewas)}')
                            .toList(),
                        qrText: row.qrText,
                        cashierName: row.cashierName,
                      )))),
            ),
          ],
        ],
      ]),
    );
  }
}
