import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import '../db/app_db.dart';
import '../design/receipt_design.dart';
import '../receipt_signer.dart';
import '../seller_key_service.dart';
import '../services.dart';
import '../supabase_config.dart';
import '../sync/sync_service.dart';
import 'key_wrap.dart';
import 'restore_logic.dart';

/// Cross-device restore (Phase 8): after a cloud sign-in, rebuild this
/// phone from the server — profile, business + verification, receipt
/// history (decoded back from the signed backups), My Items, receipt
/// design, branches, staff (PIN hashes, so their PINs still work), and
/// the seller signing key (unwrapped with the account password).
/// Everything merges: existing local rows are never overwritten.
class RestoreReport {
  int receipts = 0;
  int catalogueItems = 0;
  int branches = 0;
  int staff = 0;
  bool businessFound = false;
  bool keyRestored = false;
  bool keyFailed = false;
  String? error;

  String get summary {
    final parts = <String>[
      if (receipts > 0) '$receipts receipt(s)',
      if (catalogueItems > 0) '$catalogueItems item(s)',
      if (branches > 0) '$branches branch(es)',
      if (staff > 0) '$staff staff',
      if (keyRestored) 'seller key',
    ];
    return parts.isEmpty ? 'nothing new to restore' : parts.join(', ');
  }
}

