import 'package:flutter/material.dart';
import '../../core/dummy_data.dart';
import '../../core/models.dart';

/// Receipt History — grouped by buyer/company name, then date/time.
/// Same component for Buyer, Integrated Seller and Manual Seller (per plan).
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: SearchBar(hintText: 'Search buyer, company, item…'),
            ),
            for (final group in dummyHistory) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(group.buyer,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              for (final r in group.receipts)
                ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: Text('${r.receiptNo} · ${formatGhs(r.totalPesewas)}'),
                  subtitle: Text('${r.sellerName}\n${r.issuedAt.toLocal()}'),
                  isThreeLine: true,
                  trailing: const Chip(label: Text('Verified')),
                ),
            ],
          ],
        ),
      );
}
