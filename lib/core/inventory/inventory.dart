/// Inventory-lite (Phase 7): stock awareness derived from what CA already
/// knows — the items on issued receipts — plus the seller's own physical
/// counts. Pure logic, unit-tested.
///
/// Model: a count is a physical stock-take at a moment in time. Estimated
/// on-hand now = last count − units sold since that count. Items never
/// counted show sales only (on-hand unknown) — CA never invents stock.
class InventoryRow {
  const InventoryRow({
    required this.name,
    required this.totalSold,
    required this.lastCount,
    required this.soldSinceCount,
  });
  final String name;
  final int totalSold;
  final int? lastCount;
  final int soldSinceCount;

  int? get estimatedOnHand =>
      lastCount == null ? null : lastCount! - soldSinceCount;
  bool get lowStock {
    final est = estimatedOnHand;
    return est != null && est <= lowStockThreshold;
  }

  static const lowStockThreshold = 5;
}

class SoldLine {
  const SoldLine(this.name, this.qty, this.issuedAtUnix);
  final String name;
  final int qty;
  final int issuedAtUnix;
}

class StockCount {
  const StockCount(this.qty, this.atUnix);
  final int qty;
  final int atUnix;
}

List<InventoryRow> computeInventory({
  required List<SoldLine> soldLines,
  required Map<String, StockCount> counts,
}) {
  final total = <String, int>{};
  final since = <String, int>{};
  for (final l in soldLines) {
    total[l.name] = (total[l.name] ?? 0) + l.qty;
    final c = counts[l.name];
    if (c != null && l.issuedAtUnix >= c.atUnix) {
      since[l.name] = (since[l.name] ?? 0) + l.qty;
    }
  }
  final names = {...total.keys, ...counts.keys}.toList()..sort();
  return [
    for (final n in names)
      InventoryRow(
        name: n,
        totalSold: total[n] ?? 0,
        lastCount: counts[n]?.qty,
        soldSinceCount: since[n] ?? 0,
      ),
  ];
}
