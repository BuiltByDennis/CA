import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/receipt_design.dart';
import '../../core/models.dart';
import '../../core/onboarding/onboarding.dart';
import '../../core/services.dart';

/// "Getting started" checklist card (Phase 6) — shows live progress from
/// the local DB, deep-links each step, hides when complete or dismissed.
class OnboardingCard extends StatefulWidget {
  const OnboardingCard({super.key, required this.mode});
  final UserMode mode;
  @override
  State<OnboardingCard> createState() => _OnboardingCardState();
}

class _OnboardingCardState extends State<OnboardingCard> {
  static const _storage = FlutterSecureStorage();
  List<OnboardingStep>? _steps;
  bool _dismissed = true; // until loaded, show nothing (no flash)

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dismissed =
        await _storage.read(key: 'onboarding_dismissed_${widget.mode.name}') == 'yes';
    final issued = await AppServices.db.issuedReceipts();
    final received = await AppServices.db.receiptCount('received');
    final keys = await AppServices.db.sellerKeyCount();
    final verification = await AppServices.db.getVerification();
    final design = await DesignStore.load();
    final backedUp = await _storage.read(key: 'key_backed_up') == 'yes';
    final facts = OnboardingFacts(
      issuedCount: issued.length,
      capturedCount: issued.where((r) => r.source == 'captured').length,
      receivedCount: received,
      pairedSellerKeys: keys,
      verificationStatus: verification?.status,
      designSaved: design != null,
      keyBackedUp: backedUp,
    );
    if (!mounted) return;
    setState(() {
      _steps = onboardingSteps(widget.mode, facts);
      _dismissed = dismissed || onboardingComplete(widget.mode, facts);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed || _steps == null) return const SizedBox.shrink();
    final done = _steps!.where((s) => s.done).length;
    return Card(
      color: const Color(0xFFEAF3EC),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Text('Getting started',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            Text('$done of ${_steps!.length}'),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Dismiss',
              onPressed: () async {
                await _storage.write(
                    key: 'onboarding_dismissed_${widget.mode.name}', value: 'yes');
                if (mounted) setState(() => _dismissed = true);
              },
            ),
          ]),
          for (final s in _steps!)
            ListTile(
              dense: true,
              leading: Icon(s.done ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: s.done ? const Color(0xFF14532D) : Colors.grey),
              title: Text(s.label,
                  style: TextStyle(
                      decoration: s.done ? TextDecoration.lineThrough : null)),
              trailing: s.done ? null : const Icon(Icons.chevron_right),
              onTap: s.done ? null : () => context.go(s.route),
            ),
        ]),
      ),
    );
  }
}
