import '../models.dart';
import '../receipt_signer.dart';

// GRA-ready tax reporting + exports (Phase 5) — pure logic, unit-tested.
//
// The per-component tax breakdown (VAT / NHIL / GETFund / levies) lives in
// each receipt's signed payload, so reports are built by decoding the
// stored QR payloads — the same data the buyer verified. This keeps the
// report provably consistent with what was issued.
//
// IMPORTANT: CA is NOT GRA-certified and this report does not file anything
// with GRA. It prepares clean records in the shape a VAT return needs
// (see docs/GRA_EVAT_READINESS.md).

class TaxReportRow {
  const TaxReportRow({
    required this.date,
    required this.receiptNo,
    required this.buyer,
    required this.netPesewas,
    required this.taxByComponent,
    required this.totalPesewas,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.cashier,
  });
  final DateTime date;
  final String receiptNo;
  final String buyer;
  final int netPesewas; // items subtotal (total minus positive taxes)
  final Map<String, int> taxByComponent;
  final int totalPesewas;
  final String paymentMethod;
  final String paymentStatus;
  final String cashier;
}

class TaxReport {
  const TaxReport({
    required this.rows,
    required this.components,
    required this.totalNetPesewas,
    required this.totalTaxByComponent,
    required this.grandTotalPesewas,
    required this.skippedUndecodable,
  });
  final List<TaxReportRow> rows;
  final List<String> components; // tax component names, sorted
  final int totalNetPesewas;
  final Map<String, int> totalTaxByComponent;
  final int grandTotalPesewas;
  final int skippedUndecodable;
}

/// One issued receipt as stored locally: the signed QR text (source of the
/// tax breakdown) + local stamps (cashier, payment tracking).
typedef ReportInput = ({
  String qrText,
  String? cashierName,
  String? paymentStatus,
  String? paymentMethodOverride,
});

TaxReport buildTaxReport(List<ReportInput> inputs,
    {required DateTime from, required DateTime to}) {
  final rows = <TaxReportRow>[];
  final componentTotals = <String, int>{};
  var skipped = 0;
  var net = 0;
  var grand = 0;

  for (final input in inputs) {
    final payload = ReceiptSigner.decodePayloadUnverified(input.qrText);
    if (payload == null) {
      skipped++;
      continue;
    }
    final Receipt r;
    try {
      r = Receipt.fromPayload(payload);
    } catch (_) {
      skipped++;
      continue;
    }
    if (r.issuedAt.isBefore(from) || !r.issuedAt.isBefore(to)) continue;
    final byComponent = <String, int>{};
    for (final t in r.taxLines) {
      // Discounts are stored as negative tax lines (Phase 2 convention) —
      // they reduce the net, they are not a tax component.
      if (t.amountPesewas < 0) continue;
      byComponent[t.name] = (byComponent[t.name] ?? 0) + t.amountPesewas;
      componentTotals[t.name] = (componentTotals[t.name] ?? 0) + t.amountPesewas;
    }
    final rowNet = r.totalPesewas -
        byComponent.values.fold<int>(0, (s, v) => s + v);
    rows.add(TaxReportRow(
      date: r.issuedAt,
      receiptNo: r.receiptNo,
      buyer: r.buyerName ?? 'Walk-in buyer',
      netPesewas: rowNet,
      taxByComponent: byComponent,
      totalPesewas: r.totalPesewas,
      paymentMethod: input.paymentMethodOverride ?? r.paymentMethod,
      paymentStatus: input.paymentStatus ?? 'paid',
      cashier: input.cashierName ?? 'Owner',
    ));
    net += rowNet;
    grand += r.totalPesewas;
  }
  rows.sort((a, b) => a.date.compareTo(b.date));
  final components = componentTotals.keys.toList()..sort();
  return TaxReport(
    rows: rows,
    components: components,
    totalNetPesewas: net,
    totalTaxByComponent: componentTotals,
    grandTotalPesewas: grand,
    skippedUndecodable: skipped,
  );
}

String _csv(String v) =>
    v.contains(',') || v.contains('"') ? '"${v.replaceAll('"', '""')}"' : v;

String _money(int pesewas) => (pesewas / 100).toStringAsFixed(2);

