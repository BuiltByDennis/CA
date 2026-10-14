/// Receipt text parser (Phase 2) — pure Dart, no Flutter, fully unit-tested.
///
/// Takes raw OCR text from a POS/printed receipt and extracts seller, receipt
/// number, date/time, items, tax, discount and total — all money in pesewas.
///
/// IMPORTANT (honest design): ML Kit text recognition gives NO per-word
/// confidence score, so "needs check" flags here are *validation* flags:
/// qty x unit != line amount, items+tax-discount != printed total, missing
/// fields, or OCR-garbled characters in the line. The human approves/edits
/// everything before a QR is issued — the parser never auto-issues.
library;

class ParsedItem {
  ParsedItem({
    required this.name,
    required this.qty,
    required this.unitPricePesewas,
    required this.amountPesewas,
    required this.rawLine,
    this.needsCheck = false,
  });
  String name;
  int qty;
  int unitPricePesewas;
  int amountPesewas;
  final String rawLine;
  bool needsCheck;
}

class ParsedReceipt {
  String? sellerName;
  String? receiptNo;
  String? originalDateText;
  DateTime? dateTime;
  final List<ParsedItem> items = [];
  int? subtotalPesewas;
  int taxPesewas = 0;
  int discountPesewas = 0;
  int? totalPesewas;
  String? paymentMethod;
  final List<String> warnings = [];

  int get itemsTotalPesewas => items.fold(0, (s, i) => s + i.amountPesewas);
  int get computedTotalPesewas => itemsTotalPesewas + taxPesewas - discountPesewas;

  /// Printed total agrees with items + tax - discount (1 pesewa rounding slack).
  bool get totalsMatch =>
      totalPesewas != null && (computedTotalPesewas - totalPesewas!).abs() <= 1;
}

class ReceiptParser {
  static final _moneyRe = RegExp(r'(\d{1,3}(?:,\d{3})*\.\d{2})');
  static int _toPesewas(String s) =>
      (double.parse(s.replaceAll(',', '')) * 100).round();

  static List<({int value, int start, int end})> _money(String line) => [
        for (final m in _moneyRe.allMatches(line))
          (value: _toPesewas(m.group(1)!), start: m.start, end: m.end)
      ];

  static final _noPatterns = <RegExp>[
    RegExp(
        r'(?:receipt|rcpt|invoice|inv|bill|order|txn|transaction)\s*(?:no\.?|number|num|#|id)?\s*[:#\-]?\s*([A-Za-z0-9][A-Za-z0-9\-/]{2,})',
        caseSensitive: false),
  ];

  static bool _isTaxLine(String lower) =>
      lower.contains('vat') ||
      lower.contains('nhil') ||
      lower.contains('getfund') ||
      lower.contains('get fund') ||
      lower.contains('levy') ||
      lower.contains('tax');

  static bool _isSubtotalLine(String lower) =>
      lower.contains('subtotal') || lower.contains('sub total') || lower.contains('sub-total');

  static bool _isTotalLine(String lower) =>
      lower.contains('total') && !_isSubtotalLine(lower);

  static ParsedReceipt parse(String ocrText) {
    final r = ParsedReceipt();
    final lines = ocrText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      r.warnings.add('No text was recognised in this image.');
      return r;
    }

    // Seller: first plausible header line.
    for (final l in lines) {
      final low = l.toLowerCase();
      if (l.length >= 3 &&
          RegExp(r'[A-Za-z]').hasMatch(l) &&
          !low.contains('receipt') &&
          !low.contains('invoice') &&
          !low.contains('welcome') &&
          !low.startsWith('tel')) {
        r.sellerName = l;
        break;
      }
    }

