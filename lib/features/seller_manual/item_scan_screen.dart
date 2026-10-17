import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/catalogue/scan_merge.dart';
import '../../core/db/app_db.dart';
import '../../core/models.dart';
import '../../core/services.dart';
import '../buyer/scan_overlay.dart';

/// Retail barcode formats (product packaging + wholesale cartons).
/// QR is deliberately excluded — this scanner is for goods, not receipts.
const _productFormats = [
  BarcodeFormat.ean13,
  BarcodeFormat.ean8,
  BarcodeFormat.upcA,
  BarcodeFormat.upcE,
  BarcodeFormat.code128,
  BarcodeFormat.code39,
  BarcodeFormat.code93,
  BarcodeFormat.codabar,
  BarcodeFormat.itf14,
];

/// Single-shot barcode picker: returns the first code scanned.
class ScanOneBarcodeScreen extends StatefulWidget {
  const ScanOneBarcodeScreen({super.key});
  @override
  State<ScanOneBarcodeScreen> createState() => _ScanOneBarcodeScreenState();
}

class _ScanOneBarcodeScreenState extends State<ScanOneBarcodeScreen> {
  final _controller = MobileScannerController(formats: _productFormats);
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Scan barcode')),
        body: Stack(children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_done) return;
              final code = capture.barcodes.firstOrNull?.rawValue;
              if (code == null) return;
              _done = true;
              Navigator.of(context).pop(code);
            },
          ),
          const Positioned.fill(child: ScanViewfinder()),
        ]),
      );
}

/// Till mode (v0.7.2): scan product barcodes one after another and they
/// pile up into a list — the fast alternative to photographing a receipt
/// or typing items. A barcode is only a NUMBER: the first time a product
/// is scanned, the seller names and prices it once; CA remembers the
/// pairing in My Items forever (fully offline, like a real till's PLU).
class ItemScanScreen extends StatefulWidget {
  const ItemScanScreen({super.key});
  @override
  State<ItemScanScreen> createState() => _ItemScanScreenState();
}

class _ItemScanScreenState extends State<ItemScanScreen> {
  final _controller = MobileScannerController(formats: _productFormats);
  final List<ScannedEntry> _adds = [];
  final Set<String> _skipped = {};
  String? _lastCode;
  DateTime _lastAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _prompting = false;
  String? _lastAddedName;

  List<ScannedEntry> get _merged => mergeScanned(_adds);
  int get _total => _merged.fold(0, (s, e) => s + e.qty * e.unitPricePesewas);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_prompting) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || _skipped.contains(code)) return;
    final now = DateTime.now();
    if (code == _lastCode && now.difference(_lastAt).inMilliseconds < 1500) return;
    _lastCode = code;
    _lastAt = now;
    await _handleCode(code);
  }

  Future<void> _handleCode(String code) async {
    final known = await AppServices.db.catalogueItemByBarcode(code);
    if (known != null) {
      HapticFeedback.mediumImpact();
      setState(() {
        _adds.add(ScannedEntry(known.name, 1, known.unitPricePesewas));
        _lastAddedName = known.name;
      });
      return;
    }
    // First time this product is ever scanned: name + price it once.
    _prompting = true;
    await _controller.stop();
    if (!mounted) return;
    final name = TextEditingController();
    final price = TextEditingController();
    final save = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New product'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Barcode $code is not in your items yet. Name it once — CA will remember it.'),
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Product name')),
          TextField(controller: price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Your price GH₵')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Skip this item')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save & add')),
        ],
      ),
    );
    if (save == true && name.text.trim().isNotEmpty) {
      final pesewas = ((double.tryParse(price.text.trim()) ?? 0) * 100).round();
      await AppServices.db.saveCatalogueItem(CatalogueItemsCompanion.insert(
        id: 'cat-${DateTime.now().millisecondsSinceEpoch}',
        name: name.text.trim(),
        unitPricePesewas: Value(pesewas),
        barcode: Value(code),
        createdAtUnix: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ));
      HapticFeedback.mediumImpact();
      if (mounted) {
        setState(() {
          _adds.add(ScannedEntry(name.text.trim(), 1, pesewas));
          _lastAddedName = name.text.trim();
        });
      }
    } else {
      _skipped.add(code);
    }
    _prompting = false;
    if (mounted) await _controller.start();
  }

  Future<void> _typeCode() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Type a barcode'),
        content: TextField(controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Barcode number under the lines')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      _lastCode = null; // manual entry bypasses the refire guard
      await _handleCode(ctrl.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Scan items')),
        // Layout fixed after Dennis's device report (words rendering
        // vertically in the squeezed half-screen layout): the camera now
        // fills the screen exactly like the buyer scanner — which
        // displays correctly — and the scanned list rides as a bottom
        // sheet over it.
        body: Stack(children: [
          Positioned.fill(
              child: MobileScanner(controller: _controller, onDetect: _onDetect)),
          const Positioned.fill(child: ScanViewfinder()),
          if (_lastAddedName != null)
            Positioned(
              left: 16, right: 16, top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.green.shade700,
                    borderRadius: BorderRadius.circular(20)),
                child: Text('Added: $_lastAddedName',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center),
              ),
            ),
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [BoxShadow(blurRadius: 12, color: Colors.black26)],
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.42),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
                    child: Row(children: [
                      Expanded(child: Text('Scanned (${_merged.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                      TextButton.icon(
                        icon: const Icon(Icons.keyboard),
                        label: const Text('Type code'),
                        onPressed: _typeCode,
                      ),
                    ]),
                  ),
                  Flexible(
                    child: _merged.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text('Point at a product barcode. Each scan adds one.'))
                        : ListView(
                            shrinkWrap: true,
                            children: [
                              for (final e in _merged)
                                ListTile(
                                  dense: true,
                                  title: Text(e.name),
                                  subtitle: Text('${e.qty} × ${formatGhs(e.unitPricePesewas)}'),
                                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Text(formatGhs(e.qty * e.unitPricePesewas),
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: () => setState(() {
                                        final i = _adds.lastIndexWhere((a) =>
                                            a.name.toLowerCase() == e.name.toLowerCase());
                                        if (i >= 0) _adds.removeAt(i);
                                      }),
                                    ),
                                  ]),
                                ),
                            ],
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      Expanded(child: Text('Total: ${formatGhs(_total)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                      FilledButton(
                        onPressed: _merged.isEmpty
                            ? null
                            : () => Navigator.of(context).pop(_merged),
                        child: const Text('Add to receipt'),
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      );
}
