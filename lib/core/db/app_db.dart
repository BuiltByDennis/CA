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
  TextColumn get originalReceiptNo => text().nullable()(); // for captured receipts: the POS system's own number
  TextColumn get cashierName => text().nullable()(); // staff member who issued it (Phase 4, local stamp)
  TextColumn get paymentStatus => text().nullable()(); // Phase 5: 'pending' | 'paid' (MoMo confirmation flow); null = not tracked
  TextColumn get paymentReference => text().nullable()(); // Phase 5: MoMo transaction ID entered on confirmation
  TextColumn get buyerPhone => text().nullable()(); // Phase 5: buyer MoMo number (local only, not in payload)
  TextColumn get branchName => text().nullable()(); // Phase 7: branch that issued it (local stamp, like cashierName)
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
  TextColumn get source => text().withDefault(const Constant('pairing'))(); // pairing | registry
  BoolColumn get verifiedBusiness => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {businessId};
}

/// Business verification record (Phase 3) — one row (id 'me') per seller.
/// ghanaCardNo is stored ONLY on this device and is never synced.
@DataClassName('BusinessVerificationRow')
class BusinessVerification extends Table {
  TextColumn get id => text()();
  TextColumn get legalName => text()();
  TextColumn get tradingName => text()();
  TextColumn get businessType => text()(); // sole_prop | limited | informal | company
  TextColumn get orcNumber => text().nullable()();
  TextColumn get tin => text().nullable()();
  BoolColumn get vatRegistered => boolean().withDefault(const Constant(false))();
  TextColumn get address => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get contactPhone => text().nullable()();
  TextColumn get contactEmail => text().nullable()();
  TextColumn get ghanaCardNo => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('unverified'))();
  TextColumn get note => text().nullable()();
  IntColumn get submittedAtUnix => integer().nullable()();
  TextColumn get remoteBusinessId => text().nullable()();
  TextColumn get referredBy => text().nullable()(); // Phase 7: referral code of the seller who invited this business
  @override
  Set<Column> get primaryKey => {id};
}

/// Business branches (Phase 7, multi-branch). The branch a sale belongs to
/// is stamped onto the receipt locally (branchName) — the frozen QR payload
/// v1 is unchanged.
@DataClassName('BranchRow')
class Branches extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get location => text().nullable()();
  IntColumn get createdAtUnix => integer()();
  @override
  Set<Column> get primaryKey => {id};
}

/// Manual stock counts (Phase 7, inventory-lite). One row per item name:
/// what the seller says they have. Sold quantities are computed from
/// issued receipt items, so on-hand = counted - sold-since-count is shown
/// by the inventory logic; this table stores the latest physical count.
@DataClassName('StockCountRow')
class StockCounts extends Table {
  TextColumn get itemName => text()();
  IntColumn get quantityOnHand => integer()();
  IntColumn get updatedAtUnix => integer()();
  @override
  Set<Column> get primaryKey => {itemName};
}

@DataClassName('VerificationDocRow')
class VerificationDocs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get docType => text()(); // orc_certificate | tin_certificate | ghana_card | business_permit | other
  TextColumn get localPath => text()();
  BoolColumn get uploaded => boolean().withDefault(const Constant(false))();
  TextColumn get remotePath => text().nullable()();
}

/// Staff members (Phase 4) — people besides the owner who can work on this
/// device under the business, each with their own PIN. PINs are salted hashes.
@DataClassName('StaffMemberRow')
class StaffMembers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get role => text()(); // manager | cashier | accountant
  TextColumn get pinSalt => text()();
  TextColumn get pinHash => text()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  IntColumn get createdAtUnix => integer()();
  @override
  Set<Column> get primaryKey => {id};
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