    // Receipt number.
    for (final l in lines) {
      for (final pat in _noPatterns) {
        final m = pat.firstMatch(l);
        if (m != null) {
          var v = m.group(1)!.replaceAll(RegExp(r'[.,]+$'), '');
          final vl = v.toLowerCase();
          if (vl != 'date' && vl != 'no' && vl.length >= 3) {
            r.receiptNo = v;
            break;
          }
        }
      }
      if (r.receiptNo != null) break;
    }
    if (r.receiptNo == null) {
      // Fallback: a line starting with "No:" / "No."
      for (final l in lines) {
        final m = RegExp(r'^\s*no\s*[:.]\s*([A-Za-z0-9][A-Za-z0-9\-/]{2,})',
                caseSensitive: false)
            .firstMatch(l);
        if (m != null) {
          r.receiptNo = m.group(1);
          break;
        }
      }
    }

    // Date/time.
    final months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    final timeRe = RegExp(r'(\d{1,2}):(\d{2})(?:\s*(AM|PM))?', caseSensitive: false);
    for (final l in lines) {
      DateTime? d;
      // ISO yyyy-mm-dd MUST be tried before d/m/y, or '2026-10-09' misreads
      // as day 26, month 10, year 2009.
      var iso = RegExp(r'(\d{4})-(\d{2})-(\d{2})').firstMatch(l);
      if (iso != null) {
        d = DateTime(int.parse(iso.group(1)!), int.parse(iso.group(2)!),
            int.parse(iso.group(3)!));
      }
      var m = d == null
          ? RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{2,4})').firstMatch(l)
          : null;
      if (m != null) {
        var day = int.parse(m.group(1)!);
        var mon = int.parse(m.group(2)!);
        var yr = int.parse(m.group(3)!);
        if (yr < 100) yr += 2000;
        if (mon > 12 && day <= 12) {
          final tmp = day;
          day = mon;
          mon = tmp;
        }
        if (mon >= 1 && mon <= 12 && day >= 1 && day <= 31) {
          d = DateTime(yr, mon, day);
        }
      }
      if (d == null) {
        m = RegExp(r'(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(\d{4})',
                caseSensitive: false)
            .firstMatch(l);
        if (m != null) {
          d = DateTime(int.parse(m.group(3)!), months[m.group(2)!.toLowerCase()]!,
              int.parse(m.group(1)!));
        }
      }
      if (d != null) {
        r.originalDateText = l;
        var hh = 0, mm2 = 0;
        final tm = timeRe.firstMatch(l);
        if (tm != null) {
          hh = int.parse(tm.group(1)!);
          mm2 = int.parse(tm.group(2)!);
          final ap = tm.group(3)?.toUpperCase();
          if (ap == 'PM' && hh < 12) hh += 12;
          if (ap == 'AM' && hh == 12) hh = 0;
        }
        r.dateTime = DateTime(d.year, d.month, d.day, hh, mm2);
        break;
      }
    }

    // Money lines: totals, tax, discount, items.
    int? grandTotal;
    for (final l in lines) {
      final low = l.toLowerCase();
      final money = _money(l);
      if (money.isEmpty) {
        _detectPayment(low, r);
        continue;
      }
      final last = money.last.value;
      if (_isSubtotalLine(low)) {
        r.subtotalPesewas = last;
        continue;
      }
      if (_isTotalLine(low)) {
        grandTotal = last; // last total line wins (grand total comes last)
        continue;
      }
      if (low.contains('discount')) {
        r.discountPesewas = last;
        continue;
      }
      if (_isTaxLine(low)) {
        r.taxPesewas += last;
        continue;
      }
      if (low.startsWith('cash') ||
          low.startsWith('change') ||
          low.startsWith('tendered') ||
          low.startsWith('balance') ||
          low.startsWith('amount paid')) {
        _detectPayment(low, r);
        continue;
      }
      _detectPayment(low, r);
      final item = _parseItemLine(l, money);
      if (item != null) r.items.add(item);
    }
    r.totalPesewas = grandTotal ?? r.subtotalPesewas;

    // Warnings / validation.
    if (r.receiptNo == null) r.warnings.add('Receipt number not found — add it in review.');
    if (r.dateTime == null) r.warnings.add('Date not found — check the receipt date.');
    if (r.items.isEmpty) r.warnings.add('No items extracted — add them manually.');
    if (r.totalPesewas == null) {
      r.warnings.add('Total not found — the total will be calculated from items.');
    } else if (!r.totalsMatch && r.items.isNotEmpty) {
      r.warnings.add(
          'Printed total does not match items + tax − discount. Check the flagged lines.');
    }
    final flagged = r.items.where((i) => i.needsCheck).length;
    if (flagged > 0) r.warnings.add('$flagged item line(s) need checking (highlighted).');
    return r;
  }

  static void _detectPayment(String low, ParsedReceipt r) {
    if (r.paymentMethod != null) return;
    if (low.contains('momo') || low.contains('mobile money')) {
      r.paymentMethod = 'MoMo';
    } else if (low.contains('visa') || low.contains('mastercard') || low.contains('card')) {
      r.paymentMethod = 'Card';
    } else if (low.contains('transfer') || low.contains('bank')) {
      r.paymentMethod = 'Bank';
    } else if (low.contains('cash')) {
      r.paymentMethod = 'Cash';
    }
  }

  static ParsedItem? _parseItemLine(
      String line, List<({int value, int start, int end})> money) {
    final amount = money.last.value;
    if (amount <= 0) return null;
    // Core text: everything before the unit-price token (2nd-last money) if
    // present, else before the amount token.
    final coreEnd = money.length >= 2 ? money[money.length - 2].start : money.last.start;
    var core = line.substring(0, coreEnd).trim();
    // Trailing currency words/symbols in the core.
    core = core.replaceAll(RegExp(r'(GH₵|GHS|GHc|¢)\s*$', caseSensitive: false), '').trim();

    var qty = 1;
    var name = core;
    var needsCheck = line.contains('|') || line.contains('¦');

    final leadQty = RegExp(r'^(\d+)\s*[xX]\s+(.+)$').firstMatch(core);
    final trailQtyX = RegExp(r'^(.+?)\s+(\d+)\s*[xX]\s*$').firstMatch(core);
    final trailXQty = RegExp(r'^(.+?)\s*[xX](\d+)\s*$').firstMatch(core);
    final trailQty = RegExp(r'^(.+?)\s+(\d+)\s*$').firstMatch(core);
    if (leadQty != null) {
      qty = int.parse(leadQty.group(1)!);
      name = leadQty.group(2)!;
    } else if (trailQtyX != null) {
      name = trailQtyX.group(1)!;
      qty = int.parse(trailQtyX.group(2)!);
    } else if (trailXQty != null) {
      name = trailXQty.group(1)!;
      qty = int.parse(trailXQty.group(2)!);
    } else if (trailQty != null && money.length >= 2) {
      name = trailQty.group(1)!;
      qty = int.parse(trailQty.group(2)!);
    }
    if (qty <= 0) qty = 1;

    name = name
        .replaceAll(RegExp(r'[\s\-:.@]+$'), '')
        .replaceAll(RegExp(r'^[\s\-:.@]+'), '')
        .replaceAll('|', '')
        .trim();
    if (name.isEmpty || !RegExp(r'[A-Za-z]').hasMatch(name)) return null;

    int unitPrice;
    if (qty == 1) {
      unitPrice = amount;
    } else if (money.length >= 2 && money[money.length - 2].value * qty == amount) {
      unitPrice = money[money.length - 2].value;
    } else if (amount % qty == 0) {
      unitPrice = amount ~/ qty;
      if (money.length >= 2) needsCheck = true; // unit column disagreed
    } else {
      unitPrice = (amount / qty).round();
      needsCheck = true; // qty x unit cannot reproduce the amount exactly
    }
    if (qty * unitPrice != amount) needsCheck = true;
    if (name.length < 2) needsCheck = true;
    return ParsedItem(
      name: name,
      qty: qty,
      unitPricePesewas: unitPrice,
      amountPesewas: amount,
      rawLine: line,
      needsCheck: needsCheck,
    );
  }
}
