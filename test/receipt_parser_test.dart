import 'package:flutter_test/flutter_test.dart';
import 'package:ca_receipt/core/ocr/receipt_parser.dart';

/// Phase 2 parser test set: 10 representative Ghana receipts as OCR text
/// (supermarket, pharmacy, fuel, hardware, restaurant, small shop, electronics
/// with discount, wholesaler, clinic, and one garbled screen-photo capture).
/// Exit bar from the plan: totals + receipt numbers extracted correctly.
void main() {
  group('parser test set', () {
    test('1. supermarket with VAT/NHIL/GETFund', () {
      final r = ReceiptParser.parse('''
MELCOM PLUS - ACCRA MALL
Tel: 0302 123 456
Receipt No: RC-20261011-0451
Date: 11/10/2026 10:24 AM
Rice (5kg) 1 x 185.00 185.00
Tomatoes 1kg 2 45.50 91.00
Chicken (Whole) 120.00
Subtotal 396.00
VAT (15%) 59.40
NHIL (2.5%) 9.90
GETFund (2.5%) 9.90
TOTAL 475.20
Cash 500.00
Change 24.80
Thank you for shopping!
''');
      expect(r.sellerName, contains('MELCOM'));
      expect(r.receiptNo, 'RC-20261011-0451');
      expect(r.totalPesewas, 47520);
      expect(r.taxPesewas, 7920);
      expect(r.items.length, 3);
      expect(r.items[1].qty, 2);
      expect(r.items[1].unitPricePesewas, 4550);
      expect(r.totalsMatch, isTrue);
      expect(r.dateTime?.day, 11);
      expect(r.dateTime?.hour, 10);
    });

    test('2. pharmacy with invoice number and MoMo', () {
      final r = ReceiptParser.parse('''
HEALTHLINE PHARMACY, OSU
INVOICE # INV-88412
2026-10-09 14:05
Paracetamol 500mg (24 tabs) 18.50
Vitamin C 1000mg 2 x 32.00 64.00
Antiseptic Liquid 250ml 27.75
GRAND TOTAL: 110.25
Paid by MoMo
''');
      expect(r.receiptNo, 'INV-88412');
      expect(r.totalPesewas, 11025);
      expect(r.items.length, 3);
      expect(r.paymentMethod, 'MoMo');
      expect(r.totalsMatch, isTrue);
      expect(r.dateTime?.year, 2026);
    });

    test('3. fuel station, qty x unit with litres', () {
      final r = ReceiptParser.parse('''
GOIL FUEL STATION - TEMA MOTORWAY
Receipt No 77341
Date: 09 Oct 2026 08:15
Super XP Litres 25 x 14.85 371.25
TOTAL GHS 371.25
Card Payment
''');
      expect(r.receiptNo, '77341');
      expect(r.totalPesewas, 37125);
      expect(r.items.single.qty, 25);
      expect(r.items.single.unitPricePesewas, 1485);
      expect(r.paymentMethod, 'Card');
      expect(r.totalsMatch, isTrue);
      expect(r.dateTime?.month, 10);
    });

    test('4. hardware with thousands separators', () {
      final r = ReceiptParser.parse('''
OSEI BUILDING MATERIALS
Kumasi - Ahodwo
Bill No: B-2210
Date 12/10/2026
Cement (Bag) 40 x 95.00 3,800.00
Iron Rod 12mm 15 210.00 3,150.00
Binding Wire 85.50
Sub Total 7,035.50
TOTAL 7,035.50
''');
      expect(r.receiptNo, 'B-2210');
      expect(r.totalPesewas, 703550);
      expect(r.subtotalPesewas, 703550);
      expect(r.items.length, 3);
      expect(r.items[0].amountPesewas, 380000);
      expect(r.items[1].qty, 15);
      expect(r.totalsMatch, isTrue);
    });

    test('5. restaurant with order number and service charge', () {
      final r = ReceiptParser.parse('''
THE GOLDEN FORK RESTAURANT
East Legon, Accra
Order # 5523
11-10-2026 19:42
Grilled Tilapia 150.00
Jollof Rice 2 x 65.00 130.00
Fresh Orange Juice 3 x 25.00 75.00
Service Charge 17.75
Total: 372.75
Mobile Money
''');
      expect(r.receiptNo, '5523');
      expect(r.totalPesewas, 37275);
      expect(r.items.length, 4);
      expect(r.paymentMethod, 'MoMo');
      expect(r.totalsMatch, isTrue);
      expect(r.dateTime?.hour, 19);
    });

    test('6. small shop, short receipt number with leading zeros', () {
      final r = ReceiptParser.parse('''
ABENA STORES
Receipt: 009812
Date: 10/10/2026
Sugar 1kg 28.00
Milo Tin 400g 68.50
Bread (Large) 20.00
Total 116.50
Cash
''');
      expect(r.receiptNo, '009812');
      expect(r.totalPesewas, 11650);
      expect(r.items.length, 3);
      expect(r.totalsMatch, isTrue);
    });

    test('7. electronics with discount and VAT', () {
      final r = ReceiptParser.parse('''
CITY ELECTRONICS LTD
Receipt No: CE/2026/0917
Date: 08/10/2026 12:30 PM
USB Cable 2 x 45.00 90.00
Wireless Mouse 150.00
Discount -10.00
Subtotal 230.00
VAT 15% 34.50
TOTAL 264.50
''');
      expect(r.receiptNo, 'CE/2026/0917');
      expect(r.totalPesewas, 26450);
      expect(r.discountPesewas, 1000);
      expect(r.taxPesewas, 3450);
      expect(r.items.length, 2);
      expect(r.computedTotalPesewas, 26450);
      expect(r.totalsMatch, isTrue);
      expect(r.dateTime?.hour, 12);
    });

    test('8. wholesaler, qty column without x', () {
      final r = ReceiptParser.parse('''
YAA ASANTEWAA PROVISIONS
Receipt No: YA-0093
14/10/2026
Onions (Bag) 3 450.00 1,350.00
Palm Oil 25L 2 780.00 1,560.00
TOTAL 2,910.00
MoMo
''');
      expect(r.receiptNo, 'YA-0093');
      expect(r.totalPesewas, 291000);
      expect(r.items[0].qty, 3);
      expect(r.items[1].unitPricePesewas, 78000);
      expect(r.totalsMatch, isTrue);
    });

    test('9. clinic invoice with month name date', () {
      final r = ReceiptParser.parse('''
CITY DIAGNOSTIC LAB
Invoice No: LAB-2026-311
Date: 07 Oct 2026
Full Blood Count 180.00
Malaria Test (RDT) 60.00
Consultation 250.00
Total Amount 490.00
''');
      expect(r.receiptNo, 'LAB-2026-311');
      expect(r.totalPesewas, 49000);
      expect(r.items.length, 3);
      expect(r.dateTime?.day, 7);
      expect(r.totalsMatch, isTrue);
    });

    test('10. garbled screen-photo capture is flagged, not trusted', () {
      final r = ReceiptParser.parse('''
PALACE SHOPPING CENTRE
Receipt No: PL-5501
Date: 13/10/2026 16:20
Dettol Soap 3 x 22.00 66.00
Toothpaste 41.99
Rice | Basmati 50.00
TOTAL 107.99
''');
      expect(r.receiptNo, 'PL-5501');
      expect(r.totalPesewas, 10799);
      expect(r.totalsMatch, isFalse);
      expect(r.warnings, isNotEmpty);
      expect(r.items.any((i) => i.needsCheck), isTrue);
    });
  });

  test('empty OCR text gives a clear warning, no crash', () {
    final r = ReceiptParser.parse('');
    expect(r.items, isEmpty);
    expect(r.warnings, isNotEmpty);
  });
}
