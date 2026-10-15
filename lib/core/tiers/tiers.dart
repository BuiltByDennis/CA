import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Paid tiers (Phase 7). The pilot rule stands: a sale must never need
/// internet or a subscription — so tiers NEVER gate issuing or scanning.
/// Pro unlocks scale features only: more branches, more staff.
enum PlanTier { free, pro }

class PlanLimits {
  static int maxBranches(PlanTier t) => t == PlanTier.pro ? 1 << 30 : 2; // Free: main shop + 1 branch
  static int maxStaff(PlanTier t) => t == PlanTier.pro ? 1 << 30 : 3;
  static bool canAddBranch(PlanTier t, int currentCount) =>
      currentCount < maxBranches(t);
  static bool canAddStaff(PlanTier t, int currentActiveCount) =>
      currentActiveCount < maxStaff(t);
}

/// The device's cached tier. Written by SyncService from the server-side
/// subscriptions table (the source of truth); defaults to Free offline.
class TierStore {
  static const _key = 'plan_tier';
  static const _storage = FlutterSecureStorage();

  static Future<PlanTier> current() async =>
      (await _storage.read(key: _key)) == 'pro' ? PlanTier.pro : PlanTier.free;

  static Future<void> set(PlanTier t) =>
      _storage.write(key: _key, value: t.name);
}
