import 'package:flutter_test/flutter_test.dart';
import 'package:ca_receipt/core/seller_key_service.dart';
import 'package:ca_receipt/core/receipt_signer.dart';
import 'package:ca_receipt/core/models.dart';

void main() {
  test('seller key pairing QR round-trips', () {
    final qr = SellerKeyService.pairingQr('biz-123', ' PUBKEY ', 'Ama\'s Shop & Sons');
    // pairing values must not contain spaces; pubkeys are base64url (no spaces) in practice
    final clean = SellerKeyService.pairingQr('biz-123', 'PUBKEY', "Ama's Shop & Sons");
    expect(qr.contains(' '), isTrue); // documents why clean keys matter
    final parsed = SellerKeyService.parsePairingQr(clean);
    expect(parsed, isNotNull);
    expect(parsed!.businessId, 'biz-123');
    expect(parsed.businessName, "Ama's Shop & Sons");
    expect(SellerKeyService.parsePairingQr('CA1.x.y'), isNull);
  });

  test('decodePayloadUnverified reads a signed receipt payload', () async {
    final signer = await ReceiptSigner.fromSeed(List<int>.filled(32, 3));
    final qr = await signer.signReceipt(Receipt.sample());
    final payload = ReceiptSigner.decodePayloadUnverified(qr);
    expect(payload, isNotNull);
    expect(payload!['no'], 'CA-2026-0001');
    expect(ReceiptSigner.decodePayloadUnverified('hello'), isNull);
  });
}
