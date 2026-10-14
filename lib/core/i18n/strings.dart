import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Language support (Phase 4): English + Twi (Akan).
///
/// Scope (honest): the home screen, dashboards and main actions are
/// translated. Deep form fields remain English for now. The Twi strings are
/// a first pass and MUST be reviewed by a native Akan speaker before a
/// public release — they are collected here, in one file, for exactly that.
class LanguageService {
  static const _storage = FlutterSecureStorage();
  static final ValueNotifier<String> code = ValueNotifier('en');

  static Future<void> init() async {
    code.value = await _storage.read(key: 'app_lang') ?? 'en';
  }

  static Future<void> set(String lang) async {
    code.value = lang;
    await _storage.write(key: 'app_lang', value: lang);
  }

  static String t(String key) =>
      (_strings[code.value] ?? _strings['en']!)[key] ??
      _strings['en']![key] ??
      key;
}

const _strings = <String, Map<String, String>>{
  'en': {
    'welcome': 'CA — Welcome',
    'howUse': 'How will you use CA?',
    'oneAccount': 'One account. Pick one to start — you can add the others later.',
    'buyer': 'Buyer',
    'sellerIntegrated': 'Seller — has a receipt system',
    'sellerManual': 'Seller — manual receipts',
    'scanForReceipt': 'Scan for Receipt',
    'myReceipts': 'My Receipts (History)',
    'captureReceipt': 'Capture Receipt',
    'receiptHistory': 'Receipt History',
    'newReceipt': 'New Receipt',
    'myReceiptDesign': 'My Receipt Design',
    'mySellerKey': 'My Seller Key (for buyers)',
    'businessVerification': 'Business Verification',
    'analytics': 'Sales Analytics',
    'staff': 'Staff',
    'syncNow': 'Sync Now — backup, verification, verified sellers',
    'buyerTagline': 'Every scanned receipt is signature-checked offline.',
    'language': 'Language',
  },
  'tw': {
    'welcome': 'CA — Akwaaba',
    'howUse': 'Wopɛ sɛ wode CA yɛ dɛn?',
    'oneAccount': 'Account baako pɛ. Yi baako na fa hyɛ aseɛ — wobɛtumi aka afoforɔ ho akyiri.',
    'buyer': 'Ɔtɔfo',
    'sellerIntegrated': 'Ɔtɔnfo — ɔwɔ receipt system',
    'sellerManual': 'Ɔtɔnfo — ɔkyerɛw receipt wɔ nsa',
    'scanForReceipt': 'Skan Receipt',
    'myReceipts': 'Me Receipt a Woanya',
    'captureReceipt': 'Fa Receipt no Foto',
    'receiptHistory': 'Receipt Abakɔsɛm',
    'newReceipt': 'Receipt Foforɔ',
    'myReceiptDesign': 'Me Receipt Nhyehyɛeɛ',
    'mySellerKey': 'Me Seller Key (ma atɔfo)',
    'businessVerification': 'Adwuma no Mu Hwɛ',
    'analytics': 'Ntotɔn Nkontaabuo',
    'staff': 'Adwumayɛfo',
    'syncNow': 'Sync Seisei — backup, mu hwɛ, atɔnfo a wɔagye wɔn ato mu',
    'buyerTagline': 'Receipt biara a woskan no, yɛhwɛ ne signature wɔ offline.',
    'language': 'Kasa',
  },
};

String tr(String key) => LanguageService.t(key);
