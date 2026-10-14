import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/ocr/ocr_service.dart';
import '../../core/ocr/receipt_parser.dart';
import 'review_capture_screen.dart';

const sampleReceiptText = """
MELCOM PLUS - ACCRA MALL
Tel: 0302 123 456
Receipt No: RC-20261011-0451
Date: 11/10/2026 10:24 AM
Rice (5kg) 1 x 185.00 185.00
Tomatoes 1kg 2 45.50 91.00
Chicken (Whole) 120.00
Subtotal 396.00
VAT (15%) 59.40
NHIL (2.5%) 9.90
GETFund (2.5%) 9.90
TOTAL 475.20
Cash 500.00
Change 24.80
""";

/// Capture (Phase 2): photograph your existing system's receipt — on paper,
/// or on your PC screen — or pick a screenshot/image from the gallery.
/// OCR runs on-device; nothing is issued until you approve it in Review.
class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});
  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  bool _busy = false;
  final _picker = ImagePicker();

  Future<void> _capture(ImageSource source) async {
    XFile? file;
    try {
      file = await _picker.pickImage(source: source, imageQuality: 100);
    } catch (_) {
      file = null;
    }
    if (file == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final text = await OcrService.extractText(file.path);
      if (!mounted) return;
      if (text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No text found. Move closer, keep the receipt flat '
                'and straight, avoid glare, and try again.')));
        return;
      }
      final parsed = ReceiptParser.parse(text);
      await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ReviewCaptureScreen(
              imagePath: file!.path, parsed: parsed, rawText: text)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _demo() {
    final parsed = ReceiptParser.parse(sampleReceiptText);
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ReviewCaptureScreen(
            imagePath: null, parsed: parsed, rawText: sampleReceiptText)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Capture Receipt')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const Text('Turn a receipt from your existing system into a CA receipt '
              'your customer can scan. You review and approve everything first — '
              'OCR never issues anything on its own.'),
          const SizedBox(height: 20),
          FilledButton.icon(
            icon: const Icon(Icons.photo_camera, size: 26),
            label: const Text('Take a Photo'),
            onPressed: _busy ? null : () => _capture(ImageSource.camera),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.photo_library),
            label: const Text('Pick from Gallery / Screenshot'),
            onPressed: _busy ? null : () => _capture(ImageSource.gallery),
          ),
          if (_busy) ...[
            const SizedBox(height: 20),
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              CircularProgressIndicator(),
              SizedBox(width: 12),
              Text('Reading receipt on this phone…'),
            ]),
          ],
          const SizedBox(height: 24),
          const Card(child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Photographing a PC screen? Read this first.',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• Best: screenshot the receipt on the PC, send it to this '
                  'phone, and use "Pick from Gallery" — no glare, no distortion.\n'
                  '• If you must photograph the screen: zoom the receipt to fill '
                  'the screen, turn OFF the flash, hold the phone parallel to '
                  'the screen, and avoid bright lights behind you.\n'
                  '• Wavy patterns (moiré) and glare are the top cause of wrong '
                  'amounts — the review screen flags anything that does not add up.'),
            ]),
          )),
          const SizedBox(height: 12),
          TextButton.icon(
            icon: const Icon(Icons.science_outlined),
            label: const Text('No receipt handy? Try with a sample receipt (demo)'),
            onPressed: _busy ? null : _demo,
          ),
        ]),
      );
}
