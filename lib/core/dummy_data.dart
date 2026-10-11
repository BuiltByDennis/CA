import 'models.dart';

/// Phase 0 dummy data so every dashboard + history screen is navigable/reviewable.
/// Replaced by Drift local DB in Phase 1.
final dummyHistory = <({String buyer, List<Receipt> receipts})>[
  (buyer: 'Ama Serwaa', receipts: [Receipt.sample()]),
  (buyer: 'Mensah Trading Ltd', receipts: [Receipt.sample()]),
  (buyer: 'Walk-in buyer', receipts: [Receipt.sample()]),
];
