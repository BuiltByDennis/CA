import '../models.dart';
import '../receipt_signer.dart';

/// Pure restore logic (Phase 8): turns backed-up QR texts into local
/// receipt records. Direction: receipts whose seller is MY business are
/// 'issued'; everything else I backed up was a receipt I scanned/saved
/// as a buyer ('saved'). Duplicates (already on this phone) are skipped
/// by the caller via receiptById.
class RestoredReceipt {
  const RestoredReceipt({
    required this.id,
    required this.receiptNo,
    required this.sellerBusinessId,
    required this.sellerName,
    required this.buyerName,
    required this.totalPesewas,
    required this.currency,
    required this.paymentMethod,
    required this.issuedAtUnix,
    required this.source,
    required this.direction,
    required this.qrText,
    required this.items,
  });
  final String id;
  final String receiptNo;
  final String sellerBusinessId;
  final String sellerName;
  final String? buyerName;
  final int totalPesewas;
  final String currency;
  final String paymentMethod;
  final int issuedAtUnix;
  final String source; // manual | captured | scanned
  final String direction; // issued | saved
  final String qrText;
  final List<ReceiptItem> items;
}

RestoredReceipt? restoredReceiptFromQr(String qrText, {required String? myBusinessId}) {
  final payload = ReceiptSigner.decodePayloadUnverified(qrText);
  if (payload == null) return null;
  final Receipt r;
  try {
    r = Receipt.fromPayload(payload);
  } catch (_) {
    return null;
  }
  final mine = myBusinessId != null && r.sellerBusinessId == myBusinessId;
  return RestoredReceipt(
    id: r.id,
    receiptNo: r.receiptNo,
    sellerBusinessId: r.sellerBusinessId,
    sellerName: r.sellerName,
    buyerName: r.buyerName,
    totalPesewas: r.totalPesewas,
    currency: r.currency,
    paymentMethod: r.paymentMethod,
    issuedAtUnix: r.issuedAt.millisecondsSinceEpoch ~/ 1000,
    source: mine ? r.source : 'scanned',
    direction: mine ? 'issued' : 'saved',
    qrText: qrText,
    items: r.items,
  );
}

/// Change fingerprint for the local catalogue — sync only re-uploads
/// the price list when it actually changed.
String catalogueFingerprint(
    List<({String id, String name, int price, String? barcode})> items) {
  final sorted = [...items]..sort((a, b) => a.id.compareTo(b.id));
  var h = items.length * 2654435761 % 4294967296;
  for (final i in sorted) {
    h = (h * 31 + i.name.hashCode + i.price * 7 + (i.barcode?.hashCode ?? 0)) % 4294967296;
  }
  return h.toString();
}

/// The business id a restored account should use: the server's
/// businesses row wins; otherwise re-derive from the phone exactly the
/// way signup does ('biz-' plus the phone digits), so pre-verification sellers
/// land on the same id their old phone used.
String restoredBusinessId({String? serverCaBusinessId, required String phone}) {
  if (serverCaBusinessId != null && serverCaBusinessId.isNotEmpty) {
    return serverCaBusinessId;
  }
  return 'biz-${phone.replaceAll(RegExp(r'\D'), '')}';
}
