import 'package:flutter_test/flutter_test.dart';
import 'package:ca_receipt/core/catalogue/scan_merge.dart';

void main() {
  group('barcode scan merge (v0.7.2)', () {
    test('repeated scans of the same product add quantities', () {
      final merged = mergeScanned(const [
        ScannedEntry('Milo 400g', 1, 4500),
        ScannedEntry('Milo 400g', 1, 4500),
        ScannedEntry('milo 400g', 1, 4500),
        ScannedEntry('Ideal Milk', 2, 1200),
      ]);
      expect(merged.length, 2);
      expect(merged.first.qty, 3);
      expect(merged.last.qty, 2);
    });
    test('junk entries are dropped, order is first-seen', () {
      final merged = mergeScanned(const [
        ScannedEntry('  ', 1, 100),
        ScannedEntry('Rice', 0, 100),
        ScannedEntry('Rice', 1, 5000),
        ScannedEntry('Oil', 1, 3000),
      ]);
      expect(merged.map((e) => e.name), ['Rice', 'Oil']);
    });
  });
}
