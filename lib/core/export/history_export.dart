import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// History export (v0.8.1): users asked for their receipt history as a
/// PDF / Excel file — for accountants, loan applications, their own
/// records. Fully offline: the document is generated on the phone and
/// handed to the share sheet.
///
/// The Excel file is a REAL .xlsx (two sheets: Summary + Items), built
/// directly as zipped XML with the archive package — the popular `excel`
/// package can't be used (its archive ^3 requirement conflicts with
/// the OCR image package's archive ^4).

class ExportItem {
  const ExportItem(this.name, this.qty, this.unitPricePesewas);
  final String name;
  final int qty;
  final int unitPricePesewas;
  int get amountPesewas => qty * unitPricePesewas;
}

class ExportReceipt {
  const ExportReceipt({
    required this.receiptNo,
    required this.direction, // issued | saved
    required this.sellerName,
    required this.buyerName,
    required this.paymentMethod,
    required this.totalPesewas,
    required this.issuedAtUnix,
    required this.items,
  });
  final String receiptNo;
  final String direction;
  final String sellerName;
  final String? buyerName;
  final String paymentMethod;
  final int totalPesewas;
  final int issuedAtUnix;
  final List<ExportItem> items;

  /// The other party: for issued receipts the buyer, for saved ones the seller.
  String get counterparty => direction == 'issued' ? (buyerName ?? 'Walk-in') : sellerName;
  DateTime get date => DateTime.fromMillisecondsSinceEpoch(issuedAtUnix * 1000);
}

class HistorySummary {
  const HistorySummary(this.issuedCount, this.issuedTotal, this.savedCount, this.savedTotal);
  final int issuedCount;
  final int issuedTotal;
  final int savedCount;
  final int savedTotal;
}

HistorySummary summarise(List<ExportReceipt> receipts) {
  var ic = 0, it = 0, sc = 0, st = 0;
  for (final r in receipts) {
    if (r.direction == 'issued') {
      ic++;
      it += r.totalPesewas;
    } else {
      sc++;
      st += r.totalPesewas;
    }
  }
  return HistorySummary(ic, it, sc, st);
}

