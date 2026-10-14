import 'package:flutter/material.dart';
import '../../core/analytics/analytics.dart';
import '../../core/models.dart';
import '../../core/services.dart';
import '../../core/staff/staff_logic.dart' as staff_logic;
import '../auth/session_service.dart';

/// Seller analytics (Phase 4) — computed fully offline from local receipts.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _days = 7;
  late final Future<List<AnalyticsReceipt>> _data = _load();

  Future<List<AnalyticsReceipt>> _load() async {
    final receipts = await AppServices.db.issuedReceipts();
    final items = await AppServices.db.allReceiptItems();
    final byReceipt = <String, List<({String name, int qty, int amountPesewas})>>{};
    for (final i in items) {
      byReceipt.putIfAbsent(i.receiptId, () => []).add((
        name: i.name,
        qty: i.qty,
        amountPesewas: i.qty * i.unitPricePesewas,
      ));
    }
    return receipts
        .map((r) => AnalyticsReceipt(
              totalPesewas: r.totalPesewas,
              issuedAt: DateTime.fromMillisecondsSinceEpoch(r.issuedAtUnix * 1000),
              buyerName: r.buyerName,
              paymentMethod: r.paymentMethod,
              cashierName: r.cashierName,
              items: byReceipt[r.id] ?? const [],
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!staff_logic.canViewAnalytics(SessionService.currentRole)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analytics')),
        body: const Center(child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Analytics is for the owner, manager, and accountant. '
              'Cashiers can issue receipts and view history.'),
        )),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Sales Analytics')),
      body: FutureBuilder<List<AnalyticsReceipt>>(
        future: _data,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final s = summarize(snap.data!, now: DateTime.now(), days: _days);
          final maxDaily = s.dailyTotals.fold(0, (m, d) => d.totalPesewas > m ? d.totalPesewas : m);
          return ListView(padding: const EdgeInsets.all(16), children: [
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('Today')),
                ButtonSegment(value: 7, label: Text('7 days')),
                ButtonSegment(value: 30, label: Text('30 days')),
                ButtonSegment(value: 36500, label: Text('All')),
              ],
              selected: {_days},
              onSelectionChanged: (v) => setState(() => _days = v.first),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _stat('Total sales', formatGhs(s.totalPesewas))),
              Expanded(child: _stat('Receipts', '${s.receiptCount}')),
              Expanded(child: _stat('Average sale', formatGhs(s.averageBasketPesewas))),
            ]),
            const Divider(height: 32),
            const Text('Daily sales', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 90,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                for (final d in s.dailyTotals)
                  Expanded(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Container(
                      height: maxDaily == 0 ? 2 : 6 + 80 * (d.totalPesewas / maxDaily),
                      color: const Color(0xFF14532D),
                    ),
                  )),
              ]),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${s.dailyTotals.first.day.day}/${s.dailyTotals.first.day.month}'),
              Text('${s.dailyTotals.last.day.day}/${s.dailyTotals.last.day.month}'),
            ]),
            const Divider(height: 32),
            const Text('Top items (by quantity)', style: TextStyle(fontWeight: FontWeight.bold)),
            if (s.topItemsByQty.isEmpty) const Text('No items yet in this period.'),
            for (final i in s.topItemsByQty)
              ListTile(title: Text(i.name), trailing: Text('× ${i.qty}')),
            const Text('Top items (by revenue)', style: TextStyle(fontWeight: FontWeight.bold)),
            for (final i in s.topItemsByRevenue)
              ListTile(title: Text(i.name), trailing: Text(formatGhs(i.amountPesewas))),
            const Text('Top buyers', style: TextStyle(fontWeight: FontWeight.bold)),
            for (final b in s.topBuyers)
              ListTile(title: Text(b.name),
                  subtitle: Text('${b.receipts} receipt(s)'),
                  trailing: Text(formatGhs(b.amountPesewas))),
            const Text('By payment method', style: TextStyle(fontWeight: FontWeight.bold)),
            for (final e in s.paymentSplit.entries)
              ListTile(title: Text(e.key), trailing: Text(formatGhs(e.value))),
            const Text('By cashier / staff', style: TextStyle(fontWeight: FontWeight.bold)),
            for (final c in s.cashierTotals)
              ListTile(title: Text(c.name),
                  subtitle: Text('${c.receipts} receipt(s)'),
                  trailing: Text(formatGhs(c.amountPesewas))),
          ]);
        },
      ),
    );
  }

  Widget _stat(String label, String value) => Card(child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: const TextStyle(fontSize: 12)),
        ]),
      ));
}
