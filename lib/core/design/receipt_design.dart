import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Receipt design (Phase 6 — replaces the Phase 0 placeholder screen with a
// real, persisted design): what the business's receipts look like and the
// defaults the New Receipt form starts from. Stored on-device; the design
// is presentation only — it never changes the signed payload contents
// except the seller display name the seller themselves chose at setup.
class ReceiptDesign {
  const ReceiptDesign({
    this.businessDisplayName,
    this.footerNote = 'Thank you for your business!',
    this.applyTaxByDefault = false,
    this.defaultPayment = 'Cash',
    this.style = 0,
  });
  final String? businessDisplayName;
  final String footerNote;
  final bool applyTaxByDefault;
  final String defaultPayment;
  final int style; // 0 classic, 1 compact, 2 bold header

  Map<String, Object?> toJson() => {
        'bn': businessDisplayName, 'footer': footerNote,
        'tax': applyTaxByDefault, 'pay': defaultPayment, 'style': style,
      };

  static ReceiptDesign fromJson(Map<String, dynamic> j) => ReceiptDesign(
        businessDisplayName: j['bn'] as String?,
        footerNote: j['footer'] as String? ?? 'Thank you for your business!',
        applyTaxByDefault: j['tax'] as bool? ?? false,
        defaultPayment: j['pay'] as String? ?? 'Cash',
        style: j['style'] as int? ?? 0,
      );

  ReceiptDesign copyWith({
    String? businessDisplayName, String? footerNote, bool? applyTaxByDefault,
    String? defaultPayment, int? style,
  }) =>
      ReceiptDesign(
        businessDisplayName: businessDisplayName ?? this.businessDisplayName,
        footerNote: footerNote ?? this.footerNote,
        applyTaxByDefault: applyTaxByDefault ?? this.applyTaxByDefault,
        defaultPayment: defaultPayment ?? this.defaultPayment,
        style: style ?? this.style,
      );
}

class DesignStore {
  static const _storage = FlutterSecureStorage();
  static const _key = 'receipt_design';

  static Future<ReceiptDesign?> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      return ReceiptDesign.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(ReceiptDesign d) =>
      _storage.write(key: _key, value: jsonEncode(d.toJson()));
}