String _date(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

double _cedis(int pesewas) => pesewas / 100;

/// PDF-safe money: the built-in PDF font has no ₵ glyph (U+20B5), so
/// PDF text spells the currency out. (Excel gets numbers, screens get ₵.)
String _ghs(int pesewas) => 'GHS ${(pesewas / 100).toStringAsFixed(2)}';

/// The built-in PDF font also lacks — and • glyphs; sanitise PDF text.
String _pdfSafe(String s) => s
    .replaceAll('—', '-')
    .replaceAll('–', '-')
    .replaceAll('•', '|')
    .replaceAll('‘', "'")
    .replaceAll('’', "'")
    .replaceAll('“', '"')
    .replaceAll('”', '"');

// ---------------------------------------------------------------- PDF

Future<Uint8List> buildHistoryPdf(List<ExportReceipt> receipts,
    {required String title}) async {
  final s = summarise(receipts);
  final doc = pw.Document();
  final headerStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9);
  final cell = const pw.TextStyle(fontSize: 9);
  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    build: (ctx) => [
      pw.Text('CA - Receipt History',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
      pw.Text(_pdfSafe(title), style: const pw.TextStyle(fontSize: 11)),
      pw.Text('Generated ${DateTime.now().toLocal().toString().split('.').first}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
      pw.SizedBox(height: 10),
      pw.Text(
          'Issued: ${s.issuedCount} receipt(s) totalling ${_ghs(s.issuedTotal)}   |   '
          'Saved: ${s.savedCount} receipt(s) totalling ${_ghs(s.savedTotal)}',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 12),
      pw.TableHelper.fromTextArray(
        headerStyle: headerStyle,
        cellStyle: cell,
        headers: const ['Date', 'Receipt No', 'Type', 'From / To', 'Payment', 'Total'],
        data: [
          for (final r in receipts)
            [
              _date(r.date.toLocal()),
              r.receiptNo,
              r.direction == 'issued' ? 'Issued' : 'Saved',
              _pdfSafe(r.counterparty),
              r.paymentMethod,
              _ghs(r.totalPesewas),
            ]
        ],
      ),
      pw.SizedBox(height: 16),
      pw.Text('Item details',
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 6),
      pw.TableHelper.fromTextArray(
        headerStyle: headerStyle,
        cellStyle: cell,
        headers: const ['Receipt No', 'Item', 'Qty', 'Unit price', 'Amount'],
        data: [
          for (final r in receipts)
            for (final i in r.items)
              [
                r.receiptNo,
                _pdfSafe(i.name),
                '${i.qty}',
                _ghs(i.unitPricePesewas),
                _ghs(i.amountPesewas),
              ]
        ],
      ),
      pw.SizedBox(height: 10),
      pw.Text('Generated by CA. Receipts are digitally signed at issue; '
          'this document is a readable copy of the history held on the phone.',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
    ],
  ));
  return doc.save();
}

// ---------------------------------------------------------------- XLSX

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

String _col(int i) {
  var n = i + 1, out = '';
  while (n > 0) {
    final m = (n - 1) % 26;
    out = String.fromCharCode(65 + m) + out;
    n = (n - 1) ~/ 26;
  }
  return out;
}

String _sheetXml(List<List<Object?>> rows, {List<double>? widths}) {
  final b = StringBuffer('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">');
  if (widths != null) {
    b.write('<cols>');
    for (var i = 0; i < widths.length; i++) {
      b.write('<col min="${i + 1}" max="${i + 1}" width="${widths[i]}" customWidth="1"/>');
    }
    b.write('</cols>');
  }
  b.write('<sheetData>');
  for (var r = 0; r < rows.length; r++) {
    b.write('<row r="${r + 1}">');
    for (var c = 0; c < rows[r].length; c++) {
      final v = rows[r][c];
      final ref = '${_col(c)}${r + 1}';
      final header = r == 0 ? ' s="1"' : '';
      if (v is num) {
        b.write('<c r="$ref"$header><v>${v is double ? v.toStringAsFixed(2) : v}</v></c>');
      } else {
        b.write('<c r="$ref" t="inlineStr"$header><is><t>${_esc(v?.toString() ?? '')}</t></is></c>');
      }
    }
    b.write('</row>');
  }
  b.write('</sheetData></worksheet>');
  return b.toString();
}

Uint8List buildHistoryXlsx(List<ExportReceipt> receipts) {
  final summary = <List<Object?>>[
    ['Date', 'Receipt No', 'Type', 'From / To', 'Payment', 'Total (GHS)'],
    for (final r in receipts)
      [
        _date(r.date.toLocal()),
        r.receiptNo,
        r.direction == 'issued' ? 'Issued' : 'Saved',
        r.counterparty,
        r.paymentMethod,
        _cedis(r.totalPesewas),
      ],
  ];
  final items = <List<Object?>>[
    ['Receipt No', 'Date', 'Item', 'Qty', 'Unit price (GHS)', 'Amount (GHS)'],
    for (final r in receipts)
      for (final i in r.items)
        [
          r.receiptNo,
          _date(r.date.toLocal()),
          i.name,
          i.qty,
          _cedis(i.unitPricePesewas),
          _cedis(i.amountPesewas),
        ],
  ];
  const contentTypes = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
      '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
      '<Override PartName="/xl/worksheets/sheet2.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
      '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
      '</Types>';
  const rootRels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
      '</Relationships>';
  const workbook = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
      '<sheets><sheet name="Summary" sheetId="1" r:id="rId1"/>'
      '<sheet name="Items" sheetId="2" r:id="rId2"/></sheets></workbook>';
  const workbookRels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
      '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet2.xml"/>'
      '<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
      '</Relationships>';
  const styles = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
      '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font>'
      '<font><b/><sz val="11"/><name val="Calibri"/></font></fonts>'
      '<fills count="2"><fill><patternFill patternType="none"/></fill>'
      '<fill><patternFill patternType="gray125"/></fill></fills>'
      '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
      '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
      '<cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
      '<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0"/></cellXfs>'
      '</styleSheet>';
  final archive = Archive();
  void add(String name, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  add('[Content_Types].xml', contentTypes);
  add('_rels/.rels', rootRels);
  add('xl/workbook.xml', workbook);
  add('xl/_rels/workbook.xml.rels', workbookRels);
  add('xl/styles.xml', styles);
  add('xl/worksheets/sheet1.xml',
      _sheetXml(summary, widths: const [18, 16, 9, 26, 10, 13]));
  add('xl/worksheets/sheet2.xml',
      _sheetXml(items, widths: const [16, 18, 34, 7, 15, 13]));
  return Uint8List.fromList(ZipEncoder().encode(archive));
}
