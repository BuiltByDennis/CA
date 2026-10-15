/// Seller referral codes (Phase 7). A code is derived deterministically
/// from the business ID, so it is stable across devices and needs no
/// server round-trip to display: CA-XXXXXX (6 base32 chars).
/// Referral codes are public identifiers, not secrets.
String referralCodeFor(String businessId) {
  var h1 = 0x811c9dc5, h2 = 0x01000193 ^ 0x9e3779b9;
  for (final c in businessId.codeUnits) {
    h1 = ((h1 ^ c) * 0x01000193) & 0xffffffff;
    h2 = ((h2 * 31) + c) & 0xffffffff;
  }
  const alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789'; // no I, L, O, 0, 1
  final buf = StringBuffer('CA-');
  var v = (h1 << 16) ^ h2;
  for (var i = 0; i < 6; i++) {
    buf.write(alphabet[v % alphabet.length]);
    v = (v ~/ alphabet.length) ^ (h1 >> (i + 1));
  }
  return buf.toString();
}

bool isValidReferralCode(String s) =>
    RegExp(r'^CA-[A-Z2-9]{6}$').hasMatch(s.trim().toUpperCase());
