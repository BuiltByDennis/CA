import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ca_receipt/core/db/app_db.dart';
import 'package:ca_receipt/core/models.dart';
import 'package:ca_receipt/core/receipt_signer.dart';
import 'package:ca_receipt/core/tax/tax_report.dart';

void main() {
  Future<String> qrFor(Receipt r) async =>
      (await ReceiptSigner.fromSeed(List<int>.filled(32, 5))).signReceipt(r);

  Receipt mk(String no, int day, List<TaxLine> tx, {int itemsTotal = 10000}) =>
      Receipt(
        id: 'id-$no', receiptNo: no, sellerBusinessId: 'biz-1',
        sellerName: 'Test Shop', buyerName: 'Kwame',
        items: [ReceiptItem(name: 'Goods', qty: 1, unitPricePesewas: itemsTotal)],
        taxLines: tx,
        totalPesewas: itemsTotal + tx.fold(0, (s, t) => s + t.amountPesewas),
        issuedAt: DateTime.utc(2026, 10, day, 10),
        source: 'manual', paymentMethod: 'MoMo',
      );

  group('tax report', () {
    test('aggregates components from signed payloads; discounts reduce net, not tax', () async {
      final vat = TaxLine(name: 'VAT', ratePercent: 15, amountPesewas: 1500);
      final nhil = TaxLine(name: 'NHIL', ratePercent: 2.5, amountPesewas: 250);
      final discount = TaxLine(name: 'Discount', ratePercent: 0, amountPesewas: -500);
      final q1 = await qrFor(mk('CA-2026-0001', 3, [vat, nhil]));
      final q2 = await qrFor(mk('CA-2026-0002', 4, [vat, discount]));
      final report = buildTaxReport(
        [
          (qrText: q1, cashierName: 'Esi', paymentStatus: 'paid', paymentMethodOverride: null),
          (qrText: q2, cashierName: null, paymentStatus: 'pending', paymentMethodOverride: null),
          (qrText: 'garbage', cashierName: null, paymentStatus: null, paymentMethodOverride: null),
        ],
        from: DateTime.utc(2026, 10, 1),
        to: DateTime.utc(2026, 11, 1),
      );
      expect(report.rows.length, 2);
      expect(report.skippedUndecodable, 1);
      expect(report.totalTaxByComponent['VAT'], 3000);
      expect(report.totalTaxByComponent['NHIL'], 250);
      expect(report.totalTaxByComponent.containsKey('Discount'), isFalse);
      // receipt2: total = 10000+1500-500=11000; net = 11000-1500 = 9500 (discount applied)
      expect(report.rows[1].netPesewas, 9500);
      expect(report.grandTotalPesewas, 11750 + 11000);

      final csv = taxReportCsv(report, businessName: 'Test Shop');
      expect(csv, contains('VAT (GHS)'));
      expect(csv, contains('SUMMARY'));
      expect(csv, contains('not a GRA filing'));
      expect(report.rows[1].paymentStatus, 'pending');
    });

    test('period filter excludes out-of-range receipts', () async {
      final q = await qrFor(mk('CA-2026-0009', 20, const []));
      final report = buildTaxReport(
        [(qrText: q, cashierName: null, paymentStatus: null, paymentMethodOverride: null)],
        from: DateTime.utc(2026, 10, 1), to: DateTime.utc(2026, 10, 15));
      expect(report.rows, isEmpty);
    });

    test('items CSV flattens lines for the accountant', () async {
      final q = await qrFor(mk('CA-2026-0003', 5, const []));
      final csv = itemsCsv(
        [(qrText: q, cashierName: 'Esi', paymentStatus: null, paymentMethodOverride: null)],
        from: DateTime.utc(2026, 10, 1), to: DateTime.utc(2026, 11, 1));
      expect(csv, contains('Goods'));
      expect(csv, contains('CA-2026-0003'));
    });
  });

  group('readiness + payload round-trip', () {
    test('fromPayload rebuilds items, taxes, date', () async {
      final r = mk('CA-2026-0007', 9,
          [TaxLine(name: 'VAT', ratePercent: 15, amountPesewas: 1500)]);
      final payload = ReceiptSigner.decodePayloadUnverified(await qrFor(r))!;
      final back = Receipt.fromPayload(payload);
      expect(back.receiptNo, r.receiptNo);
      expect(back.taxLines.single.amountPesewas, 1500);
      expect(back.items.single.name, 'Goods');
      expect(back.totalPesewas, r.totalPesewas);
    });

    test('checklist flags missing TIN and unconfirmed presets', () {
      final checks = evatReadiness(
        tin: null, vatRegistered: false, businessVerified: false,
        presetsConfirmed: false, receiptsWithTaxLines: 3, totalReceipts: 5);
      expect(checks.where((c) => c.ok).length, 0);
      final good = evatReadiness(
        tin: 'C0012345678', vatRegistered: true, businessVerified: true,
        presetsConfirmed: true, receiptsWithTaxLines: 5, totalReceipts: 5);
      expect(good.every((c) => c.ok), isTrue);
    });
  });

  test('payment status persists (Drift v5)', () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.saveReceipt(
      ReceiptsCompanion.insert(
        id: 'r1', receiptNo: 'CA-2026-0001', sellerBusinessId: 'b',
        sellerName: 'S', totalPesewas: 100, paymentMethod: 'MoMo',
        issuedAtUnix: 1, source: 'manual', qrText: 'q', direction: 'issued',
        paymentStatus: const Value('pending'),
        buyerPhone: const Value('0244000000'),
      ),
      const [],
    );
    await db.setPaymentStatus('r1', 'paid', reference: 'TXN123');
    final rows = await db.issuedReceipts();
    expect(rows.single.paymentStatus, 'paid');
    expect(rows.single.paymentReference, 'TXN123');
    expect(rows.single.buyerPhone, '0244000000');
  });
}
