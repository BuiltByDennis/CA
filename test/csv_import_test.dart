import 'package:flutter_test/flutter_test.dart';
import 'package:ca_receipt/core/catalogue/csv_import.dart';

void main() {
  group('bulk price-list import (v0.7.3)', () {
    test('plain template-format file parses fully', () {
      final a = analyzeImport(templateCsv);
      expect(a.rows.length, 3);
      expect(a.rows.first.name, 'Milo 400g');
      expect(a.rows.first.pricePesewas, 4500);
      expect(a.rows.first.barcode, '6030000123456');
      expect(a.rows.last.barcode, isNull);
    });

    test('messy supermarket export: semicolons, renamed headers, GH₵ prices, quoted commas', () {
      final a = analyzeImport('Product Description;Selling Price;SKU\r\n'
          '"Rice, Jasmine 5kg";GH₵1,250.50;8801234567890\r\n'
          'Cooking Oil 5L;320;12345678\r\n');
      expect(a.rows.length, 2);
      expect(a.rows.first.name, 'Rice, Jasmine 5kg');
      expect(a.rows.first.pricePesewas, 125050);
      expect(a.rows.first.barcode, '8801234567890');
      expect(a.priceHeader, 'Selling Price');
      expect(a.barcodeHeader, 'SKU');
    });

    test('bad rows are counted, not silently swallowed', () {
      final a = analyzeImport('name,price,barcode\n'
          ',10.00,111\n'
          'Bread,not-a-price,222\n'
          'Eggs,8.00,\n');
      expect(a.rows.length, 1);
      expect(a.skippedNoName, 1);
      expect(a.skippedBadPrice, 1);
    });

    test('headerless file falls back to name,price,barcode order', () {
      final a = analyzeImport('Sugar 1kg,18.00,555\nSalt,4.50,\n');
      expect(a.rows.length, 2);
      expect(a.rows.first.pricePesewas, 1800);
    });

    test('re-import refreshes prices instead of duplicating', () {
      final plan = planImport(
        [
          (id: 'a', name: 'Milo 400g', barcode: '111'),
          (id: 'b', name: 'Sugar 1kg', barcode: null),
        ],
        const [
          ImportRow('Milo 400g', 4800, '111'), // by barcode → update
          ImportRow('sugar 1kg', 1900, null), // by name → update
          ImportRow('New Soap', 650, '999'), // insert
        ],
      );
      expect(plan.inserts.length, 1);
      expect(plan.updates.map((u) => u.id), ['a', 'b']);
      expect(plan.updates.first.row.pricePesewas, 4800);
    });

    test('export round-trips through the importer', () {
      final csv = catalogueToCsv([
        (name: 'Rice, Jasmine 5kg', pricePesewas: 125050, barcode: '8801'),
        (name: 'Salt', pricePesewas: 450, barcode: null),
      ]);
      final a = analyzeImport(csv);
      expect(a.rows.length, 2);
      expect(a.rows.first.name, 'Rice, Jasmine 5kg');
      expect(a.rows.first.pricePesewas, 125050);
    });
  });
}
