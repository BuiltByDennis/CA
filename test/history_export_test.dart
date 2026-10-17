import 'package:flutter_test/flutter_test.dart';
import 'package:ca_receipt/core/export/history_export.dart';

void main() {
  const receipts = [
    ExportReceipt(
      receiptNo: 'CA-2026-0001', direction: 'issued', sellerName: 'My Shop',
      buyerName: 'Ama', paymentMethod: 'MoMo', totalPesewas: 14500,
      issuedAtUnix: 1760000000,
      items: [ExportItem('Rice 5kg', 2, 6000), ExportItem('Oil', 1, 2500)],
    ),
    ExportReceipt(
      receiptNo: 'CA-2026-0009', direction: 'saved', sellerName: 'Other Shop',
      buyerName: null, paymentMethod: 'Cash', totalPesewas: 3000,
      issuedAtUnix: 1760001000,
      items: [ExportItem('Bread', 2, 1500)],
    ),
  ];

  group('history export (v0.8.1)', () {
    test('summary totals split by direction', () {
      final s = summarise(receipts);
      expect(s.issuedCount, 1);
      expect(s.issuedTotal, 14500);
      expect(s.savedCount, 1);
      expect(s.savedTotal, 3000);
    });
    test('counterparty is the buyer for issued, the seller for saved', () {
      expect(receipts[0].counterparty, 'Ama');
      expect(receipts[1].counterparty, 'Other Shop');
    });
    test('PDF builds to a real document', () async {
      final bytes = await buildHistoryPdf(receipts, title: 'Test');
      expect(bytes.length, greaterThan(1000));
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });
    test('XLSX builds to a real zip workbook', () {
      final bytes = buildHistoryXlsx(receipts);
      expect(bytes.length, greaterThan(1000));
      expect(bytes[0], 0x50); // 'P'
      expect(bytes[1], 0x4B); // 'K'
    });
  });
}
