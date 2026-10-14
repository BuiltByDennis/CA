import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/models.dart';
import '../../core/receipt_signer.dart';
import '../../core/services.dart';
import '../../core/tax/tax_report.dart';

/// Tax Report & Exports (Phase 5) — GRA-ready sales/tax reporting.
/// CA is not GRA-certified; this prepares clean records (see
/// docs/GRA_EVAT_READINESS.md). Exports are CSV via the share sheet.
class TaxReportScreen extends StatefulWidget {
  const TaxReportScreen({super.key});
  @override
  State<TaxReportScreen> createState() => _TaxReportScreenState();
}

class _TaxReportScreenState extends State<TaxReportScreen> {
  static const _storage = FlutterSecureStorage();
  String _range = 'thisMonth';
  bool _presetsConfirmed = false;

  @override
  void initState() {
    super.initState();
    _storage.read(key: 'tax_presets_confirmed').then((v) {
      if (mounted) setState(() => _presetsConfirmed = v == 'yes');
    });
  }

  ({DateTime from, DateTime to}) get _window {
    final now = DateTime.now();
    return switch (_range) {
      'lastMonth' => (
          from: DateTime(now.year, now.month - 1, 1),
          to: DateTime(now.year, now.month, 1)),
      'all' => (from: DateTime(2020), to: DateTime(2100)),
      _ => (from: DateTime(now.year, now.month, 1),
            to: DateTime(now.year, now.month + 1, 1)),
    };
  }

  Future<({TaxReport report, List<ReportInput> inputs, List<({String label, bool ok, String hint})> checks, String business})> _load() async {
    final rows = await AppServices.db.issuedReceipts();
    final inputs = rows
        .map((r) => (
              qrText: r.qrText,
              cashierName: r.cashierName,
              paymentStatus: r.paymentStatus,
              paymentMethodOverride: r.paymentMethod,
            ))
        .toList();
    final w = _window;
    final report = buildTaxReport(inputs, from: w.from, to: w.to);
    final verification = await AppServices.db.getVerification();
    final profile = await AppServices.db.getProfile();
    var withTax = 0;
    for (final i in inputs) {
      final payload = ReceiptSigner.decodePayloadUnverified(i.qrText);
      if (payload != null) {
        try {
          if (Receipt.fromPayload(payload).taxLines.isNotEmpty) withTax++;
        } catch (_) {}
      }
    }
    final checks = evatReadiness(
      tin: verification?.tin,
      vatRegistered: verification?.vatRegistered ?? false,
      businessVerified: verification?.status == 'verified',
      presetsConfirmed: _presetsConfirmed,
      receiptsWithTaxLines: withTax,
      totalReceipts: inputs.length,
    );
    return (report: report, inputs: inputs, checks: checks,
        business: verification?.tradingName ?? profile?.businessName ?? 'My Business');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Tax Report & Exports')),
        body: FutureBuilder(
          future: _load(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final d = snap.data!;
            final r = d.report;
            return ListView(padding: const EdgeInsets.all(16), children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'thisMonth', label: Text('This month')),
                  ButtonSegment(value: 'lastMonth', label: Text('Last month')),
                  ButtonSegment(value: 'all', label: Text('All time')),
                ],
                selected: {_range},
                onSelectionChanged: (v) => setState(() => _range = v.first),
              ),
              const SizedBox(height: 16),
              Card(child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${r.rows.length} receipts', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Net sales: ${formatGhs(r.totalNetPesewas)}'),
                  for (final c in r.components)
                    Text('$c: ${formatGhs(r.totalTaxByComponent[c] ?? 0)}'),
                  Text('Grand total: ${formatGhs(r.grandTotalPesewas)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (r.skippedUndecodable > 0)
                    Text('${r.skippedUndecodable} receipt(s) could not be read and were skipped.',
                        style: const TextStyle(color: Colors.orange)),
                ]),
              )),
              const SizedBox(height: 8),
              FilledButton.icon(
                icon: const Icon(Icons.table_chart),
                label: const Text('Export Sales & Tax Report (CSV)'),
                onPressed: () => SharePlus.instance.share(ShareParams(
                    text: taxReportCsv(r, businessName: d.business),
                    subject: 'CA Sales & Tax Report')),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.list_alt),
                label: const Text('Export Item Lines for Accountant (CSV)'),
                onPressed: () {
                  final w = _window;
                  SharePlus.instance.share(ShareParams(
                      text: itemsCsv(d.inputs, from: w.from, to: w.to),
                      subject: 'CA Receipt Items'));
                },
              ),
              const Divider(height: 32),
              const Text('GRA e-VAT readiness',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              const Text('CA is not GRA-certified and does not file taxes. '
                  'This checklist shows how ready your records are for GRA '
                  'e-VAT onboarding (details in the project docs).'),
              const SizedBox(height: 8),
              for (final c in d.checks)
                ListTile(
                  leading: Icon(c.ok ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: c.ok ? const Color(0xFF14532D) : Colors.orange),
                  title: Text(c.label),
                  subtitle: Text(c.ok ? 'Done' : c.hint),
                ),
              SwitchListTile(
                title: const Text('I confirmed the tax rates with my accountant'),
                subtitle: const Text('VAT / NHIL / GETFund presets are defaults until confirmed.'),
                value: _presetsConfirmed,
                onChanged: (v) async {
                  setState(() => _presetsConfirmed = v);
                  await _storage.write(key: 'tax_presets_confirmed', value: v ? 'yes' : 'no');
                },
              ),
            ]);
          },
        ),
      );
}
