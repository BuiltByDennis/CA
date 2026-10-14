import '../models.dart';

// First-run onboarding checklists (Phase 6, pilot prep) — pure logic over
// facts gathered from the local DB, unit-tested. Each step deep-links to the
// screen that completes it. The card hides when all steps are done or when
// dismissed.

class OnboardingFacts {
  const OnboardingFacts({
    required this.issuedCount,
    required this.capturedCount,
    required this.receivedCount,
    required this.pairedSellerKeys,
    required this.verificationStatus,
    required this.designSaved,
    required this.keyBackedUp,
  });
  final int issuedCount;
  final int capturedCount;
  final int receivedCount;
  final int pairedSellerKeys;
  final String? verificationStatus; // null = not started
  final bool designSaved;
  final bool keyBackedUp;
}

class OnboardingStep {
  const OnboardingStep(this.label, this.done, this.route);
  final String label;
  final bool done;
  final String route;
}

List<OnboardingStep> onboardingSteps(UserMode mode, OnboardingFacts f) {
  final verificationDone =
      f.verificationStatus == 'pending' || f.verificationStatus == 'verified';
  return switch (mode) {
    UserMode.buyer => [
        OnboardingStep('Pair a seller: scan their Seller Key QR',
            f.pairedSellerKeys > 0, '/buyer/scan'),
        OnboardingStep('Scan your first receipt', f.receivedCount > 0, '/buyer/scan'),
        OnboardingStep('See your receipts in History', f.receivedCount > 0, '/buyer/history'),
      ],
    UserMode.sellerManual => [
        OnboardingStep('Design your receipt', f.designSaved, '/seller-manual/design'),
        OnboardingStep('Register & verify your business', verificationDone, '/seller-manual/verify'),
        OnboardingStep('Issue your first receipt', f.issuedCount > 0, '/seller-manual/new'),
        OnboardingStep('Back up your signing key', f.keyBackedUp, '/seller-manual/key'),
      ],
    UserMode.sellerIntegrated => [
        OnboardingStep('Capture your first receipt', f.capturedCount > 0, '/seller-integrated/capture'),
        OnboardingStep('Register & verify your business', verificationDone, '/seller-integrated/verify'),
        OnboardingStep('Back up your signing key', f.keyBackedUp, '/seller-manual/key'),
      ],
  };
}

bool onboardingComplete(UserMode mode, OnboardingFacts f) =>
    onboardingSteps(mode, f).every((s) => s.done);