class RestoreService {
  static Future<RestoreReport> restore({required String password}) async {
    final report = RestoreReport();
    final client = SupabaseConfig.clientOrNull;
    if (client == null) {
      report.error = 'Supabase is not configured on this build.';
      return report;
    }
    final user = client.auth.currentUser;
    if (user == null) {
      report.error = 'Not signed in.';
      return report;
    }
    final uid = user.id;
    final db = AppServices.db;
    try {
      await SyncService.refreshRegistry();

      final profRows = await client.from('profiles').select().eq('id', uid);
      final prof = profRows.isEmpty ? null : profRows.first;
      final name = (prof?['display_name'] as String?) ?? 'CA User';
      final phone = (prof?['phone'] as String?) ?? '';

      final bizRows = await client.from('businesses').select().eq('owner_id', uid);
      final biz = bizRows.isEmpty ? null : bizRows.first;
      final serverCaId = biz?['ca_business_id'] as String?;
      final derivedId = phone.isNotEmpty
          ? restoredBusinessId(serverCaBusinessId: serverCaId, phone: phone)
          : serverCaId;

      final existing = await db.getProfile();
      final String? myBusinessId = existing?.businessId ?? derivedId;
      if (existing == null) {
        final sellerMode = biz?['seller_mode'] as String?;
        final mode = biz == null
            ? 'buyer'
            : (sellerMode == 'integrated' ? 'sellerIntegrated' : 'sellerManual');
        await db.saveProfile(ProfilesCompanion.insert(
          id: 'me',
          name: name,
          phone: phone,
          mode: mode,
          businessName: Value(biz == null
              ? null
              : (biz['trading_name'] as String? ?? biz['legal_name'] as String?)),
          businessId: Value(mode == 'buyer' ? null : myBusinessId),
        ));
      }

      if (biz != null && await db.getVerification() == null) {
        await db.saveVerification(BusinessVerificationCompanion.insert(
          id: 'me',
          legalName: (biz['legal_name'] as String?) ?? '',
          tradingName: (biz['trading_name'] as String?) ?? '',
          businessType: (biz['business_type'] as String?) ?? 'informal',
          orcNumber: Value(biz['orc_number'] as String?),
          tin: Value(biz['tin'] as String?),
          vatRegistered: Value(biz['vat_registered'] == true),
          address: Value(biz['address'] as String?),
          category: Value(biz['category'] as String?),
          contactPhone: Value(biz['contact_phone'] as String?),
          contactEmail: Value(biz['contact_email'] as String?),
          status: Value((biz['verification_status'] as String?) ?? 'unverified'),
          note: Value(biz['verification_note'] as String?),
          remoteBusinessId: Value(biz['id'] as String?),
        ));
        report.businessFound = true;
      }

      // Receipt history from the signed backups.
      final rows = await client
          .from('receipts_backup')
          .select('qr_text')
          .eq('backed_up_by', uid)
          .order('issued_at');
      for (final row in rows) {
        final qr = row['qr_text'] as String?;
        if (qr == null) continue;
        final r = restoredReceiptFromQr(qr, myBusinessId: myBusinessId);
        if (r == null) continue;
        if (await db.receiptById(r.id) != null) continue;
        var verified = false;
        final key = await db.sellerKey(r.sellerBusinessId);
        if (key != null) {
          verified = await ReceiptSigner.verify(
                  qr, ReceiptSigner.b64Decode(key.publicKeyB64)) !=
              null;
        }
        await db.saveReceiptRestored(
          ReceiptsCompanion.insert(
            id: r.id,
            receiptNo: r.receiptNo,
            sellerBusinessId: r.sellerBusinessId,
            sellerName: r.sellerName,
            buyerName: Value(r.buyerName),
            totalPesewas: r.totalPesewas,
            paymentMethod: r.paymentMethod,
            issuedAtUnix: r.issuedAtUnix,
            source: r.source,
            qrText: r.qrText,
            direction: r.direction,
            verified: Value(verified),
          ),
          [
            for (final i in r.items)
              ReceiptItemsCompanion.insert(
                  receiptId: r.id,
                  name: i.name,
                  qty: i.qty,
                  unitPricePesewas: i.unitPricePesewas)
          ],
        );
        report.receipts++;
      }

      // My Items.
      final catRows = await client.from('catalogue_backup').select().eq('owner_id', uid);
      final existingCat = {for (final i in await db.catalogueList()) i.id};
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      for (final row in catRows) {
        final id = row['item_id'] as String;
        if (existingCat.contains(id)) continue;
        await db.saveCatalogueItem(CatalogueItemsCompanion.insert(
          id: id,
          name: (row['name'] as String?) ?? 'Item',
          unitPricePesewas: Value(((row['unit_price_pesewas'] as num?) ?? 0).toInt()),
          barcode: Value(row['barcode'] as String?),
          createdAtUnix: now,
        ));
        report.catalogueItems++;
      }

      // Settings row: design, branches, staff, seller key.
      final ab = await client
          .from('account_backups')
          .select()
          .eq('owner_id', uid)
          .maybeSingle();
      if (ab != null) {
        final design = ab['design_json'] as String?;
        if (design != null && await DesignStore.loadRaw() == null) {
          await DesignStore.saveRaw(design);
        }
        final branchesJson = ab['branches_json'] as String?;
        if (branchesJson != null) {
          final have = {for (final b in await db.branchList()) b.name.toLowerCase()};
          for (final e in (jsonDecode(branchesJson) as List)) {
            final m = (e as Map).cast<String, dynamic>();
            final bName = (m['name'] as String?) ?? '';
            if (bName.isEmpty || have.contains(bName.toLowerCase())) continue;
            await db.saveBranch(BranchesCompanion.insert(
              id: 'br-${DateTime.now().millisecondsSinceEpoch}-${report.branches}',
              name: bName,
              location: Value(m['location'] as String?),
              createdAtUnix: now,
            ));
            report.branches++;
          }
        }
        final staffJson = ab['staff_json'] as String?;
        if (staffJson != null) {
          final have = {for (final s in await db.staffList()) s.name.toLowerCase()};
          for (final e in (jsonDecode(staffJson) as List)) {
            final m = (e as Map).cast<String, dynamic>();
            final sName = (m['name'] as String?) ?? '';
            if (sName.isEmpty || have.contains(sName.toLowerCase())) continue;
            await db.saveStaff(StaffMembersCompanion.insert(
              id: 'staff-${DateTime.now().millisecondsSinceEpoch}-${report.staff}',
              name: sName,
              phone: Value(m['phone'] as String?),
              role: (m['role'] as String?) ?? 'cashier',
              pinSalt: (m['pinSalt'] as String?) ?? '',
              pinHash: (m['pinHash'] as String?) ?? '',
              active: Value(m['active'] == true),
              createdAtUnix: ((m['createdAtUnix'] as num?) ?? now).toInt(),
            ));
            report.staff++;
          }
        }
        final salt = ab['key_salt'] as String?;
        final nonce = ab['key_nonce'] as String?;
        final cipher = ab['key_ciphertext'] as String?;
        if (salt != null && nonce != null && cipher != null && myBusinessId != null) {
          final seed = await unwrapSeed(WrappedKey(salt, nonce, cipher), password);
          if (seed != null) {
            await SellerKeyService.importSeed(myBusinessId, seed);
            report.keyRestored = true;
          } else {
            report.keyFailed = true;
          }
        }
      }
      return report;
    } catch (e) {
      report.error = 'Restore did not finish (are you online?). $e';
      return report;
    }
  }
}
