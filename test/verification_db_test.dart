import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ca_receipt/core/db/app_db.dart';

void main() {
  test('verification record + docs + registry key flags persist (Drift v3)', () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.saveVerification(BusinessVerificationCompanion.insert(
      id: 'me', legalName: 'Ama Serwaa', tradingName: 'Ama Provisions',
      businessType: 'sole_prop', status: const Value('pending'),
    ));
    final v = await db.getVerification();
    expect(v?.status, 'pending');
    await db.setVerificationStatus('verified', note: 'OK');
    expect((await db.getVerification())?.status, 'verified');

    final docId = await db.addVerificationDoc('ghana_card', '/tmp/card.jpg');
    await db.markDocUploaded(docId, 'uuid-1/ghana_card-1.jpg');
    final docs = await db.verificationDocsList();
    expect(docs.single.uploaded, isTrue);
    expect(docs.single.remotePath, contains('ghana_card'));

    await db.upsertSellerKey(SellerKeysCompanion.insert(
      businessId: 'biz-111', businessName: 'Good Ltd', publicKeyB64: 'KEY1',
      addedAtUnix: 1, source: const Value('registry'),
      verifiedBusiness: const Value(true),
    ));
    final key = await db.sellerKey('biz-111');
    expect(key?.source, 'registry');
    expect(key?.verifiedBusiness, isTrue);
  });
}
