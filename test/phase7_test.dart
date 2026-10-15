import 'package:flutter_test/flutter_test.dart';
import 'package:ca_receipt/core/inventory/inventory.dart';
import 'package:ca_receipt/core/referral/referral.dart';
import 'package:ca_receipt/core/tiers/tiers.dart';
import 'package:ca_receipt/core/momo/momo.dart';

void main() {
  group('Phase 7 inventory', () {
    test('on-hand = count minus sales since the count', () {
      final rows = computeInventory(
        soldLines: const [
          SoldLine('Rice 5kg', 3, 100),
          SoldLine('Rice 5kg', 2, 300), // after the count at t=200
          SoldLine('Oil 1L', 4, 300),
        ],
        counts: const {'Rice 5kg': StockCount(20, 200)},
      );
      final rice = rows.firstWhere((r) => r.name == 'Rice 5kg');
      expect(rice.totalSold, 5);
      expect(rice.soldSinceCount, 2);
      expect(rice.estimatedOnHand, 18);
      final oil = rows.firstWhere((r) => r.name == 'Oil 1L');
      expect(oil.estimatedOnHand, isNull, reason: 'never counted — CA must not invent stock');
      expect(oil.totalSold, 4);
    });
    test('low stock flags at five or fewer', () {
      final rows = computeInventory(
        soldLines: const [SoldLine('Sugar', 1, 500)],
        counts: const {'Sugar': StockCount(6, 100)},
      );
      expect(rows.single.estimatedOnHand, 5);
      expect(rows.single.lowStock, isTrue);
    });
  });

  group('Phase 7 referrals', () {
    test('code is stable per business and well-formed', () {
      final a = referralCodeFor('biz-0244000000');
      expect(a, referralCodeFor('biz-0244000000'));
      expect(isValidReferralCode(a), isTrue);
      expect(a, startsWith('CA-'));
      expect(referralCodeFor('biz-999'), isNot(a));
    });
    test('validation rejects junk', () {
      expect(isValidReferralCode('hello'), isFalse);
      expect(isValidReferralCode('CA-ABC'), isFalse);
    });
  });

  group('Phase 7 tiers', () {
    test('free caps branches at 1 (incl. main) and staff at 3', () {
      expect(PlanLimits.canAddBranch(PlanTier.free, 1), isTrue); // the main shop
      expect(PlanLimits.canAddBranch(PlanTier.free, 2), isFalse);
      expect(PlanLimits.canAddStaff(PlanTier.free, 3), isFalse);
      expect(PlanLimits.canAddStaff(PlanTier.free, 2), isTrue);
    });
    test('pro is uncapped', () {
      expect(PlanLimits.canAddBranch(PlanTier.pro, 50), isTrue);
      expect(PlanLimits.canAddStaff(PlanTier.pro, 50), isTrue);
    });
  });

  test('Phase 7 MoMo reference format', () {
    final ref = momoRequestReference(businessId: 'biz-0244000000', receiptNo: 'CA-2026-0042');
    expect(ref, startsWith('CA-2026-0042-'));
    expect(ref.length, 'CA-2026-0042-'.length + 4);
    expect(receiptNoFromReference(ref), 'CA-2026-0042');
    // A different business with the same receipt number gets a different reference.
    final other = momoRequestReference(businessId: 'biz-999', receiptNo: 'CA-2026-0042');
    expect(other, isNot(ref));
  });
}
