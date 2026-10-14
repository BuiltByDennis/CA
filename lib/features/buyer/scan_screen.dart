import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/db/app_db.dart';
import '../../core/models.dart';
import '../../core/receipt_signer.dart';
import '../../core/seller_key_service.dart';
import '../../core/services.dart';
import '../../core/sync/sync_service.dart';
import 'scan_overlay.dart';

/// Buyer scanner: scans CAKEY1 pairing QRs and CA1 receipt QRs.
/// Verification is fully offline against locally stored seller keys.
///
/// Fix pack (Phase 6): the result used to render as one long string crammed
/// into a bottom card — clipped and hard to read. It is now a proper
/// full-screen result: status header, then the receipt itself (items,
/// taxes, total) in a readable card.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _Outcome {
  const _Outcome({
    required this.title,
    required this.icon,
    required this.good,
    this.receipt,
    this.explanation = '',
  });
  final String title;
  final IconData icon;
  final bool good;
  final Receipt? receipt;
  final String explanation;
}

class _ScanScreenState extends State<ScanScreen> {
  final _controller = MobileScannerController();
  bool _handling = false;
  _Outcome? _outcome;

  @override
  void initState() {
    super.initState();
    // Best-effort: refresh the verified-seller registry when online.
    SyncService.refreshRegistry();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    _handling = true;
    await _controller.stop();
    await _process(raw.trim());
  }

  Future<void> _process(String text) async {
    final pairing = SellerKeyService.parsePairingQr(text);
    if (pairing != null) {
      await AppServices.db.upsertSellerKey(SellerKeysCompanion.insert(
        businessId: pairing.businessId,
        businessName: pairing.businessName,
        publicKeyB64: pairing.publicKeyB64,
        addedAtUnix: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ));
      setState(() => _outcome = _Outcome(
            title: 'Seller key saved',
            icon: Icons.key,
            good: true,
            explanation:
                '${pairing.businessName} is now paired. You can verify their receipts offline, even in airplane mode.',
          ));
      return;
    }

    final payload = ReceiptSigner.decodePayloadUnverified(text);
    if (payload == null) {
      setState(() => _outcome = const _Outcome(
            title: 'Not a CA code',
            icon: Icons.error_outline,
            good: false,
            explanation: 'This QR is not a CA receipt or a CA seller key.',
          ));
      return;
    }

    Receipt? receipt;
    try {
      receipt = Receipt.fromPayload(payload);
    } catch (_) {}
    final sid = payload['sid'] as String? ?? '';
    final key = await AppServices.db.sellerKey(sid);
    var verified = false;
    if (key != null) {
      verified = await ReceiptSigner.verify(
              text, ReceiptSigner.b64Decode(key.publicKeyB64)) !=
          null;
    }
    final businessVerified = verified && (key?.verifiedBusiness ?? false);
    final id = payload['id'] as String? ?? SellerKeyService.newReceiptId();
    final existing = await AppServices.db.receiptById(id);
    if (existing == null && receipt != null) {
      await AppServices.db.saveReceipt(
        ReceiptsCompanion.insert(
          id: id,
          receiptNo: receipt.receiptNo,
          sellerBusinessId: sid,
          sellerName: receipt.sellerName,
          buyerName: Value(receipt.buyerName),
          totalPesewas: receipt.totalPesewas,
          paymentMethod: receipt.paymentMethod,
          issuedAtUnix: receipt.issuedAt.millisecondsSinceEpoch ~/ 1000,
          source: 'scanned',
          qrText: text,
          direction: 'saved',
          verified: Value(verified),
        ),
        receipt.items
            .map((i) => ReceiptItemsCompanion.insert(
                receiptId: id,
                name: i.name,
                qty: i.qty,
                unitPricePesewas: i.unitPricePesewas))
            .toList(),
      );
    }

    final title = existing != null
        ? 'Already in your History'
        : businessVerified
            ? 'Verified seller — receipt saved'
            : verified
                ? 'Signed receipt — saved'
                : 'Saved — NOT verified';
    final explanation = StringBuffer();
    if (businessVerified) {
      explanation.write(
          'This seller is in the verified business registry, and the receipt signature checks out. ');
    } else if (verified) {
      explanation.write(
          'The signature is genuine (this seller\'s key is on your phone), but the business is not in the verified registry yet. ');
    }
    if (key == null) {
      explanation.write(
          'No key for this seller on this phone yet — scan their Seller Key QR once, or tap Sync on the home screen to download the verified registry, then scan again to check the signature. ');
    } else if (!verified) {
      explanation.write(
          '⚠️ The signature check FAILED — this receipt does not match the seller\'s key. Treat it as tampered and do not rely on it. ');
    }
    if (existing != null) {
      explanation.write('You had already saved this receipt — no duplicate was made.');
    }

    setState(() => _outcome = _Outcome(
          title: title,
          icon: businessVerified
              ? Icons.verified
              : verified
                  ? Icons.check_circle_outline
                  : Icons.warning_amber,
          good: businessVerified || verified,
          receipt: receipt,
          explanation: explanation.toString().trim(),
        ));
  }

