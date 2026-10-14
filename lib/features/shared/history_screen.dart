import 'package:flutter/material.dart';
import '../../core/db/app_db.dart';
import '../../core/models.dart';
import '../../core/services.dart';

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

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.title, required this.direction});
  final String title;
  final String direction;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
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
                  ),
              ],
            ]);
          },
        ),
      );
}