@DriftDatabase(tables: [Profiles, Receipts, ReceiptItems, SellerKeys, SyncOutbox, BusinessVerification, VerificationDocs, StaffMembers, Branches, StockCounts])
class AppDb extends _$AppDb {
  AppDb() : super(_open());
  AppDb.forTesting(super.executor);
  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.addColumn(receipts, receipts.originalReceiptNo);
          if (from < 3) {
            await m.createTable(businessVerification);
            await m.createTable(verificationDocs);
            await m.addColumn(sellerKeys, sellerKeys.source);
            await m.addColumn(sellerKeys, sellerKeys.verifiedBusiness);
          }
          if (from < 4) {
            await m.createTable(staffMembers);
            await m.addColumn(receipts, receipts.cashierName);
          }
          if (from < 5) {
            await m.addColumn(receipts, receipts.paymentStatus);
            await m.addColumn(receipts, receipts.paymentReference);
            await m.addColumn(receipts, receipts.buyerPhone);
          }
          if (from < 6) {
            await m.createTable(branches);
            await m.createTable(stockCounts);
            await m.addColumn(receipts, receipts.branchName);
            await m.addColumn(businessVerification, businessVerification.referredBy);
          }
        },
      );

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

  Future<BusinessVerificationRow?> getVerification() async {
    try {
      return await (select(businessVerification)
            ..where((t) => t.id.equals('me')))
          .getSingleOrNull();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveVerification(BusinessVerificationCompanion v) =>
      into(businessVerification).insertOnConflictUpdate(v);

  Future<void> setVerificationStatus(String status, {String? note, String? remoteBusinessId}) async {
    final existing = await getVerification();
    if (existing == null) return;
    await (update(businessVerification)..where((t) => t.id.equals('me'))).write(
      BusinessVerificationCompanion(
        status: Value(status),
        note: Value(note),
        remoteBusinessId: remoteBusinessId == null ? const Value.absent() : Value(remoteBusinessId),
      ),
    );
  }

  Future<int> addVerificationDoc(String docType, String localPath) =>
      into(verificationDocs).insert(VerificationDocsCompanion.insert(
          docType: docType, localPath: localPath));

  Future<List<VerificationDocRow>> verificationDocsList() =>
      select(verificationDocs).get();

  Future<void> markDocUploaded(int id, String remotePath) async {
    await (update(verificationDocs)..where((t) => t.id.equals(id))).write(
      VerificationDocsCompanion(uploaded: const Value(true), remotePath: Value(remotePath)),
    );
  }

  Future<List<OutboxRow>> outboxRows() =>
      (select(syncOutbox)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();

  Future<void> deleteOutboxRow(int id) =>
      (delete(syncOutbox)..where((t) => t.id.equals(id))).go();

  Future<void> bumpOutboxAttempts(int id, int attempts) async {
    await (update(syncOutbox)..where((t) => t.id.equals(id)))
        .write(SyncOutboxCompanion(attempts: Value(attempts)));
  }

  Future<List<StaffMemberRow>> staffList() =>
      (select(staffMembers)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

  Future<void> saveStaff(StaffMembersCompanion s) =>
      into(staffMembers).insertOnConflictUpdate(s);

  Future<void> setStaffActive(String id, bool active) async {
    await (update(staffMembers)..where((t) => t.id.equals(id)))
        .write(StaffMembersCompanion(active: Value(active)));
  }

  Future<void> deleteStaff(String id) =>
      (delete(staffMembers)..where((t) => t.id.equals(id))).go();

  Future<List<ReceiptRow>> issuedReceipts() =>
      (select(receipts)..where((t) => t.direction.equals('issued'))).get();

  Future<List<ReceiptItemRow>> allReceiptItems() => select(receiptItems).get();

  Future<void> setPaymentStatus(String id, String status, {String? reference}) async {
    await (update(receipts)..where((t) => t.id.equals(id))).write(ReceiptsCompanion(
      paymentStatus: Value(status),
      paymentReference: Value(reference),
    ));
  }

  Future<int> receiptCount(String direction) async {
    final rows = await (select(receipts)..where((t) => t.direction.equals(direction))).get();
    return rows.length;
  }

  Future<int> sellerKeyCount() async => (await select(sellerKeys).get()).length;

  /// Complete account deletion (fix pack): erase EVERY local table.
  /// Used by Settings → Delete account after PIN confirmation.
  Future<void> deleteEverything() async {
    await transaction(() async {
      await delete(receiptItems).go();
      await delete(receipts).go();
      await delete(sellerKeys).go();
      await delete(syncOutbox).go();
      await delete(verificationDocs).go();
      await delete(businessVerification).go();
      await delete(staffMembers).go();
      await delete(branches).go();
      await delete(stockCounts).go();
      await delete(profiles).go();
    });
  }

  // --- Phase 7: branches & stock ---

  Future<List<BranchRow>> branchList() =>
      (select(branches)..orderBy([(t) => OrderingTerm.asc(t.createdAtUnix)])).get();

  Future<void> saveBranch(BranchesCompanion b) =>
      into(branches).insertOnConflictUpdate(b);

  Future<void> deleteBranch(String id) =>
      (delete(branches)..where((t) => t.id.equals(id))).go();

  Future<List<StockCountRow>> stockCountList() => select(stockCounts).get();

  Future<void> setStockCount(String itemName, int qty) =>
      into(stockCounts).insertOnConflictUpdate(StockCountsCompanion.insert(
        itemName: itemName,
        quantityOnHand: qty,
        updatedAtUnix: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ));

}
