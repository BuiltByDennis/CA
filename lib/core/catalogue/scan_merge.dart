/// Merging barcode-scan results into receipt rows (v0.7.2) — pure logic.
/// Scanned entries merge by name (case-insensitive): quantities add up,
/// the scanned price wins for its own entries.
class ScannedEntry {
  const ScannedEntry(this.name, this.qty, this.unitPricePesewas);
  final String name;
  final int qty;
  final int unitPricePesewas;
}

List<ScannedEntry> mergeScanned(Iterable<ScannedEntry> entries) {
  final byName = <String, ScannedEntry>{};
  final order = <String>[];
  for (final e in entries) {
    final key = e.name.trim().toLowerCase();
    if (key.isEmpty || e.qty <= 0) continue;
    final prev = byName[key];
    if (prev == null) {
      byName[key] = e;
      order.add(key);
    } else {
      byName[key] = ScannedEntry(prev.name, prev.qty + e.qty, prev.unitPricePesewas);
    }
  }
  return [for (final k in order) byName[k]!];
}
