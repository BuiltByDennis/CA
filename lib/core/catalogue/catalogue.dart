import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../db/app_db.dart';
import '../services.dart';

/// Seller item catalogue ('My Items', v0.7.1). Sellers customise the list
/// of things they sell — name + usual price — and New Receipt offers them
/// as one-tap entries. On first use the catalogue is seeded with common
/// Ghana provisions staples (the examples sellers kept asking for:
/// tomatoes, onions, rice…) at price 0 for the seller to price their way.
/// Seeding happens once: deleting everything later does not resurrect them.
const starterItemNames = <String>[
  'Tomatoes', 'Onions', 'Rice', 'Cooking Oil', 'Sugar', 'Salt',
  'Eggs', 'Bread', 'Milk', 'Milo', 'Gari', 'Yam', 'Plantain',
  'Beans', 'Sardines', 'Mackerel', 'Chicken', 'Beef', 'Pepper',
  'Maggi Cubes', 'Spaghetti', 'Biscuits', 'Soft Drink', 'Bottled Water',
];

/// Which starters are missing from [existingNames] (case-insensitive).
List<String> pendingStarters(List<String> existingNames) {
  final have = existingNames.map((e) => e.toLowerCase()).toSet();
  return starterItemNames.where((s) => !have.contains(s.toLowerCase())).toList();
}

class CatalogueService {
  static const _seedKey = 'catalogue_seeded_v1';
  static const _storage = FlutterSecureStorage();

  static Future<void> seedIfFirstUse() async {
    if (await _storage.read(key: _seedKey) != null) return;
    final db = AppServices.db;
    final existing = await db.catalogueList();
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    var i = 0;
    for (final name in pendingStarters(existing.map((e) => e.name).toList())) {
      await db.saveCatalogueItem(CatalogueItemsCompanion.insert(
        id: 'cat-seed-${i++}',
        name: name,
        createdAtUnix: now,
      ));
    }
    await _storage.write(key: _seedKey, value: '1');
  }
}
