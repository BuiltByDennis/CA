import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

/// Bluetooth thermal printing (Phase 4) — prints a paper QR slip for buyers
/// without a smartphone: business name, receipt no., total, the CA QR, and
/// "scan with CA" so the paper is a bridge into the digital receipt.
///
/// Android (Bluetooth Classic) only in this phase — print_bluetooth_thermal
/// has no iOS support. NOT device-tested yet: it needs a physical printer.

class SlipData {
  const SlipData({
    required this.businessName,
    required this.receiptNo,
    required this.dateText,
    required this.totalText,
    required this.itemLines,
    required this.qrText,
    this.cashierName,
  });
  final String businessName;
  final String receiptNo;
  final String dateText;
  final String totalText;
  final List<String> itemLines;
  final String qrText;
  final String? cashierName;
}

/// Thermal printers encode Latin-1 at best — the cedi sign (₵) and Twi
/// letters (ɛ, ɔ) cannot print. Slip text is transliterated: ₵ → 'GHS',
/// ɛ → e, ɔ → o, anything else unprintable is dropped.
String slipSafe(String s) => s
    .replaceAll('GH₵', 'GHS')
    .replaceAll('₵', 'GHS')
    .replaceAll('ɛ', 'e')
    .replaceAll('Ɛ', 'E')
    .replaceAll('ɔ', 'o')
    .replaceAll('Ɔ', 'O')
    .replaceAll(RegExp(r'[^\x00-\xFF]'), '');

/// Print-safe money: GHS 1,234.50 (never the ₵ glyph).
String slipMoney(int pesewas) {
  final sign = pesewas < 0 ? '-' : '';
  final abs = pesewas.abs();
  final cedis = (abs ~/ 100).toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  return '${sign}GHS $cedis.${(abs % 100).toString().padLeft(2, '0')}';
}

/// Builds ESC/POS bytes for an 80mm slip (58mm printers accept it cropped;
/// PaperSize is a Phase 4 setting candidate). Pure generation — unit-tested.
class PrintSlipBuilder {
  static Future<List<int>> build(SlipData slip) async {
    final profile = await CapabilityProfile.load();
    final gen = Generator(PaperSize.mm80, profile);
    var bytes = <int>[];
    bytes += gen.text(slipSafe(slip.businessName),
        styles: const PosStyles(
            align: PosAlign.center, bold: true, height: PosTextSize.size2));
    bytes += gen.text('Receipt ${slip.receiptNo}',
        styles: const PosStyles(align: PosAlign.center));
    bytes += gen.text(slip.dateText,
        styles: const PosStyles(align: PosAlign.center));
    bytes += gen.hr();
    for (final line in slip.itemLines) {
      bytes += gen.text(slipSafe(line));
    }
    bytes += gen.hr();
    bytes += gen.text('TOTAL: ${slipSafe(slip.totalText)}',
        styles: const PosStyles(bold: true, height: PosTextSize.size2));
    if (slip.cashierName != null) {
      bytes += gen.text('Served by: ${slipSafe(slip.cashierName!)}');
    }
    bytes += gen.feed(1);
    bytes += gen.qrcode(slip.qrText, size: QRSize.size8);
    bytes += gen.text('Scan with the CA app to save this receipt',
        styles: const PosStyles(align: PosAlign.center));
    bytes += gen.feed(2);
    bytes += gen.cut();
    return bytes;
  }
}

class ThermalPrintService {
  static const _storage = FlutterSecureStorage();
  static const _macKey = 'printer_mac';

  static Future<bool> ensurePermissions() async {
    final statuses = await [
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.bluetooth,
      Permission.locationWhenInUse,
    ].request();
    // Older Android grants via legacy bluetooth/location; newer via connect.
    return statuses[Permission.bluetoothConnect]?.isGranted != false ||
        statuses[Permission.bluetooth]?.isGranted == true;
  }

  static Future<bool> get bluetoothOn async =>
      await PrintBluetoothThermal.bluetoothEnabled;

  static Future<List<BluetoothInfo>> bondedPrinters() async {
    try {
      return await PrintBluetoothThermal.pairedBluetooths;
    } catch (_) {
      return const [];
    }
  }

  static Future<String?> rememberedMac() => _storage.read(key: _macKey);

  static Future<void> rememberMac(String mac) =>
      _storage.write(key: _macKey, value: mac);

  static Future<bool> printSlip(String macAddress, SlipData slip) async {
    final connected = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
    if (!connected) return false;
    final bytes = await PrintSlipBuilder.build(slip);
    return PrintBluetoothThermal.writeBytes(bytes);
  }
}
