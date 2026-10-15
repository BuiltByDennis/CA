import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services.dart';
import '../../core/supabase_config.dart';
import '../../core/tiers/tiers.dart';

/// Paid tiers (Phase 7). Free keeps the full pilot product — issuing and
/// scanning are NEVER gated (a sale must work offline, always). Pro is for
/// scale: unlimited branches and staff. Activation: the seller requests
/// Pro here; the request lands in the subscriptions table, and the admin
/// activates it once payment is confirmed (payment-link integration is
/// the final step, pending provider keys). Tier syncs down on Sync Now.
class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});
  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  PlanTier _tier = PlanTier.free;
  String? _note;

  @override
  void initState() {
    super.initState();
    TierStore.current().then((t) {
      if (mounted) setState(() => _tier = t);
    });
  }

  Future<void> _requestPro() async {
    if (!SupabaseConfig.isConfigured) {
      setState(() => _note = 'Connect the app first (Sync Now), then request Pro.');
      return;
    }
    final profile = await AppServices.db.getProfile();
    final caId = profile?.businessId;
    if (caId == null) {
      setState(() => _note = 'Set up your business first.');
      return;
    }
    try {
      final client = Supabase.instance.client;
      if (client.auth.currentUser == null) {
        await client.auth.signInAnonymously();
      }
      await client.from('subscriptions').upsert({
        'ca_business_id': caId,
        'plan': 'pro',
        'status': 'requested',
      }, onConflict: 'ca_business_id');
      setState(() => _note = 'Pro requested. The CA team will confirm payment '
          'and activate it — then tap Sync Now and your plan updates here.');
    } catch (e) {
      setState(() => _note = 'Request failed: $e');
    }
  }

  Widget _card(String name, String price, List<String> features, bool current, VoidCallback? cta, String ctaLabel) =>
      Card(
        color: current ? Colors.green.shade50 : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            for (final f in features)
              Padding(padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(children: [const Icon(Icons.check, size: 18), const SizedBox(width: 6), Expanded(child: Text(f))])),
            const SizedBox(height: 8),
            if (current)
              const Chip(label: Text('Your current plan'))
            else if (cta != null)
              FilledButton(onPressed: cta, child: Text(ctaLabel)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Plans')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          _card('Free', 'GH₵0', const [
            'Issue & scan receipts — unlimited, fully offline',
            'OCR capture, analytics, tax reports, printing',
            'Main shop + 1 branch · up to 3 staff',
          ], _tier == PlanTier.free, null, ''),
          const SizedBox(height: 12),
          _card('Pro', 'For growing businesses', const [
            'Everything in Free',
            'Unlimited branches',
            'Unlimited staff',
            'Priority support',
          ], _tier == PlanTier.pro, _tier == PlanTier.free ? _requestPro : null, 'Request Pro'),
          if (_note != null)
            Padding(padding: const EdgeInsets.only(top: 12), child: Text(_note!)),
          const SizedBox(height: 12),
          const Text('Your plan is set by the CA team and reaches this phone on '
              'Sync Now. Selling never stops because of a plan — CA receipts '
              'always work offline.',
              style: TextStyle(color: Colors.grey)),
        ]),
      );
}
