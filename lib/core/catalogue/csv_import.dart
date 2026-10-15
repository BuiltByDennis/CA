/// Bulk price-list import (v0.7.3) — the answer for businesses that
/// already keep their items in ANOTHER system (supermarket POS, Excel).
/// Every till/accounting system can export a CSV; CA reads it directly:
/// no re-typing names and prices one by one.
///
/// Pure logic, fully tested. Tolerates the mess of real exports:
/// comma OR semicolon separators, quoted fields with commas inside,
/// whatever header names the other system uses (Item/Product/
/// Description… Price/Selling Price… Barcode/EAN/UPC/SKU/Code…),
/// GH₵ symbols and thousands commas inside prices.
library;

/// One row ready for the catalogue.
class ImportRow {
  const ImportRow(this.name, this.pricePesewas, this.barcode);
  final String name;
  final int pricePesewas;
  final String? barcode;
}

class ImportAnalysis {
  const ImportAnalysis({
    required this.rows,
    required this.totalLines,
    required this.skippedNoName,
    required this.skippedBadPrice,
    required this.nameHeader,
    required this.priceHeader,
    required this.barcodeHeader,
  });
  final List<ImportRow> rows;
  final int totalLines;
  final int skippedNoName;
  final int skippedBadPrice;
  final String? nameHeader;
  final String? priceHeader;
  final String? barcodeHeader;
}

/// Splits CSV text into rows of cells. Handles quoted fields (commas,
/// quotes and newlines inside quotes) and CRLF line endings.
List<List<String>> parseCsv(String text, {String separator = ','}) {
  final rows = <List<String>>[];
  var row = <String>[];
  var cell = StringBuffer();
  var inQuotes = false;
  final s = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  void endCell() {
    row.add(cell.toString());
    cell = StringBuffer();
  }

  void endRow() {
    endCell();
    rows.add(row);
    row = <String>[];
  }

  for (var i = 0; i < s.length; i++) {
    final c = s[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < s.length && s[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        cell.write(c);
      }
    } else if (c == '"') {
      inQuotes = true;
    } else if (c == separator) {
      endCell();
    } else if (c == '\n') {
      endRow();
    } else {
      cell.write(c);
    }
  }
  if (cell.isNotEmpty || row.isNotEmpty) endRow();
  return rows.where((r) => r.any((c) => c.trim().isNotEmpty)).toList();
}

String _normHeader(String h) =>
    h.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

const _nameHeaders = {
  'name', 'itemname', 'productname', 'item', 'product', 'description',
  'itemdescription', 'productdescription', 'goods', 'stockitem', 'title',
};
const _priceHeaders = {
  'price', 'sellingprice', 'unitprice', 'retailprice', 'saleprice',
  'amount', 'cost', 'priceghs', 'pricegh', 'selling', 'unitcost',
};
const _barcodeHeaders = {
  'barcode', 'ean', 'upc', 'sku', 'code', 'itemcode', 'productcode',
  'plu', 'barcodeno', 'barcodenumber', 'gtin',
};

/// Parses a price cell to pesewas; null when it isn't a number.
/// 'GH₵1,250.50' → 125050, '45' → 4500, '12.5' → 1250.
int? parsePriceCell(String raw) {
  final cleaned = raw
      .replaceAll(RegExp(r'GH₵|GHS|GHc|₵', caseSensitive: false), '')
      .replaceAll(',', '')
      .trim();
  if (cleaned.isEmpty) return null;
  final v = double.tryParse(cleaned);
  if (v == null || v < 0) return null;
  return (v * 100).round();
}