  Future<void> _scanAgain() async {
    setState(() {
      _outcome = null;
      _handling = false;
    });
    await _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    final outcome = _outcome;
    return Scaffold(
      appBar: AppBar(title: const Text('Scan for Receipt')),
      body: outcome != null ? _resultView(outcome) : _scannerView(),
    );
  }

  Widget _scannerView() => Stack(children: [
        MobileScanner(controller: _controller, onDetect: _onDetect),
        const Positioned.fill(child: ScanViewfinder()),
        Positioned(
          left: 24,
          right: 24,
          bottom: 28,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                'Point at a CA receipt QR — or a seller\'s Key QR the first time',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ]);

  Widget _resultView(_Outcome o) {
    final r = o.receipt;
    final color = o.good ? const Color(0xFF14532D) : Colors.orange.shade800;
    return ListView(padding: const EdgeInsets.all(16), children: [
      const SizedBox(height: 8),
      Icon(o.icon, size: 64, color: color),
      const SizedBox(height: 8),
      Text(o.title,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      if (r != null) ...[
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.sellerName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text('Receipt ${r.receiptNo}'),
              Text(_fmtDate(r.issuedAt)),
              if (r.buyerName != null) Text('Buyer: ${r.buyerName}'),
              const Divider(height: 24),
              if (r.items.isEmpty)
                const Text('Summary receipt — item details are on the seller\'s copy.')
              else
                for (final i in r.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(children: [
                      Expanded(child: Text(i.name)),
                      Text('${i.qty} × ${formatGhs(i.unitPricePesewas)}'),
                      const SizedBox(width: 12),
                      Text(formatGhs(i.amountPesewas),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ]),
                  ),
              if (r.taxLines.isNotEmpty) ...[
                const Divider(height: 24),
                for (final t in r.taxLines)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(children: [
                      Expanded(child: Text(t.name)),
                      Text(formatGhs(t.amountPesewas)),
                    ]),
                  ),
              ],
              const Divider(height: 24),
              Row(children: [
                const Expanded(
                    child: Text('TOTAL',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                Text(formatGhs(r.totalPesewas),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ]),
              const SizedBox(height: 6),
              Chip(label: Text(r.paymentMethod)),
            ]),
          ),
        ),
      ],
      if (o.explanation.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(o.explanation, style: const TextStyle(height: 1.4)),
      ],
      const SizedBox(height: 20),
      FilledButton.icon(
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan again'),
        onPressed: _scanAgain,
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        icon: const Icon(Icons.history),
        label: const Text('View in History'),
        onPressed: () => context.push('/buyer/history'),
      ),
    ]);
  }

  String _fmtDate(DateTime utc) {
    final d = utc.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.day}/${d.month}/${d.year} · ${two(d.hour)}:${two(d.minute)}';
  }
}
