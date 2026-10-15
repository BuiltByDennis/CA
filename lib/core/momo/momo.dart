/// MoMo payment linking (Phase 7). Every pending MoMo receipt carries a
/// payment-request reference: `<receiptNo>-<4-char business tag>` (receipt
/// numbers start with CA- already, and the tag keeps references unique
/// across businesses, since two shops can both have a CA-2026-0001).
/// When the seller collects via MTN MoMo (request-to-pay), this reference
/// goes in as the provider's externalId; MTN's callback (Supabase Edge
/// Function `momo-callback`) writes the outcome to the `momo_payments`
/// table keyed by this reference, and the seller's next Sync pulls
/// confirmations down and marks the receipt paid automatically. Until
/// MTN credentials exist, sellers keep confirming manually in History —
/// the reference is what makes the automatic path possible.
library;

import '../referral/referral.dart';

String momoRequestReference({
  required String businessId,
  required String receiptNo,
}) {
  final tag = referralCodeFor(businessId).substring(3, 7); // 4 chars after CA-
  return '$receiptNo-$tag';
}

/// Recovers the receipt number from a reference built by
/// [momoRequestReference] (used by the callback function, mirrored there).
String receiptNoFromReference(String reference) {
  final i = reference.lastIndexOf('-');
  return i > 0 ? reference.substring(0, i) : reference;
}
