import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../db/app_db.dart';
import '../receipt_signer.dart';
import '../seller_key_service.dart';
import '../services.dart';
import '../supabase_config.dart';
import 'sync_payloads.dart';

/// Supabase sync (Phase 3) — thin network layer over the pure builders in
/// sync_payloads.dart. Everything here is best-effort: offline or unconfigured
/// NEVER blocks the app, and the local outbox keeps everything not yet pushed.
///
/// Identity model (Phase 3): the app links to Supabase with an *anonymous*
/// sign-in (must be enabled in the project — see docs/CONNECT_SUPABASE.md).
/// The local PIN account stays the device identity; phone-OTP account
/// linking (for cross-device history restore) is a later phase.
class SyncReport {
  SyncReport(this.configured, this.message);
  final bool configured;
  String message;
  int receiptsPushed = 0;
  int docsUploaded = 0;
  int registryKeys = 0;
  String? businessStatus;
}

class SyncService {
  static SupabaseClient? get _client => SupabaseConfig.clientOrNull;

  /// Pull the verified-seller registry into the local key cache.
  /// Public-read (RLS) — works without sign-in. Returns keys cached, or -1
  /// when unavailable (offline / not configured). Safe to call any time.
  static Future<int> refreshRegistry() async {
    final client = _client;
    if (client == null) return -1;
    try {
      final businesses = await client
          .from('businesses')
          .select('id, trading_name, verification_status, ca_business_id')
          .eq('verification_status', 'verified');
      final keys = await client
          .from('seller_public_keys')
          .select('business_id, public_key_b64url, status')
          .eq('status', 'active');
      final filtered = filterVerifiedKeys(
        businesses.cast<Map<String, dynamic>>(),
        keys.cast<Map<String, dynamic>>(),
      );
      for (final k in filtered) {
        await AppServices.db.upsertSellerKey(SellerKeysCompanion.insert(
          businessId: k.businessId,
          businessName: k.businessName,
          publicKeyB64: k.publicKeyB64,
          addedAtUnix: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          source: const Value('registry'),
          verifiedBusiness: const Value(true),
        ));
      }
      return filtered.length;
    } catch (_) {
      return -1;
    }
  }

  static Future<SyncReport> syncNow() async {
    final client = _client;
    if (client == null) {
      return SyncReport(false,
          'Supabase is not configured on this build. Add dart_defines.json (see docs/CONNECT_SUPABASE.md). Nothing was lost — everything stays on this phone.');
    }
    final report = SyncReport(true, 'Sync complete.');
    try {
      // 1) Identity: anonymous link.
      var user = client.auth.currentUser;
      if (user == null) {
        final res = await client.auth.signInAnonymously();
        user = res.user;
      }
      if (user == null) {
        report.message =
            'Could not sign in to Supabase. If anonymous sign-in is disabled in your project, enable it (Authentication → Sign In / Providers → Anonymous).';
        return report;
      }
      final uid = user.id;
      final profile = await AppServices.db.getProfile();
      await client.from('profiles').upsert({
        'id': uid,
        'display_name': profile?.name ?? 'CA User',
        'phone': profile?.phone,
      });

      // 2) Verification: submit/update business + upload docs, pull status.
      var remoteBizId = await _syncVerification(client, uid, report);

      // 3) Receipt backups from the outbox.
      final rows = await AppServices.db.outboxRows();
      for (final row in rows) {
        if (row.kind != 'receipt_backup') continue;
        final payload = ReceiptSigner.decodePayloadUnverified(row.payload);
        final isOwnBusiness =
            payload != null && payload['sid'] == profile?.businessId;
        final backupRow = buildReceiptBackupRow(
          row.payload,
          backedUpBy: uid,
          sellerBusinessUuid: isOwnBusiness ? remoteBizId : null,
        );
        if (backupRow == null) {
          await AppServices.db.deleteOutboxRow(row.id); // poison row — drop
          continue;
        }
        try {
          await client.from('receipts_backup').upsert(backupRow);
          await AppServices.db.deleteOutboxRow(row.id);
          report.receiptsPushed++;
        } catch (_) {
          await AppServices.db.bumpOutboxAttempts(row.id, row.attempts + 1);
          break; // probably offline — stop, keep the rest queued
        }
      }

      // 4) Registry for this device (as a buyer).
      final n = await refreshRegistry();
      if (n >= 0) report.registryKeys = n;
      report.businessStatus =
          (await AppServices.db.getVerification())?.status;
      report.message =
          'Sync complete: ${report.receiptsPushed} receipt(s) backed up, '
          '${report.docsUploaded} document(s) uploaded, '
          '${report.registryKeys} verified seller(s) cached.';
      return report;
    } catch (e) {
      report.message =
          'Sync did not finish (are you online?). Everything is still safe on this phone and queued. Details: $e';
      return report;
    }
  }

