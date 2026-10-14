import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'models.dart';

/// Share a receipt through the system share sheet (WhatsApp, etc.) —
/// Phase 5 "backup to WhatsApp": the QR as a PNG image + a text summary.
/// The buyer can screenshot/save it and scan it into CA later; the signed
/// payload is also in the caption path (the QR itself carries it).
Future<void> shareReceiptQr(BuildContext context,
    {required Receipt receipt, required String qr}) async {
  final caption = '${receipt.sellerName} — Receipt ${receipt.receiptNo}\n'
      'Total: ${formatGhs(receipt.totalPesewas)} · ${receipt.paymentMethod}\n'
      'Scan this QR with the CA app to save and verify your receipt.';
  try {
    final painter = QrPainter(data: qr, version: QrVersions.auto, gapless: true);
    final data = await painter.toImageData(640, format: ui.ImageByteFormat.png);
    if (data == null) throw Exception('qr render failed');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/ca-receipt-${receipt.receiptNo}.png');
    await file.writeAsBytes(data.buffer.asUint8List());
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: caption));
  } catch (_) {
    await SharePlus.instance.share(ShareParams(text: '$caption\n\nReceipt code:\n$qr'));
  }
}
