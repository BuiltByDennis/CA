import 'package:flutter/material.dart';
import '../../core/db/app_db.dart';
import '../../core/models.dart';
import '../../core/services.dart';

/// Receipt History from the local DB (Phase 1) — grouped by buyer/company
/// for sellers (direction=issued) and by seller for buyers (direction=saved).
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
                        '${DateTime.fromMillisecondsSinceEpoch(r.issuedAtUnix * 1000).toLocal()}'),
                    isThreeLine: true,
                    trailing: Chip(
                        label: Text(r.verified ? 'Verified' : 'Unverified'),
                        backgroundColor: r.verified ? Colors.green.shade100 : Colors.orange.shade100),
                  ),
              ],
            ]);
          },
        ),
      );
}
