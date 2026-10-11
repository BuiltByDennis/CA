import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ca_receipt/core/db/app_db.dart';

void main() {
  test('issued receipt is stored and streamed back from Drift', () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.saveReceipt(
      ReceiptsCompanion.insert(
        id: 'r1', receiptNo: 'CA-2026-0001', sellerBusinessId: 'biz-1',
        sellerName: 'CA Demo Farms', totalPesewas: 22000,
        paymentMethod: 'Cash', issuedAtUnix: 1760000000,
        source: 'manual', qrText: 'CA1.x.y', direction: 'issued',
      ),
      [
        ReceiptItemsCompanion.insert(
            receiptId: 'r1', name: 'Tomatoes', qty: 2, unitPricePesewas: 5000),
      ],
    );
    final rows = await db.watchReceipts('issued').first;
    expect(rows.length, 1);
    expect(rows.first.totalPesewas, 22000);
    expect(await db.issuedCount(), 1);
    expect((await db.receiptById('r1'))?.receiptNo, 'CA-2026-0001');
  });
}
