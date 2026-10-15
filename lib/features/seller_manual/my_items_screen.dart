import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/catalogue/catalogue.dart';
import '../../core/catalogue/csv_import.dart';
import '../../core/db/app_db.dart';
import '../../core/models.dart';
import '../../core/services.dart';
import 'item_scan_screen.dart';

/// My Items (v0.7.1; bulk import v0.7.3): the seller's own product list —
/// add, price, edit, remove, one by one OR all at once: businesses that
/// already keep their stock in another system (supermarket POS, Excel)
/// export a CSV there and import it here — names, prices and barcodes
/// land in one go, no re-typing. Re-importing an updated file refreshes
/// prices instead of duplicating (matched by barcode, then name).
class MyItemsScreen extends StatefulWidget {
  const MyItemsScreen({super.key});
  @override
  State<MyItemsScreen> createState() => _MyItemsScreenState();
}

class _MyItemsScreenState extends State<MyItemsScreen> {
  List<CatalogueItemRow> _items = [];
  bool _loaded = false;
  String _query = '';

  List<CatalogueItemRow> get _visible => _query.isEmpty
      ? _items
      : _items
          .where((i) =>
              i.name.toLowerCase().contains(_query.toLowerCase()) ||
              (i.barcode ?? '').contains(_query))
          .toList();

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

  // --- bulk import ---

  Future<void> _import() async {
    final picked = await FilePicker.pickFiles(
        type: FileType.custom, allowedExtensions: ['csv', 'txt', 'tsv']);
    if (picked.isEmpty) return;
    final bytes = await picked.first.xFile.readAsBytes();
    final analysis = analyzeImport(utf8.decode(bytes, allowMalformed: true));
    if (!mounted) return;
    if (analysis.rows.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('No products found'),
          content: const Text('CA could not find product rows in that file. '
              'Export a CSV from your other system with columns for name, '
              'price and barcode — or use our template (menu → Get the CSV '
              'template), fill it in Excel, and import that.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
      return;
    }
    final plan = planImport(
      [for (final i in _items) (id: i.id, name: i.name, barcode: i.barcode)],
      analysis.rows,
    );
    if (!mounted) return;
    final go = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import price list?'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Found ${analysis.rows.length} products in the file.'),
          Text('• ${plan.inserts.length} new items to add'),
          Text('• ${plan.updates.length} existing items to update (price refreshed)'),
          if (analysis.skippedNoName > 0) Text('• ${analysis.skippedNoName} rows skipped (no name)'),
          if (analysis.skippedBadPrice > 0) Text('• ${analysis.skippedBadPrice} rows skipped (price unreadable)'),
          const SizedBox(height: 8),
          Text('Columns read: name = "${analysis.nameHeader ?? 'column 1'}", '
              'price = "${analysis.priceHeader ?? 'column 2'}"'
              '${analysis.barcodeHeader != null ? ', barcode = "$analysis.barcodeHeader"' : ''}.',
              style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          for (final r in analysis.rows.take(3))
            Text('– ${r.name} · ${formatGhs(r.pricePesewas)}${r.barcode != null ? ' · ${r.barcode}' : ''}',
                style: const TextStyle(fontSize: 12)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Import')),
        ],
      ),
    );
    if (go != true) return;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    var n = 0;
    await AppServices.db.transaction(() async {
      for (final u in plan.updates) {
        final old = _items.firstWhere((i) => i.id == u.id);
        await AppServices.db.saveCatalogueItem(CatalogueItemsCompanion.insert(
          id: u.id,
          name: u.row.name,
          unitPricePesewas: Value(u.row.pricePesewas),
          barcode: Value(u.row.barcode ?? old.barcode),
          createdAtUnix: old.createdAtUnix,
        ));
      }
      for (final r in plan.inserts) {
        await AppServices.db.saveCatalogueItem(CatalogueItemsCompanion.insert(
          id: 'cat-imp-$now-${n++}',
          name: r.name,
          unitPricePesewas: Value(r.pricePesewas),
          barcode: Value(r.barcode),
          createdAtUnix: now,
        ));
      }
    });
    await _refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Imported: ${plan.inserts.length} new, ${plan.updates.length} updated.')));
    }
  }

  Future<void> _shareExport() => SharePlus.instance.share(ShareParams(
      text: catalogueToCsv([
        for (final i in _items)
          (name: i.name, pricePesewas: i.unitPricePesewas, barcode: i.barcode)
      ]),
      subject: 'CA My Items (CSV)'));

  Future<void> _shareTemplate() => SharePlus.instance.share(
      ShareParams(text: templateCsv, subject: 'CA price list template (CSV)'));

  // --- single-item edit ---

  Future<void> _edit(CatalogueItemRow? item) async {
    final name = TextEditingController(text: item?.name ?? '');
    final barcode = TextEditingController(text: item?.barcode ?? '');
    final price = TextEditingController(
        text: item == null || item.unitPricePesewas == 0
            ? ''
            : (item.unitPricePesewas / 100).toStringAsFixed(2));
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item == null ? 'Add item' : 'Edit item'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Item name')),
          TextField(controller: price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Usual price GH₵ (optional)')),
          StatefulBuilder(builder: (context, setLocal) => TextField(
              controller: barcode,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Barcode (optional)',
                helperText: 'So Scan Items can add it automatically.',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.barcode_reader),
                  onPressed: () async {
                    final code = await Navigator.of(context).push<String>(
                        MaterialPageRoute(builder: (_) => const ScanOneBarcodeScreen()));
                    if (code != null) setLocal(() => barcode.text = code);
                  },
                ),
              ))),
        ])),
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
      barcode: Value(barcode.text.trim().isEmpty ? null : barcode.text.trim()),
      createdAtUnix: item?.createdAtUnix ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
    ));
    _refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('My Items'),
          actions: [
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'import') _import();
                if (v == 'export') _shareExport();
                if (v == 'template') _shareTemplate();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'import', child: Text('Import price list (CSV)')),
                PopupMenuItem(value: 'export', child: Text('Export my items (CSV)')),
                PopupMenuItem(value: 'template', child: Text('Get the CSV template')),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _edit(null),
          child: const Icon(Icons.add),
        ),
        body: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search items or barcode…',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('${_items.length} items. Already have your stock in another system? '
                        'Menu (⋮) → Import price list loads it all at once.',
                        style: const TextStyle(fontSize: 12.5)),
                  ),
                ),
                Expanded(
                  child: _visible.isEmpty
                      ? const Center(child: Text('Nothing matches — tap + to add an item.'))
                      : ListView.builder(
                          itemCount: _visible.length,
                          itemBuilder: (_, idx) {
                            final i = _visible[idx];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: ListTile(
                                title: Text(i.name),
                                subtitle: Text((i.unitPricePesewas == 0
                                        ? 'No price set — you\'ll type it per sale'
                                        : formatGhs(i.unitPricePesewas)) +
                                    (i.barcode != null ? ' · 🏷 ${i.barcode}' : '')),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    await AppServices.db.deleteCatalogueItem(i.id);
                                    _refresh();
                                  },
                                ),
                                onTap: () => _edit(i),
                              ),
                            );
                          },
                        ),
                ),
              ]),
      );
}
