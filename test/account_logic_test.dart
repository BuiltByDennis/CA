import 'package:flutter_test/flutter_test.dart';
import 'package:ca_receipt/core/account/key_wrap.dart';
import 'package:ca_receipt/core/account/restore_logic.dart';
import 'package:ca_receipt/core/models.dart';
import 'package:ca_receipt/core/receipt_signer.dart';

void main() {
  group('seller key wrap (Phase 8)', () {
    final seed = List<int>.generate(32, (i) => i * 7 % 256);
    test('round-trips with the right password', () async {
      final w = await wrapSeed(seed, 'correct horse battery');
      expect(await unwrapSeed(w, 'correct horse battery'), seed);
    });
    test('wrong password yields null, never a wrong key', () async {
      final w = await wrapSeed(seed, 'right');
      expect(await unwrapSeed(w, 'wrong'), isNull);
    });
    test('each wrap uses a fresh salt + nonce', () async {
      final a = await wrapSeed(seed, 'pw');
      final b = await wrapSeed(seed, 'pw');
      expect(a.salt, isNot(b.salt));
      expect(a.ciphertext, isNot(b.ciphertext));
    });
  });

  group('restore mapping', () {
    Future<String> qrFor(String sid) async {
      final signer = await ReceiptSigner.fromSeed(
          List<int>.generate(32, (i) => (i * 13 + 5) % 256));
      final r = Receipt(
        id: 'r-1', receiptNo: 'CA-2026-0007', sellerBusinessId: sid,
        sellerName: 'Shop', items: const [ReceiptItem(name: 'Rice', qty: 1, unitPricePesewas: 5000)],
        taxLines: const [], totalPesewas: 5000,
        issuedAt: DateTime.utc(2026, 10, 1), source: 'manual',
      );
      return signer.signReceipt(r);
    }

    test('my own receipt restores as issued', () async {
      final qr = await qrFor('biz-123');
      final r = restoredReceiptFromQr(qr, myBusinessId: 'biz-123');
      expect(r!.direction, 'issued');
      expect(r.source, 'manual');
      expect(r.items.single.name, 'Rice');
    });
    test('someone else\'s receipt restores as saved/scanned', () async {
      final qr = await qrFor('biz-other');
      final r = restoredReceiptFromQr(qr, myBusinessId: 'biz-123');
      expect(r!.direction, 'saved');
      expect(r.source, 'scanned');
    });
    test('junk QR text restores nothing', () {
      expect(restoredReceiptFromQr('not a receipt', myBusinessId: 'biz-1'), isNull);
    });
    test('business id: server wins, else derive from phone like signup', () {
      expect(restoredBusinessId(serverCaBusinessId: 'biz-999', phone: '0244'), 'biz-999');
      expect(restoredBusinessId(serverCaBusinessId: null, phone: '+233 244 000 111'), 'biz-233244000111');
    });
    test('catalogue fingerprint changes when the list changes', () {
      final a = catalogueFingerprint([(id: '1', name: 'Rice', price: 100, barcode: null)]);
      final b = catalogueFingerprint([(id: '1', name: 'Rice', price: 200, barcode: null)]);
      final c = catalogueFingerprint([(id: '1', name: 'Rice', price: 100, barcode: null)]);
      expect(a, isNot(b));
      expect(a, c);
    });
  });
}
