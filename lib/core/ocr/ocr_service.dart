import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// On-device OCR — Google ML Kit Text Recognition v2 (Latin script model),
/// fully offline; no image ever leaves the phone.
///
/// Fix pack (Phase 6): single-pass OCR on the raw photo missed text on
/// real receipts (faded thermal print, shadows, small fonts). Extraction is
/// now TWO-PASS and keeps the better result:
///  1. the original image as captured, then
///  2. an enhanced copy — upscaled if small, grayscale, contrast-stretched,
///     and slight unsharp — which recovers faded thermal print.
/// "Better" = more alphanumeric characters extracted. The FULL raw text of
/// the winning pass is returned for the parser (and shown in Review).
class OcrService {
  static int scoreText(String t) =>
      t.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').length;

  static Future<String> extractText(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final first = await recognizer.processImage(InputImage.fromFilePath(imagePath));
      var best = first.text;
      try {
        final enhancedPath = await _enhance(imagePath);
        if (enhancedPath != null) {
          final second =
              await recognizer.processImage(InputImage.fromFilePath(enhancedPath));
          if (scoreText(second.text) > scoreText(best)) best = second.text;
        }
      } catch (_) {
        // Enhancement is best-effort — the first pass result stands.
      }
      return best;
    } finally {
      await recognizer.close();
    }
  }

  /// Builds the enhanced copy next to the app temp dir; null if the image
  /// can't be decoded (the caller then relies on pass 1 only).
  static Future<String?> _enhance(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    var decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    // Bake EXIF orientation so sideways photos read upright.
    decoded = img.bakeOrientation(decoded);
    // Upscale small images — ML Kit reads small print much better larger.
    if (decoded.width < 1400) {
      final scale = 1400 / decoded.width;
      decoded = img.copyResize(decoded,
          width: 1400, height: (decoded.height * scale).round(),
          interpolation: img.Interpolation.cubic);
    }
    decoded = img.grayscale(decoded);
    decoded = img.adjustColor(decoded, contrast: 1.25, brightness: 1.02);
    final dir = await getTemporaryDirectory();
    final out = File('${dir.path}/ca_ocr_enhanced.jpg');
    await out.writeAsBytes(img.encodeJpg(decoded, quality: 92));
    return out.path;
  }
}
