import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/db/app_db.dart';
import '../../core/models.dart';
import '../../core/receipt_signer.dart';
import '../../core/seller_key_service.dart';
import '../../core/services.dart';

/// Buyer scanner (Phase 1): scans CAKEY1 pairing QRs and CA1 receipt QRs.
/// Verification is fully offline against locally stored seller keys.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _controller = MobileScannerController();
  bool _handling = false;
  String? _resultTitle;
  String? _resultBody;
  bool? _verified;

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    _handling = true;
    await _controller.stop();
    await _process(raw.trim());
  }

  Future<void> _process(String text) async {
    // Seller key pairing
    final pairing = SellerKeyService.parsePairingQr(text);
    if (pairing != null) {
      await AppServices.db.upsertSellerKey(SellerKeysCompanion.insert(
        businessId: pairing.businessId, businessName: pairing.businessName,
        publicKeyB64: pairing.publicKeyB64,
        addedAtUnix: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ));
      setState(() {
        _resultTitle = 'Seller key saved';
        _resultBody = '${pairing.businessName} — you can now verify their receipts offline.';
        _verified = true;
      });
      return;
    }
    // Receipt
    final payload = ReceiptSigner.decodePayloadUnverified(text);
    if (payload == null) {
      setState(() {
        _resultTitle = 'Not a CA code';
        _resultBody = 'This QR is not a CA receipt or seller key.';
        _verified = false;
      });
      return;
    }
    final sid = payload['sid'] as String? ?? '';
    final key = await AppServices.db.sellerKey(sid);
    bool verified = false;
    if (key != null) {
      verified = await ReceiptSigner.verify(
              text, ReceiptSigner.b64Decode(key.publicKeyB64)) !=
          null;
    }
    final id = payload['id'] as String? ?? SellerKeyService.newReceiptId();
    final existing = await AppServices.db.receiptById(id);
    if (existing == null) {
      final items = (payload['it'] as List? ?? [])
          .map((e) => ReceiptItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
      await AppServices.db.saveReceipt(
        ReceiptsCompanion.insert(
          id: id, receiptNo: payload['no'] as String? ?? '-',
          sellerBusinessId: sid,
          sellerName: payload['sn'] as String? ?? 'Unknown seller',
          buyerName: Value(payload['bn'] as String?),
          totalPesewas: payload['tot'] as int? ?? 0,
          paymentMethod: payload['pm'] as String? ?? 'Cash',
          issuedAtUnix: payload['ts'] as int? ??
              DateTime.now().millisecondsSinceEpoch ~/ 1000,
          source: 'scanned', qrText: text, direction: 'saved',
          verified: Value(verified),
        ),
        items.map((i) => ReceiptItemsCompanion.insert(
            receiptId: id, name: i.name, qty: i.qty,
            unitPricePesewas: i.unitPricePesewas)).toList(),
      );
    }
    setState(() {
      _resultTitle = existing != null
          ? 'Already saved'
          : (verified ? '✅ Verified receipt saved' : 'Saved — NOT verified');
      _resultBody =
          '${payload['sn']} · Receipt ${payload['no']} · ${formatGhs(payload['tot'] as int? ?? 0)}'
          '${key == null ? '\n\nNo key for this seller on this phone yet — scan their Seller Key QR, or wait for the Phase 3 registry, to verify.' : ''}'
          '${key != null && !verified ? '\n\n⚠️ Signature check FAILED — treat this receipt as tampered.' : ''}';
      _verified = verified;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Scan for Receipt')),
        body: Column(children: [
          Expanded(child: MobileScanner(controller: _controller, onDetect: _onDetect)),
          if (_resultTitle != null)
            Card(
              color: _verified == true ? Colors.green.shade50 : Colors.orange.shade50,
              child: ListTile(
                title: Text(_resultTitle!),
                subtitle: Text(_resultBody ?? ''),
                trailing: FilledButton(
                  child: const Text('Scan again'),
                  onPressed: () async {
                    setState(() { _resultTitle = null; _handling = false; });
                    await _controller.start();
                  },
                ),
              ),
            )
          else
            const Padding(padding: EdgeInsets.all(16),
                child: Text('Point at a CA receipt QR — or a seller\'s Key QR the first time.')),
        ]),
      );
}