  static Future<String?> _syncVerification(
      SupabaseClient client, String uid, SyncReport report) async {
    final db = AppServices.db;
    final ver = await db.getVerification();
    if (ver == null) return null;
    final profile = await db.getProfile();
    var remoteBizId = ver.remoteBusinessId;

    // Submit (or resubmit) when not currently verified.
    if (ver.status != 'verified') {
      final row = buildBusinessRow(
        ownerProfileId: uid,
        existingId: remoteBizId,
        caBusinessId: profile?.businessId,
        legalName: ver.legalName,
        tradingName: ver.tradingName,
        businessType: ver.businessType,
        sellerMode: profile?.mode == 'sellerIntegrated' ? 'integrated' : 'manual',
        orcNumber: ver.orcNumber,
        tin: ver.tin,
        vatRegistered: ver.vatRegistered,
        address: ver.address,
        category: ver.category,
        contactPhone: ver.contactPhone,
        contactEmail: ver.contactEmail,
      );
      final saved =
          await client.from('businesses').upsert(row).select('id').single();
      remoteBizId = saved['id'] as String;
      await db.setVerificationStatus('pending', remoteBusinessId: remoteBizId);

      // Upload pending documents.
      for (final doc in await db.verificationDocsList()) {
        if (doc.uploaded) continue;
        final file = File(doc.localPath);
        if (!await file.exists()) continue;
        final bytes = await file.readAsBytes();
        final remotePath = '$remoteBizId/${doc.docType}-${doc.id}.jpg';
        await client.storage
            .from('verification-docs')
            .uploadBinary(remotePath, bytes,
                fileOptions: const FileOptions(upsert: true));
        await client.from('verification_documents').insert({
          'business_id': remoteBizId,
          'doc_type': doc.docType,
          'storage_path': remotePath,
        });
        await db.markDocUploaded(doc.id, remotePath);
        report.docsUploaded++;
      }
    }

    // Pull authoritative status.
    if (remoteBizId != null) {
      final rows = await client
          .from('businesses')
          .select('verification_status, verification_note')
          .eq('id', remoteBizId);
      if (rows.isNotEmpty) {
        final status = rows.first['verification_status'] as String;
        await db.setVerificationStatus(status,
            note: rows.first['verification_note'] as String?,
            remoteBusinessId: remoteBizId);
        // Publish our public key once verified, so buyers can cache it.
        if (status == 'verified' && profile?.businessId != null) {
          final signer = await SellerKeyService.signerFor(profile!.businessId!);
          final pub = await signer.publicKeyBase64Url();
          final existing = await client
              .from('seller_public_keys')
              .select('id')
              .eq('business_id', remoteBizId)
              .eq('public_key_b64url', pub)
              .eq('status', 'active');
          if (existing.isEmpty) {
            await client.from('seller_public_keys').insert({
              'business_id': remoteBizId,
              'public_key_b64url': pub,
              'status': 'active',
            });
          }
        }
      }
    }
    return remoteBizId;
  }
}
