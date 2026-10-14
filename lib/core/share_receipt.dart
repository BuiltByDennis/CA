import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'models.dart';

/// Share a receipt through the system share sheet (WhatsApp, etc.):
/// the QR as a PNG image + a text summary.
///
/// Fix pack (Phase 6): the QR was rendered on a TRANSPARENT background, so
/// WhatsApp and gallery apps composited it onto black — a black QR on a
/// black background looked like a blank black image (and could never be
/// scanned back). The QR is now painted onto a solid white card with a
/// quiet zone, exactly like a printed QR.
Future<void> shareReceiptQr(BuildContext context,
    {required Receipt receipt, required String qr}) async {
  final caption = '${receipt.sellerName} — Receipt ${receipt.receiptNo}\n'
      'Total: ${formatGhs(receipt.totalPesewas)} · ${receipt.paymentMethod}\n'
      'Scan this QR with the CA app to save and verify your receipt.';
  try {
    final png = await renderQrPng(qr);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/ca-receipt-${receipt.receiptNo}.png');
    await file.writeAsBytes(png);
    await SharePlus.instance
        .share(ShareParams(files: [XFile(file.path)], text: caption));
  } catch (_) {
    await SharePlus.instance
        .share(ShareParams(text: '$caption\n\nReceipt code:\n$qr'));
  }
}

/// Renders a QR string to PNG bytes on an opaque white background.
Future<List<int>> renderQrPng(String data, {int size = 720}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    Paint()..color = const Color(0xFFFFFFFF),
  );
  final margin = size * 0.06;
  final painter = QrPainter(
    data: data,
    version: QrVersions.auto,
    gapless: false,
    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF000000)),
    dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square, color: Color(0xFF000000)),
  );
  canvas.save();
  canvas.translate(margin, margin);
  painter.paint(canvas, Size(size - margin * 2, size - margin * 2));
  canvas.restore();
  final image = await recorder.endRecording().toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}