/// Full analysis of a price-list file: detects the separator, finds the
/// name/price/barcode columns by header, converts rows. [hasHeader]
/// matters: with no recognisable header, columns fall back to the
/// template order name,price,barcode.
ImportAnalysis analyzeImport(String text) {
  final firstLine = text.split('\n').firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
  final separator = firstLine.contains(';') && !firstLine.contains(',') ? ';' : ',';
  final table = parseCsv(text, separator: separator);
  if (table.isEmpty) {
    return const ImportAnalysis(rows: [], totalLines: 0, skippedNoName: 0,
        skippedBadPrice: 0, nameHeader: null, priceHeader: null, barcodeHeader: null);
  }
  final headers = table.first.map(_normHeader).toList();
  var nameIdx = headers.indexWhere(_nameHeaders.contains);
  var priceIdx = headers.indexWhere(_priceHeaders.contains);
  var barcodeIdx = headers.indexWhere(_barcodeHeaders.contains);
  final hasHeader = nameIdx >= 0 || priceIdx >= 0 || barcodeIdx >= 0;
  var data = table;
  if (hasHeader) {
    data = table.sublist(1);
    if (nameIdx < 0) nameIdx = 0;
    if (priceIdx < 0) priceIdx = 1;
    if (barcodeIdx < 0 && table.first.length > 2) barcodeIdx = 2;
  } else {
    nameIdx = 0;
    priceIdx = 1;
    barcodeIdx = 2;
  }
  final rows = <ImportRow>[];
  var noName = 0, badPrice = 0;
  for (final cells in data) {
    String at(int i) => i >= 0 && i < cells.length ? cells[i].trim() : '';
    final name = at(nameIdx);
    if (name.isEmpty) {
      noName++;
      continue;
    }
    final price = parsePriceCell(at(priceIdx));
    if (price == null) {
      if (at(priceIdx).isNotEmpty) {
        badPrice++;
        continue;
      }
      rows.add(ImportRow(name, 0, at(barcodeIdx).isEmpty ? null : at(barcodeIdx)));
    } else {
      rows.add(ImportRow(name, price, at(barcodeIdx).isEmpty ? null : at(barcodeIdx)));
    }
  }
  String? original(int idx) =>
      hasHeader && idx >= 0 && idx < table.first.length ? table.first[idx] : null;
  return ImportAnalysis(
    rows: rows,
    totalLines: data.length,
    skippedNoName: noName,
    skippedBadPrice: badPrice,
    nameHeader: original(nameIdx),
    priceHeader: original(priceIdx),
    barcodeHeader: barcodeIdx >= 0 ? original(barcodeIdx) : null,
  );
}

/// The template a shop can fill in Excel when their system can't export.
const templateCsv = 'name,price,barcode\n'
    'Milo 400g,45.00,6030000123456\n'
    'Ideal Milk Tin,12.50,6030000654321\n'
    'Tomatoes (bowl),20.00,\n';

/// Decides inserts vs updates for an import against the existing
/// catalogue (match by barcode first, then by name, case-insensitive) —
/// so re-importing an updated price list REFRESHES prices instead of
/// piling up duplicates.
({List<ImportRow> inserts, List<({String id, ImportRow row})> updates})
    planImport(
  List<({String id, String name, String? barcode})> existing,
  List<ImportRow> rows,
) {
  final byBarcode = <String, String>{
    for (final e in existing) if (e.barcode != null && e.barcode!.isNotEmpty) e.barcode!: e.id
  };
  final byName = <String, String>{
    for (final e in existing) e.name.toLowerCase(): e.id
  };
  final inserts = <ImportRow>[];
  final updates = <({String id, ImportRow row})>[];
  for (final r in rows) {
    final id = (r.barcode != null ? byBarcode[r.barcode] : null) ??
        byName[r.name.toLowerCase()];
    if (id == null) {
      inserts.add(r);
    } else {
      updates.add((id: id, row: r));
    }
  }
  return (inserts: inserts, updates: updates);
}

/// Serialises the catalogue back to CSV (backup / move to another phone /
/// hand to the next system).
String catalogueToCsv(List<({String name, int pricePesewas, String? barcode})> items) {
  String esc(String s) =>
      s.contains(',') || s.contains('"') || s.contains('\n') ? '"${s.replaceAll('"', '""')}"' : s;
  final b = StringBuffer('name,price,barcode\n');
  for (final i in items) {
    b.writeln('${esc(i.name)},${(i.pricePesewas / 100).toStringAsFixed(2)},${i.barcode ?? ''}');
  }
  return b.toString();
}
