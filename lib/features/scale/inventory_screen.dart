import 'package:flutter/material.dart';
import '../../core/inventory/inventory.dart';
import '../../core/services.dart';

/// Inventory-lite (Phase 7): what you've sold (from issued receipts) and,
/// once you enter a physical count, an estimated on-hand that counts down
/// as you sell. Fully offline.
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late Future<List<InventoryRow>> _rows = _load();

  Future<List<InventoryRow>> _load() async {
    final receipts = await AppServices.db.issuedReceipts();
    final atById = {for (final r in receipts) r.id: r.issuedAtUnix};
    final items = await AppServices.db.allReceiptItems();
    final sold = <SoldLine>[];
    for (final i in items) {
      final at = atById[i.receiptId];
      if (at != null) sold.add(SoldLine(i.name, i.qty, at));
    }
    final counts = {
      for (final c in await AppServices.db.stockCountList())
        c.itemName: StockCount(c.quantityOnHand, c.updatedAtUnix),
    };
    return computeInventory(soldLines: sold, counts: counts);
  }

  Future<void> _count(InventoryRow row) async {
    final ctrl = TextEditingController(text: row.estimatedOnHand?.toString() ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Count — ${row.name}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'How many do you physically have now?'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save count')),
        ],
      ),
    );
    final qty = int.tryParse(ctrl.text.trim());
    if (ok == true && qty != null && qty >= 0) {
      await AppServices.db.setStockCount(row.name, qty);
      setState(() => _rows = _load());
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Stock')),
        body: FutureBuilder<List<InventoryRow>>(
          future: _rows,
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final rows = snap.data!;
            if (rows.isEmpty) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No items yet. Items appear here automatically as you sell them.'),
              ));
            }
            return ListView(padding: const EdgeInsets.all(16), children: [
              const Text('Tap an item to enter a physical count. On-hand is then '
                  'estimated as that count minus what you sell afterwards.'),
              const SizedBox(height: 8),
              for (final r in rows)
                Card(
                  child: ListTile(
                    title: Text(r.name),
                    subtitle: Text('Sold so far: ${r.totalSold}'
                        '${r.lastCount != null ? ' · Last count: ${r.lastCount}' : ' · No count yet'}'),
                    trailing: r.estimatedOnHand == null
                        ? const Text('—')
                        : Chip(
                            label: Text('${r.estimatedOnHand} left'),
                            backgroundColor: r.lowStock ? Colors.red.shade100 : Colors.green.shade100,
                          ),
                    onTap: () => _count(r),
                  ),
                ),
              if (rows.any((r) => r.lowStock))
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Items at 5 or fewer are flagged low.',
                      style: TextStyle(color: Colors.red)),
                ),
            ]);
          },
        ),
      );
}
