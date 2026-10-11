import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ca_receipt/core/models.dart';
import 'package:ca_receipt/core/receipt_signer.dart';

void main() {
  test('signed receipt verifies offline; tampered receipt fails', () async {
    final signer = await ReceiptSigner.fromSeed(List<int>.filled(32, 7));
    final qr = await signer.signReceipt(Receipt.sample());
    expect(qr.startsWith('CA1.'), isTrue);

    String pad(String s) => s + '=' * ((4 - s.length % 4) % 4);
    final pub = base64Url.decode(pad(await signer.publicKeyBase64Url()));
    final payload = await ReceiptSigner.verify(qr, pub);
    expect(payload, isNotNull);
    expect(payload!['tot'], 22000);
    expect(payload['sn'], 'CA Demo Farms');

    // Tamper at payload level: re-encode a changed payload with the old signature.
    final parts = qr.split('.');
    final decoded = jsonDecode(utf8.decode(base64Url.decode(pad(parts[1])))) as Map<String, dynamic>;
    decoded['tot'] = 1;
    final forgedPayload = base64Url.encode(utf8.encode(jsonEncode(decoded))).replaceAll('=', '');
    final forged = 'CA1.$forgedPayload.${parts[2]}';
    expect(await ReceiptSigner.verify(forged, pub), isNull);
  });
}
