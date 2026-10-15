import 'package:flutter_test/flutter_test.dart';
import 'package:ca_receipt/core/ocr/receipt_parser.dart';

void main() {
  group('parser v2 — extraction recovery (Dennis device report)', () {
    test('whole-cedi receipt: every item AND the total are listed', () {
      final r = ReceiptParser.parse('''
AMA SERWAA PROVISIONS
Receipt No 1042
Tomatoes 20
Onions 15
Rice 5kg 45
TOTAL 80
Cash
''');
      expect(r.items.map((i) => i.name), ['Tomatoes', 'Onions', 'Rice 5kg']);
      expect(r.itemsTotalPesewas, 8000);
      expect(r.totalPesewas, 8000);
      expect(r.totalsMatch, isTrue);
      expect(r.items.any((i) => i.name.contains('Receipt')), isFalse,
          reason: 'the receipt number must never become an item');
    });

    test('whole-cedi qty x unit x amount pattern', () {
      final r = ReceiptParser.parse('Eggs 12 30 360');
      expect(r.items.single.qty, 12);
      expect(r.items.single.unitPricePesewas, 3000);
      expect(r.items.single.amountPesewas, 36000);
    });

    test('two-line wrapped items are merged (name line + price line)', () {
      final r = ReceiptParser.parse('''
SHOPRITE MARKET
Fresh Tomatoes
15.00
Onions
7.50
TOTAL 22.50
''');
      expect(r.items.length, 2);
      expect(r.items.first.name, 'Fresh Tomatoes');
      expect(r.items.first.amountPesewas, 1500);
      expect(r.totalsMatch, isTrue);
    });

    test('OCR digit confusions in prices are repaired', () {
      final r = ReceiptParser.parse('''
Cooking Oil 1O.00
Bread l2.50
TOTAL 22.50
''');
      expect(r.items.length, 2);
      expect(r.items[0].amountPesewas, 1000);
      expect(r.items[1].amountPesewas, 1250);
      expect(r.items[0].name, 'Cooking Oil',
          reason: 'the word Oil itself must not be mangled');
    });

    test('four-digit price without commas is not corrupted', () {
      final r = ReceiptParser.parse('Generator 1200.50');
      expect(r.items.single.amountPesewas, 120050);
    });

    test('one-decimal price is understood', () {
      final r = ReceiptParser.parse('Bread 5.5');
      expect(r.items.single.amountPesewas, 550);
    });
  });
}