/// CSV shaped for a VAT return working paper + accountant review:
/// one row per receipt with per-component tax columns, then a summary.
String taxReportCsv(TaxReport report, {required String businessName}) {
  final b = StringBuffer();
  b.writeln('CA Sales & Tax Report,${_csv(businessName)}');
  b.writeln('Generated,${DateTime.now().toIso8601String()}');
  b.writeln('Note,Prepared by CA — not a GRA filing. CA is not GRA-certified.');
  b.writeln();
  b.writeln([
    'Date', 'Receipt No', 'Buyer', 'Net (GHS)',
    for (final c in report.components) '$c (GHS)',
    'Total (GHS)', 'Payment', 'Payment Status', 'Cashier',
  ].map(_csv).join(','));
  for (final r in report.rows) {
    b.writeln([
      r.date.toIso8601String().substring(0, 10),
      r.receiptNo, r.buyer, _money(r.netPesewas),
      for (final c in report.components) _money(r.taxByComponent[c] ?? 0),
      _money(r.totalPesewas), r.paymentMethod, r.paymentStatus, r.cashier,
    ].map(_csv).join(','));
  }
  b.writeln();
  b.writeln('SUMMARY');
  b.writeln('Net sales (GHS),${_money(report.totalNetPesewas)}');
  for (final c in report.components) {
    b.writeln('${_csv(c)} (GHS),${_money(report.totalTaxByComponent[c] ?? 0)}');
  }
  b.writeln('Grand total (GHS),${_money(report.grandTotalPesewas)}');
  b.writeln('Receipts,${report.rows.length}');
  if (report.skippedUndecodable > 0) {
    b.writeln('Skipped unreadable receipts,${report.skippedUndecodable}');
  }
  return b.toString();
}

/// Flat one-row-per-item export for accounting tools (QuickBooks/Xero import
/// prep or a human accountant): receipt header repeated on each item line.
String itemsCsv(List<ReportInput> inputs,
    {required DateTime from, required DateTime to}) {
  final b = StringBuffer();
  b.writeln('Date,Receipt No,Buyer,Item,Qty,Unit Price (GHS),Line Total (GHS),'
      'Receipt Total (GHS),Payment,Cashier');
  final receipts = <Receipt>[];
  final meta = <String, ReportInput>{};
  for (final i in inputs) {
    final payload = ReceiptSigner.decodePayloadUnverified(i.qrText);
    if (payload == null) continue;
    try {
      final r = Receipt.fromPayload(payload);
      if (r.issuedAt.isBefore(from) || !r.issuedAt.isBefore(to)) continue;
      receipts.add(r);
      meta[r.id] = i;
    } catch (_) {/* skip */}
  }
  receipts.sort((a, b2) => a.issuedAt.compareTo(b2.issuedAt));
  for (final r in receipts) {
    for (final item in r.items) {
      b.writeln([
        r.issuedAt.toIso8601String().substring(0, 10),
        r.receiptNo, r.buyerName ?? 'Walk-in buyer', item.name,
        '${item.qty}', _money(item.unitPricePesewas), _money(item.amountPesewas),
        _money(r.totalPesewas), r.paymentMethod,
        meta[r.id]?.cashierName ?? 'Owner',
      ].map(_csv).join(','));
    }
  }
  return b.toString();
}

/// e-VAT readiness checklist — computed from what the business has on file.
List<({String label, bool ok, String hint})> evatReadiness({
  required String? tin,
  required bool vatRegistered,
  required bool businessVerified,
  required bool presetsConfirmed,
  required int receiptsWithTaxLines,
  required int totalReceipts,
}) {
  return [
    (label: 'Business TIN on file', ok: (tin ?? '').trim().isNotEmpty,
     hint: 'Add it under Business Verification — e-VAT invoices must carry the seller TIN.'),
    (label: 'VAT-registered status recorded', ok: vatRegistered,
     hint: 'If the business is VAT-registered, record it in Business Verification.'),
    (label: 'Business verified in CA', ok: businessVerified,
     hint: 'Complete Business Verification (Phase 3) — GRA onboarding will require business documents.'),
    (label: 'Tax presets confirmed with accountant', ok: presetsConfirmed,
     hint: 'The VAT/NHIL/GETFund presets are defaults — confirm current rates with your accountant.'),
    (label: 'Receipts carry a tax breakdown', ok: totalReceipts > 0 && receiptsWithTaxLines == totalReceipts,
     hint: 'Use the tax preset toggle when issuing so every receipt has its VAT/NHIL/GETFund lines.'),
  ];
}
