import 'package:flutter_test/flutter_test.dart';
import 'package:ca_receipt/core/catalogue/catalogue.dart';

void main() {
  group('My Items catalogue seeding (v0.7.1)', () {
    test('empty catalogue gets all starters, incl. Dennis\'s examples', () {
      final pending = pendingStarters([]);
      expect(pending, starterItemNames);
      expect(pending, containsAll(['Tomatoes', 'Onions', 'Rice']));
    });
    test('existing items are not duplicated (case-insensitive)', () {
      final pending = pendingStarters(['tomatoes', 'RICE', 'My Own Product']);
      expect(pending, isNot(contains('Tomatoes')));
      expect(pending, isNot(contains('Rice')));
      expect(pending, contains('Onions'));
    });
    test('full catalogue seeds nothing', () {
      expect(pendingStarters(starterItemNames), isEmpty);
    });
  });
}
