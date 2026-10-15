import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// On-device OCR — Google ML Kit Text Recognition v2 (Latin script model),
/// fully offline; no image ever leaves the phone.
///
/// Extraction is TWO-PASS and keeps the better result:
///  1. the original image as captured, then
///  2. an enhanced copy — upscaled if small, grayscale, contrast-stretched —
///     which recovers faded thermal print.
/// "Better" = more alphanumeric characters extracted.
///
/// Fix pack 2 (v0.7.1): the raw text is no longer taken as ML Kit returns
/// it. Blocks are re-sorted into true reading order (top-to-bottom,
/// left-to-right within a line band) from their bounding boxes — on
/// tilted or rotated photos the default block order scrambles the items,
/// which broke line-based parsing (wrapped items, totals) even when
/// every word was read correctly.
class OcrService {
  static int scoreText(String t) =>
      t.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').length;

  /// Rebuilds receipt text in reading order from recognised blocks.
  static String orderedText(RecognizedText result) {
    final blocks = [...result.blocks]..sort((a, b) {
        final dy = a.boundingBox.top.compareTo(b.boundingBox.top);
        return dy != 0 ? dy : a.boundingBox.left.compareTo(b.boundingBox.left);
      });
    final out = StringBuffer();
    for (final block in blocks) {
      final lines = [...block.lines]..sort((a, b) {
          final dy = a.boundingBox.top.compareTo(b.boundingBox.top);
          return dy != 0 ? dy : a.boundingBox.left.compareTo(b.boundingBox.left);
        });
      for (final line in lines) {
        out.writeln(line.text);
      }
    }
    return out.toString().trim();
  }

  static Future<String> extractText(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final first = await recognizer.processImage(InputImage.fromFilePath(imagePath));
      var best = orderedText(first);
      try {
        final enhancedPath = await _enhance(imagePath);
        if (enhancedPath != null) {
          final second =
              await recognizer.processImage(InputImage.fromFilePath(enhancedPath));
          final secondText = orderedText(second);
          if (scoreText(secondText) > scoreText(best)) best = secondText;
        }
      } catch (_) {
        // Enhancement is best-effort — the first pass result stands.
      }
      return best;
    } finally {
      await recognizer.close();
    }
  }

  /// Builds the enhanced copy in the app temp dir; null if the image
  /// can't be decoded (the caller then relies on pass 1 only).
  static Future<String?> _enhance(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    var decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    decoded = img.bakeOrientation(decoded);
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
