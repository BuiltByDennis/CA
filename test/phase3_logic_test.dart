import 'package:flutter_test/flutter_test.dart';
import 'package:ca_receipt/core/models.dart';
import 'package:ca_receipt/core/receipt_signer.dart';
import 'package:ca_receipt/core/sync/sync_payloads.dart';
import 'package:ca_receipt/core/verification/verification_logic.dart';

void main() {
  group('verification validation', () {
    test('sole proprietor needs Ghana Card + card photo', () {
      const f = VerificationForm(
        legalName: 'Ama Serwaa', tradingName: 'Ama Provisions',
        businessType: 'sole_prop', address: 'Madina Market', category: 'Provisions',
        contactPhone: '0244000000',
      );
      final errors = validateVerification(f);
      expect(errors.any((e) => e.contains('Ghana Card')), isTrue);
    });

    test('complete sole-proprietor submission passes', () {
      const f = VerificationForm(
        legalName: 'Ama Serwaa', tradingName: 'Ama Provisions',
        businessType: 'sole_prop', address: 'Madina Market', category: 'Provisions',
        contactPhone: '0244000000', ghanaCardNo: 'GHA-123456789-0',
        docTypes: ['ghana_card'],
      );
      expect(validateVerification(f), isEmpty);
    });

    test('company needs ORC number + ORC certificate, TIN cert when TIN given', () {
      const f = VerificationForm(
        legalName: 'Demo Ltd', tradingName: 'Demo', businessType: 'limited',
        address: 'Osu', category: 'Electronics', contactPhone: '0302123456',
        tin: 'C0012345678', docTypes: ['ghana_card'],
      );
      final errors = validateVerification(f);
      expect(errors.any((e) => e.contains('ORC registration')), isTrue);
      expect(errors.any((e) => e.contains('ORC certificate')), isTrue);
      expect(errors.any((e) => e.contains('TIN certificate')), isTrue);
    });

    test('status messages are human and distinct', () {
      expect(verificationStatusMessage('verified', null), contains('Verified badge'));
      expect(verificationStatusMessage('rejected', 'Blurry ORC photo'),
          contains('Blurry ORC photo'));
    });
  });

  group('sync payloads', () {
    test('receipt backup row builds from a real signed QR', () async {
      final signer = await ReceiptSigner.fromSeed(List<int>.filled(32, 9));
      final qr = await signer.signReceipt(Receipt.sample());
      final row = buildReceiptBackupRow(qr,
          backedUpBy: 'user-1', sellerBusinessUuid: 'uuid-1');
      expect(row, isNotNull);
      expect(row!['total_pesewas'], 22000);
      expect(row['seller_business_id'], 'uuid-1');
      expect(row['backed_up_by'], 'user-1');
      expect(buildReceiptBackupRow('not-a-qr', backedUpBy: 'u'), isNull);
    });

    test('registry filter keeps ONLY verified businesses with active keys, keyed by CA business ID', () {
      final businesses = [
        {'id': 'uuid-1', 'trading_name': 'Good Ltd', 'verification_status': 'verified', 'ca_business_id': 'biz-111'},
        {'id': 'uuid-2', 'trading_name': 'Pending Ltd', 'verification_status': 'pending', 'ca_business_id': 'biz-222'},
        {'id': 'uuid-3', 'trading_name': 'NoCaId Ltd', 'verification_status': 'verified', 'ca_business_id': null},
      ];
      final keys = [
        {'business_id': 'uuid-1', 'public_key_b64url': 'KEY1', 'status': 'active'},
        {'business_id': 'uuid-2', 'public_key_b64url': 'KEY2', 'status': 'active'},
        {'business_id': 'uuid-1', 'public_key_b64url': 'OLDKEY', 'status': 'superseded'},
        {'business_id': 'uuid-3', 'public_key_b64url': 'KEY3', 'status': 'active'},
      ];
      final out = filterVerifiedKeys(businesses, keys);
      expect(out.length, 1);
      expect(out.single.businessId, 'biz-111');
      expect(out.single.publicKeyB64, 'KEY1');
      expect(out.single.businessName, 'Good Ltd');
    });

    test('key backup export/import round-trips and rejects junk', () {
      final seed = List<int>.generate(32, (i) => i);
      final text = exportKeyBackup(seed);
      expect(text.startsWith('CAKEYBACKUP1.'), isTrue);
      expect(parseKeyBackup(text), seed);
      expect(parseKeyBackup('CAKEYBACKUP1.tooshort'), isNull);
      expect(parseKeyBackup('hello'), isNull);
    });
  });
}
