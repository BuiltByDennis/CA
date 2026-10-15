// Seller analytics (Phase 4) — pure aggregation over local receipts.
// Everything is computed on-device from the Drift data; no network.
// Inputs are plain records so this is fully unit-testable.

class AnalyticsReceipt {
  const AnalyticsReceipt({
    required this.totalPesewas,
    required this.issuedAt,
    required this.buyerName,
    required this.paymentMethod,
    required this.cashierName,
    required this.items,
    this.branchName,
  });
  final int totalPesewas;
  final DateTime issuedAt; // local time
  final String? buyerName;
  final String paymentMethod;
  final String? cashierName;
  final String? branchName; // Phase 7
  final List<({String name, int qty, int amountPesewas})> items;
}

class AnalyticsSummary {
  const AnalyticsSummary({
    required this.totalPesewas,
    required this.receiptCount,
    required this.topItemsByQty,
    required this.topItemsByRevenue,
    required this.topBuyers,
    required this.dailyTotals,
    required this.paymentSplit,
    required this.cashierTotals,
  });
  final int totalPesewas;
  final int receiptCount;
  int get averageBasketPesewas =>
      receiptCount == 0 ? 0 : (totalPesewas / receiptCount).round();
  final List<({String name, int qty})> topItemsByQty;
  final List<({String name, int amountPesewas})> topItemsByRevenue;
  final List<({String name, int amountPesewas, int receipts})> topBuyers;
  final List<({DateTime day, int totalPesewas})> dailyTotals;
  final Map<String, int> paymentSplit;
  final List<({String name, int amountPesewas, int receipts})> cashierTotals;
}

AnalyticsSummary summarize(
  List<AnalyticsReceipt> receipts, {
  required DateTime now,
  required int days, // window: 1 (today), 7, 30, or 36500 (~all)
  int topN = 5,
}) {
  final startOfToday = DateTime(now.year, now.month, now.day);
  final windowStart = days <= 1
      ? startOfToday
      : startOfToday.subtract(Duration(days: days - 1));
  final inWindow = receipts
      .where((r) => !r.issuedAt.isBefore(windowStart) && !r.issuedAt.isAfter(now))
      .toList();

  var total = 0;
  final byQty = <String, int>{};
  final byRevenue = <String, int>{};
  final buyers = <String, ({int amount, int count})>{};
  final daily = <DateTime, int>{};
  final payments = <String, int>{};
  final cashiers = <String, ({int amount, int count})>{};

  for (final r in inWindow) {
    total += r.totalPesewas;
    final day = DateTime(r.issuedAt.year, r.issuedAt.month, r.issuedAt.day);
    daily[day] = (daily[day] ?? 0) + r.totalPesewas;
    payments[r.paymentMethod] = (payments[r.paymentMethod] ?? 0) + r.totalPesewas;
    final buyer = r.buyerName ?? 'Walk-in buyer';
    final b = buyers[buyer];
    buyers[buyer] = (amount: (b?.amount ?? 0) + r.totalPesewas, count: (b?.count ?? 0) + 1);
    final cashier = r.cashierName ?? 'Owner';
    final c = cashiers[cashier];
    cashiers[cashier] = (amount: (c?.amount ?? 0) + r.totalPesewas, count: (c?.count ?? 0) + 1);
    for (final i in r.items) {
      byQty[i.name] = (byQty[i.name] ?? 0) + i.qty;
      byRevenue[i.name] = (byRevenue[i.name] ?? 0) + i.amountPesewas;
    }
  }

  List<T> top<T>(Iterable<T> xs, int Function(T) key) {
    final list = xs.toList()..sort((a, b) => key(b).compareTo(key(a)));
    return list.take(topN).toList();
  }

  final dailyList = <({DateTime day, int totalPesewas})>[];
  final chartDays = days <= 1 ? 1 : (days > 30 ? 30 : days);
  for (var i = chartDays - 1; i >= 0; i--) {
    final d = startOfToday.subtract(Duration(days: i));
    dailyList.add((day: d, totalPesewas: daily[d] ?? 0));
  }

  return AnalyticsSummary(
    totalPesewas: total,
    receiptCount: inWindow.length,
    topItemsByQty: top(
        byQty.entries.map((e) => (name: e.key, qty: e.value)), (e) => e.qty),
    topItemsByRevenue: top(
        byRevenue.entries.map((e) => (name: e.key, amountPesewas: e.value)),
        (e) => e.amountPesewas),
    topBuyers: top(
        buyers.entries.map((e) => (
              name: e.key,
              amountPesewas: e.value.amount,
              receipts: e.value.count
            )),
        (e) => e.amountPesewas),
    dailyTotals: dailyList,
    paymentSplit: payments,
    cashierTotals: top(
        cashiers.entries.map((e) => (
              name: e.key,
              amountPesewas: e.value.amount,
              receipts: e.value.count
            )),
        (e) => e.amountPesewas),
  );
}
