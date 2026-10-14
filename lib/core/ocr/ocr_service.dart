import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// On-device OCR (ML Kit) — offline, no image ever leaves the phone.
class OcrService {
  static Future<String> extractText(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(InputImage.fromFilePath(imagePath));
      return result.text;
    } finally {
      await recognizer.close();
    }
  }
}
