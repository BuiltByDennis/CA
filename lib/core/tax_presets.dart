/// Ghana tax presets — CONFIG, never hard-coded logic (plan principle 5).
///
/// ⚠️ VERIFY BEFORE PRODUCTION: rates/structure must be confirmed against the
/// current GRA rules (post-2026 reform) with an accountant. Sellers can toggle
/// these off; Phase 4 moves this into an editable in-app Tax Settings screen.
/// For Phase 1 the presets are simple % lines on the subtotal — real VAT
/// treatment (input/output, flat-rate schemes) is more complex than this.
class TaxPreset {
  const TaxPreset(this.name, this.ratePercent);
  final String name;
  final double ratePercent;
}

const taxPresets = <TaxPreset>[
  TaxPreset('VAT', 15),
  TaxPreset('NHIL', 2.5),
  TaxPreset('GETFund', 2.5),
];

/// Common items for one-tap add for manual sellers (they should not retype).
const favouriteItemNames = <String>[
  'Tomatoes', 'Onions', 'Rice (5kg)', 'Maize', 'Yam', 'Plantain',
  'Cement (bag)', 'Iron rods', 'Exercise books', 'Paracetamol',
];
