import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_db.g.dart';

@DataClassName('ProfileRow')
class Profiles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text()();
  TextColumn get mode => text()(); // UserMode.name
  TextColumn get businessName => text().nullable()();
  TextColumn get businessId => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ReceiptRow')
class Receipts extends Table {
  TextColumn get id => text()();
  TextColumn get receiptNo => text()();
  TextColumn get sellerBusinessId => text()();
  TextColumn get sellerName => text()();
  TextColumn get buyerName => text().nullable()();
  IntColumn get totalPesewas => integer()();
  TextColumn get currency => text().withDefault(const Constant('GHS'))();
  TextColumn get paymentMethod => text()();
  IntColumn get issuedAtUnix => integer()();
  TextColumn get source => text()(); // manual | captured | scanned
  TextColumn get qrText => text()();
  TextColumn get direction => text()(); // issued | saved
  BoolColumn get verified => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ReceiptItemRow')
class ReceiptItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get receiptId => text().references(Receipts, #id)();
  TextColumn get name => text()();
  IntColumn get qty => integer()();
  IntColumn get unitPricePesewas => integer()();
}

@DataClassName('SellerKeyRow')
class SellerKeys extends Table {
  TextColumn get businessId => text()();
  TextColumn get businessName => text()();
  TextColumn get publicKeyB64 => text()();
  IntColumn get addedAtUnix => integer()();
  @override
  Set<Column> get primaryKey => {businessId};
}

/// Offline outbox: everything that must sync to Supabase when online (Phase 3).
@DataClassName('OutboxRow')
class SyncOutbox extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => text()(); // receipt_backup | public_key | verification
  TextColumn get payload => text()();
  IntColumn get createdAtUnix => integer()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
}

@DriftDatabase(tables: [Profiles, Receipts, ReceiptItems, SellerKeys, SyncOutbox])
class AppDb extends _$AppDb {
  AppDb() : super(_open());
  AppDb.forTesting(super.executor);
  @override
  int get schemaVersion => 1;

  static LazyDatabase _open() => LazyDatabase(() async {
        final dir = await getApplicationDocumentsDirectory();
        return NativeDatabase.createInBackground(File(p.join(dir.path, 'ca.sqlite')));
      });

  Future<ProfileRow?> getProfile() async {
    try {
      final rows = await select(profiles).get();
      return rows.isEmpty ? null : rows.first;
    } catch (_) {
      return null; // e.g. storage unavailable in tests — treat as no profile
    }
  }

  Future<void> saveProfile(ProfilesCompanion profile) =>
      into(profiles).insertOnConflictUpdate(profile);

  Future<void> saveReceipt(ReceiptsCompanion receipt, List<ReceiptItemsCompanion> items) async {
    await into(receipts).insertOnConflictUpdate(receipt);
    await batch((b) => b.insertAll(receiptItems, items));
    await into(syncOutbox).insert(SyncOutboxCompanion.insert(
      kind: 'receipt_backup',
      payload: receipt.qrText.value,
      createdAtUnix: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    ));
  }

  Future<ReceiptRow?> receiptById(String id) =>
      (select(receipts)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<List<ReceiptRow>> watchReceipts(String direction) =>
      (select(receipts)
            ..where((t) => t.direction.equals(direction))
            ..orderBy([(t) => OrderingTerm.desc(t.issuedAtUnix)]))
          .watch();

  Future<int> issuedCount() async {
    final rows = await (select(receipts)..where((t) => t.direction.equals('issued'))).get();
    return rows.length;
  }

  Future<void> upsertSellerKey(SellerKeysCompanion key) =>
      into(sellerKeys).insertOnConflictUpdate(key);

  Future<SellerKeyRow?> sellerKey(String businessId) =>
      (select(sellerKeys)..where((t) => t.businessId.equals(businessId))).getSingleOrNull();
}
