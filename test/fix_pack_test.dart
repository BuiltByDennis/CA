import 'package:flutter_test/flutter_test.dart';
import 'package:ca_receipt/core/ocr/ocr_service.dart';
import 'package:ca_receipt/core/design/receipt_design.dart';

void main() {
  group('fix pack: OCR best-pass scoring', () {
    test('more alphanumeric content scores higher', () {
      final garbled = OcrService.scoreText('T0TAL  GHS  45.OO  x  ');
      final clean = OcrService.scoreText('TOTAL GHS 45.00 thank you');
      expect(clean, greaterThan(garbled));
    });
    test('empty text scores zero', () {
      expect(OcrService.scoreText(''), 0);
      expect(OcrService.scoreText('   \n  '), 0);
    });
  });

  group('fix pack: receipt design logo', () {
    test('logo path survives the JSON round-trip', () {
      const d = ReceiptDesign(footerNote: 'Medaaase', logoPath: '/data/logo.png');
      final back = ReceiptDesign.fromJson(d.toJson());
      expect(back.logoPath, '/data/logo.png');
      expect(back.footerNote, 'Medaaase');
    });
    test('designs saved before logos existed still load', () {
      final back = ReceiptDesign.fromJson({'foot': 'x', 'tax': true, 'pay': 'Cash', 'style': 1});
      expect(back.logoPath, isNull);
    });
  });
}
