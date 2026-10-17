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

  group('merge into receipt lines (Dennis report, v0.8.2)', () {
    test('same item scanned again in a later session bumps the quantity', () {
      final lines = mergeIntoReceiptLines(
        const [ReceiptLineData('Milo 400g', 1, 4500)],
        const [ScannedEntry('Milo 400g', 1, 4500)],
      );
      expect(lines.length, 1);
      expect(lines.single.qty, 2);
      expect(lines.single.unitPricePesewas, 4500);
    });
    test('first scan lands as a new line with name, qty and price', () {
      final lines = mergeIntoReceiptLines(
        const [],
        const [ScannedEntry('Ideal Milk', 3, 1250)],
      );
      expect(lines.single.name, 'Ideal Milk');
      expect(lines.single.qty, 3);
      expect(lines.single.unitPricePesewas, 1250);
    });
    test('matching ignores case; scanned price fills a priceless line', () {
      final lines = mergeIntoReceiptLines(
        const [ReceiptLineData('milo 400g', 1, 0)],
        const [ScannedEntry('Milo 400g', 2, 4500)],
      );
      expect(lines.single.qty, 3);
      expect(lines.single.unitPricePesewas, 4500);
    });
    test('different items append in order', () {
      final lines = mergeIntoReceiptLines(
        const [ReceiptLineData('Rice', 1, 5000)],
        const [ScannedEntry('Oil', 1, 3000), ScannedEntry('Rice', 1, 5000)],
      );
      expect(lines.map((l) => l.name), ['Rice', 'Oil']);
      expect(lines.first.qty, 2);
    });
  });
}
