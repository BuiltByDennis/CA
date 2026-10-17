import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/db/app_db.dart';
import '../../core/export/history_export.dart';
import '../../core/models.dart';
import '../../core/services.dart';
import 'receipt_detail_screen.dart';

/// Receipt History from the local DB (Phase 1) — grouped by buyer/company
/// for sellers (direction=issued) and by seller for buyers (direction=saved).
Future<void> _confirmMomo(BuildContext context, String receiptId) async {
  final ref = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Confirm MoMo payment'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Only confirm when the money has actually arrived.'),
        TextField(controller: ref,
            decoration: const InputDecoration(
                labelText: 'MoMo transaction ID (optional)')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Not yet')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Payment received')),
      ],
    ),
  );
  if (ok == true) {
    await AppServices.db.setPaymentStatus(receiptId, 'paid',
        reference: ref.text.trim().isEmpty ? null : ref.text.trim());
  }
}


/// Export history as a PDF or Excel file (v0.8.1) — generated on the
/// phone, handed to the share sheet (save it, send it to an accountant,
/// attach it to a loan application).
Future<void> _exportHistory(BuildContext context, String direction) async {
  final choice = await showDialog<String>(
    context: context,
    builder: (_) => SimpleDialog(
      title: const Text('Export history'),
      children: [
        for (final (label, code) in [
          ('PDF — this list', 'pdf-one'),
          ('Excel — this list', 'xlsx-one'),
          ('PDF — everything (issued + saved)', 'pdf-all'),
          ('Excel — everything (issued + saved)', 'xlsx-all'),
        ])
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, code),
            child: Text(label),
          ),
      ],
    ),
  );
  if (choice == null || !context.mounted) return;
  final db = AppServices.db;
  final issued = await db.issuedReceipts();
  final saved = await db.savedReceipts();
  final rows = choice.endsWith('all')
      ? [...issued, ...saved]
      : (direction == 'issued' ? issued : saved);
  rows.sort((a, b) => a.issuedAtUnix.compareTo(b.issuedAtUnix));
  if (rows.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No receipts to export yet.')));
    }
    return;
  }
  final items = await db.allReceiptItems();
  final byReceipt = <String, List<ExportItem>>{};
  for (final i in items) {
    byReceipt.putIfAbsent(i.receiptId, () => []).add(
        ExportItem(i.name, i.qty, i.unitPricePesewas));
  }
  final inputs = [
    for (final r in rows)
      ExportReceipt(
        receiptNo: r.receiptNo,
        direction: r.direction,
        sellerName: r.sellerName,
        buyerName: r.buyerName,
        paymentMethod: r.paymentMethod,
        totalPesewas: r.totalPesewas,
        issuedAtUnix: r.issuedAtUnix,
        items: byReceipt[r.id] ?? const [],
      )
  ];
  final isPdf = choice.startsWith('pdf');
  final stamp = DateTime.now().toIso8601String().split('T').first;
  final bytes = isPdf
      ? await buildHistoryPdf(inputs,
          title: choice.endsWith('all') ? 'All receipts' : 'Receipts (${direction == 'issued' ? 'issued' : 'saved'})')
      : buildHistoryXlsx(inputs);
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/ca-history-$stamp.${isPdf ? 'pdf' : 'xlsx'}');
  await file.writeAsBytes(bytes);
  await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path)], subject: 'CA receipt history'));
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.title, required this.direction});
  final String title;
  final String direction;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title), actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Export as PDF / Excel',
            onPressed: () => _exportHistory(context, direction),
          ),
        ]),
        body: StreamBuilder<List<ReceiptRow>>(
          stream: AppServices.db.watchReceipts(direction),
          builder: (context, snap) {
            final rows = snap.data ?? const <ReceiptRow>[];
            if (rows.isEmpty) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No receipts yet. Issued and scanned receipts will appear here — grouped, searchable, and kept offline.'),
              ));
            }
            final groups = <String, List<ReceiptRow>>{};
            for (final r in rows) {
              final key = direction == 'issued'
                  ? (r.buyerName ?? 'Walk-in buyer')
                  : r.sellerName;
              groups.putIfAbsent(key, () => []).add(r);
            }
            return ListView(children: [
              for (final e in groups.entries) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(e.key, style: Theme.of(context).textTheme.titleMedium),
                ),
                for (final r in e.value)
                  ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: Text('${r.receiptNo} · ${formatGhs(r.totalPesewas)}'),
                    subtitle: Text('${direction == 'issued' ? r.sellerName : (r.buyerName ?? '')}\n'
                        '${DateTime.fromMillisecondsSinceEpoch(r.issuedAtUnix * 1000).toLocal()}'
                        '${r.paymentStatus == 'pending' ? '\n⏳ MoMo payment pending' : ''}'),
                    isThreeLine: true,
                    trailing: r.paymentStatus == 'pending'
                        ? FilledButton.tonal(
                            onPressed: () => _confirmMomo(context, r.id),
                            child: const Text('Confirm MoMo'))
                        : Chip(
                            label: Text(r.verified ? 'Verified' : 'Unverified'),
                            backgroundColor: r.verified ? Colors.green.shade100 : Colors.orange.shade100),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ReceiptDetailScreen(row: r))),
                  ),
              ],
            ]);
          },
        ),
      );
}
