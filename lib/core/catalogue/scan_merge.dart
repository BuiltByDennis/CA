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

/// One receipt line as plain data (name, qty, unit price in pesewas).
class ReceiptLineData {
  const ReceiptLineData(this.name, this.qty, this.unitPricePesewas);
  final String name;
  final int qty;
  final int unitPricePesewas;
}

/// Merges scanned entries into the receipt's current lines (v0.8.2 fix):
/// a line with the same name (case-insensitive) GAINS the scanned
/// quantity — scanning the same product again in a later scan session
/// must always show up as more quantity on the receipt, at the scanned
/// price when the line has no price yet. New products append new lines.
List<ReceiptLineData> mergeIntoReceiptLines(
    List<ReceiptLineData> current, List<ScannedEntry> scanned) {
  final out = [...current];
  for (final e in scanned) {
    if (e.qty <= 0 || e.name.trim().isEmpty) continue;
    final i = out.indexWhere(
        (l) => l.name.trim().toLowerCase() == e.name.trim().toLowerCase());
    if (i >= 0) {
      final l = out[i];
      out[i] = ReceiptLineData(
        l.name,
        l.qty + e.qty,
        l.unitPricePesewas > 0 ? l.unitPricePesewas : e.unitPricePesewas,
      );
    } else {
      out.add(ReceiptLineData(e.name, e.qty, e.unitPricePesewas));
    }
  }
  return out;
}
