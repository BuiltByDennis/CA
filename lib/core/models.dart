enum UserMode { buyer, sellerIntegrated, sellerManual }

extension UserModeX on UserMode {
  String get label => switch (this) {
        UserMode.buyer => 'Buyer',
        UserMode.sellerIntegrated => 'Seller — has a receipt system',
        UserMode.sellerManual => 'Seller — manual receipts',
      };
  String get dashboardRoute => switch (this) {
        UserMode.buyer => '/buyer',
        UserMode.sellerIntegrated => '/seller-integrated',
        UserMode.sellerManual => '/seller-manual',
      };
}

enum VerificationStatus { unverified, pending, verified, rejected }

/// Money is ALWAYS integer pesewas (GH₵1 = 100). Never doubles for money.
class ReceiptItem {
  const ReceiptItem({required this.name, required this.qty, required this.unitPricePesewas});
  final String name;
  final int qty;
  final int unitPricePesewas;
  int get amountPesewas => qty * unitPricePesewas;
  Map<String, Object?> toJson() => {'n': name, 'q': qty, 'p': unitPricePesewas};
  static ReceiptItem fromJson(Map<String, dynamic> j) => ReceiptItem(
      name: j['n'] as String, qty: j['q'] as int, unitPricePesewas: j['p'] as int);
}

class TaxLine {
  const TaxLine({required this.name, required this.ratePercent, required this.amountPesewas});
  final String name; final double ratePercent; final int amountPesewas;
  Map<String, Object?> toJson() => {'n': name, 'r': ratePercent, 'a': amountPesewas};
}

class Receipt {
  const Receipt({
    required this.id, required this.receiptNo, required this.sellerBusinessId,
    required this.sellerName, required this.items, required this.taxLines,
    required this.totalPesewas, required this.issuedAt, required this.source,
    this.buyerName, this.paymentMethod = 'Cash', this.currency = 'GHS',
  });
  final String id; final String receiptNo; final String sellerBusinessId;
  final String sellerName; final String? buyerName;
  final List<ReceiptItem> items; final List<TaxLine> taxLines;
  final int totalPesewas; final DateTime issuedAt; final String source;
  final String paymentMethod; final String currency;
  int get subtotalPesewas => items.fold(0, (s, i) => s + i.amountPesewas);
  int get taxPesewas => taxLines.fold(0, (s, t) => s + t.amountPesewas);

  /// Canonical payload for signing — QR Payload Spec v1 (docs/QR_PAYLOAD_SPEC_V1.md).
  /// Keys are short to keep the QR small; field order here is the canonical order.
  Map<String, Object?> toPayload() => {
        'v': 1, 'id': id, 'no': receiptNo, 'sid': sellerBusinessId, 'sn': sellerName,
        if (buyerName != null) 'bn': buyerName,
        'it': items.map((e) => e.toJson()).toList(),
        'tx': taxLines.map((e) => e.toJson()).toList(),
        'tot': totalPesewas, 'cur': currency, 'pm': paymentMethod,
        'ts': issuedAt.toUtc().millisecondsSinceEpoch ~/ 1000, 'src': source,
      };

  static Receipt sample() {
    const items = [
      ReceiptItem(name: 'Tomatoes (basket)', qty: 2, unitPricePesewas: 5000),
      ReceiptItem(name: 'Onions (bag)', qty: 1, unitPricePesewas: 12000),
    ];
    return Receipt(
      id: 'demo-0001', receiptNo: 'CA-2026-0001', sellerBusinessId: 'biz-demo',
      sellerName: 'CA Demo Farms', buyerName: 'Demo Buyer', items: items,
      taxLines: const [], totalPesewas: 22000,
      issuedAt: DateTime.now().toUtc(), source: 'manual',
    );
  }
}

class Business {
  const Business({required this.id, required this.name, required this.mode, required this.verification});
  final String id; final String name; final UserMode mode; final VerificationStatus verification;
}

String formatGhs(int pesewas) => 'GH₵ ${(pesewas / 100).toStringAsFixed(2)}';
