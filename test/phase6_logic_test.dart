import 'package:flutter_test/flutter_test.dart';
import 'package:ca_receipt/core/design/receipt_design.dart';
import 'package:ca_receipt/core/feedback/feedback_service.dart';
import 'package:ca_receipt/core/models.dart';
import 'package:ca_receipt/core/onboarding/onboarding.dart';

const empty = OnboardingFacts(
  issuedCount: 0, capturedCount: 0, receivedCount: 0, pairedSellerKeys: 0,
  verificationStatus: null, designSaved: false, keyBackedUp: false,
);

void main() {
  group('onboarding', () {
    test('buyer steps complete in order as facts arrive', () {
      var steps = onboardingSteps(UserMode.buyer, empty);
      expect(steps.every((s) => !s.done), isTrue);
      const paired = OnboardingFacts(
        issuedCount: 0, capturedCount: 0, receivedCount: 0, pairedSellerKeys: 1,
        verificationStatus: null, designSaved: false, keyBackedUp: false);
      steps = onboardingSteps(UserMode.buyer, paired);
      expect(steps[0].done, isTrue);
      expect(steps[1].done, isFalse);
      const scanned = OnboardingFacts(
        issuedCount: 0, capturedCount: 0, receivedCount: 2, pairedSellerKeys: 1,
        verificationStatus: null, designSaved: false, keyBackedUp: false);
      expect(onboardingComplete(UserMode.buyer, scanned), isTrue);
    });

    test('manual seller: pending verification counts as done; design + first issue + backup tracked', () {
      const f = OnboardingFacts(
        issuedCount: 1, capturedCount: 0, receivedCount: 0, pairedSellerKeys: 0,
        verificationStatus: 'pending', designSaved: true, keyBackedUp: false);
      final steps = onboardingSteps(UserMode.sellerManual, f);
      expect(steps.map((s) => s.done).toList(), [true, true, true, false]);
    });

    test('integrated seller: capture step uses captured count', () {
      const f = OnboardingFacts(
        issuedCount: 3, capturedCount: 1, receivedCount: 0, pairedSellerKeys: 0,
        verificationStatus: 'verified', designSaved: false, keyBackedUp: true);
      expect(onboardingComplete(UserMode.sellerIntegrated, f), isTrue);
    });
  });

  group('receipt design', () {
    test('json round-trips and copyWith keeps other fields', () {
      const d = ReceiptDesign(businessDisplayName: 'Ama Provisions',
          footerNote: 'MoMo: 0244 000 000', applyTaxByDefault: true,
          defaultPayment: 'MoMo', style: 2);
      final back = ReceiptDesign.fromJson(d.toJson());
      expect(back.businessDisplayName, 'Ama Provisions');
      expect(back.style, 2);
      expect(back.copyWith(style: 1).footerNote, 'MoMo: 0244 000 000');
    });
  });

  test('feedback diagnostics are compact and content-free', () {
    final s = FeedbackService.buildDiagnostics(
      mode: 'sellerManual', issued: 12, received: 3,
      verificationStatus: 'verified', supabaseConfigured: true);
    expect(s, contains('issued=12'));
    expect(s, contains('verification=verified'));
  });
}
