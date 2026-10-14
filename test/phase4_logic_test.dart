import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ca_receipt/core/db/app_db.dart';
import 'package:ca_receipt/core/analytics/analytics.dart';
import 'package:ca_receipt/core/i18n/strings.dart';
import 'package:ca_receipt/core/printing/print_service.dart';
import 'package:ca_receipt/core/staff/staff_logic.dart' as staff;

AnalyticsReceipt r(int total, DateTime at,
        {String? buyer, String pay = 'Cash', String? cashier,
        List<({String name, int qty, int amountPesewas})> items = const []}) =>
    AnalyticsReceipt(
        totalPesewas: total, issuedAt: at, buyerName: buyer,
        paymentMethod: pay, cashierName: cashier, items: items);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 10, 14, 12);

  group('analytics', () {
    final data = [
      r(10000, DateTime(2026, 10, 14, 9), buyer: 'Kwame', cashier: 'Esi', items: [
        (name: 'Rice 5kg', qty: 1, amountPesewas: 6000),
        (name: 'Oil 1L', qty: 2, amountPesewas: 4000),
      ]),
      r(5000, DateTime(2026, 10, 14, 10), buyer: 'Kwame', pay: 'MoMo', cashier: 'Esi', items: [
        (name: 'Rice 5kg', qty: 1, amountPesewas: 5000),
      ]),
      r(7000, DateTime(2026, 10, 10, 10), buyer: 'Ama', items: const []), // 4 days ago
      r(99900, DateTime(2026, 8, 1, 10)), // way outside 7d
    ];

    test('7-day window totals, count and average', () {
      final s = summarize(data, now: now, days: 7);
      expect(s.totalPesewas, 22000);
      expect(s.receiptCount, 3);
      expect(s.averageBasketPesewas, 7333);
      expect(s.dailyTotals.length, 7);
    });

    test('today window only counts today', () {
      final s = summarize(data, now: now, days: 1);
      expect(s.totalPesewas, 15000);
      expect(s.receiptCount, 2);
    });

    test('top items, buyers, payments, cashiers', () {
      final s = summarize(data, now: now, days: 7);
      expect(s.topItemsByQty.first.name, 'Rice 5kg');
      expect(s.topItemsByQty.first.qty, 2);
      expect(s.topBuyers.first.name, 'Kwame');
      expect(s.topBuyers.first.amountPesewas, 15000);
      expect(s.paymentSplit['MoMo'], 5000);
      expect(s.paymentSplit['Cash'], 17000);
      expect(s.cashierTotals.first.name, 'Esi');
      expect(s.cashierTotals.first.amountPesewas, 15000);
    });
  });

  group('staff permissions', () {
    test('matrix matches the plan', () {
      expect(staff.canIssue(staff.roleCashier), isTrue);
      expect(staff.canViewAnalytics(staff.roleCashier), isFalse);
      expect(staff.canIssue(staff.roleAccountant), isFalse);
      expect(staff.canViewAnalytics(staff.roleAccountant), isTrue);
      expect(staff.canManageStaff(staff.roleManager), isFalse);
      expect(staff.canManageStaff(staff.roleOwner), isTrue);
      expect(staff.canExportKey(staff.roleManager), isFalse);
      expect(staff.canManageVerification(staff.roleManager), isTrue);
    });

    test('PIN hash/verify round-trips and wrong PIN fails', () async {
      final salt = staff.newPinSalt();
      final hash = await staff.hashPin('2468', salt);
      expect(await staff.verifyPin('2468', salt, hash), isTrue);
      expect(await staff.verifyPin('0000', salt, hash), isFalse);
    });
  });

  group('i18n', () {
    test('Twi strings exist for dashboard keys and English falls back', () {
      LanguageService.code.value = 'tw';
      expect(LanguageService.t('buyer'), 'Ɔtɔfo');
      expect(LanguageService.t('nonexistent-key'), 'nonexistent-key');
      LanguageService.code.value = 'en';
      expect(LanguageService.t('newReceipt'), 'New Receipt');
    });
  });

  group('printing', () {
    test('slip bytes are generated with business name and QR block', () async {
      final bytes = await PrintSlipBuilder.build(SlipData(
        businessName: 'Ama Provisions',
        receiptNo: 'CA-2026-0001',
        dateText: '2026-10-14',
        totalText: 'GH₵220.00',
        itemLines: ['1 x Rice 5kg  ${slipMoney(6000)}'],
        qrText: 'CA1.test.sig',
      ));
      expect(bytes.length, greaterThan(200));
      expect(String.fromCharCodes(bytes.where((b) => b < 128)), contains('Ama Provisions'));
      expect(slipMoney(123450), 'GHS 1,234.50');
      expect(slipSafe('Ɔtɔfo GH₵'), 'Otofo GHS');
    });
  });

  group('staff storage (Drift v4)', () {
    test('staff rows persist; receipt cashier stamp persists', () async {
      final db = AppDb.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await db.saveStaff(StaffMembersCompanion.insert(
        id: 'staff-1', name: 'Esi', role: 'cashier',
        pinSalt: 's', pinHash: 'h', createdAtUnix: 1,
      ));
      final rows = await db.staffList();
      expect(rows.single.name, 'Esi');
      await db.setStaffActive('staff-1', false);
      expect((await db.staffList()).single.active, isFalse);

      await db.saveReceipt(
        ReceiptsCompanion.insert(
          id: 'r1', receiptNo: 'CA-2026-0001', sellerBusinessId: 'b',
          sellerName: 'S', totalPesewas: 100, paymentMethod: 'Cash',
          issuedAtUnix: 1, source: 'manual', qrText: 'q', direction: 'issued',
          cashierName: const Value('Esi'),
        ),
        const [],
      );
      final issued = await db.issuedReceipts();
      expect(issued.single.cashierName, 'Esi');
    });
  });
}
