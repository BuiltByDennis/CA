import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import '../../core/catalogue/catalogue.dart';
import '../../core/db/app_db.dart';
import '../../core/models.dart';
import '../../core/services.dart';

/// My Items (v0.7.1): the seller's own product list — add, price, edit,
/// remove. These are the one-tap items on the New Receipt screen, so a
/// provision shop's tomatoes/onions/rice are always one tap away at
/// their prices, not typed from scratch every sale.
class MyItemsScreen extends StatefulWidget {
  const MyItemsScreen({super.key});
  @override
  State<MyItemsScreen> createState() => _MyItemsScreenState();
}

class _MyItemsScreenState extends State<MyItemsScreen> {
  List<CatalogueItemRow> _items = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    await CatalogueService.seedIfFirstUse();
    final items = await AppServices.db.catalogueList();
    if (mounted) {
      setState(() {
        _items = items;
        _loaded = true;
      });
    }
  }

  Future<void> _edit(CatalogueItemRow? item) async {
    final name = TextEditingController(text: item?.name ?? '');
    final price = TextEditingController(
        text: item == null || item.unitPricePesewas == 0
            ? ''
            : (item.unitPricePesewas / 100).toStringAsFixed(2));
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item == null ? 'Add item' : 'Edit item'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Item name')),
          TextField(controller: price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Usual price GH₵ (optional)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    final pesewas = ((double.tryParse(price.text.trim()) ?? 0) * 100).round();
    await AppServices.db.saveCatalogueItem(CatalogueItemsCompanion.insert(
      id: item?.id ?? 'cat-${DateTime.now().millisecondsSinceEpoch}',
      name: name.text.trim(),
      unitPricePesewas: Value(pesewas),
      createdAtUnix: item?.createdAtUnix ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
    ));
    _refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('My Items')),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _edit(null),
          child: const Icon(Icons.add),
        ),
        body: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : ListView(padding: const EdgeInsets.all(16), children: [
                const Text('Your products, at your prices. Tap one to edit; '
                    'these appear as quick-pick items when you create a receipt.'),
                const SizedBox(height: 12),
                if (_items.isEmpty)
                  const Text('No items yet — tap + to add what you sell.'),
                for (final i in _items)
                  Card(
                    child: ListTile(
                      title: Text(i.name),
                      subtitle: Text(i.unitPricePesewas == 0
                          ? 'No price set — you\'ll type it per sale'
                          : formatGhs(i.unitPricePesewas)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await AppServices.db.deleteCatalogueItem(i.id);
                          _refresh();
                        },
                      ),
                      onTap: () => _edit(i),
                    ),
                  ),
              ]),
      );
}
