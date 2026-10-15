import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/referral/referral.dart';
import '../../core/services.dart';

/// Referral program (Phase 7): every seller has a stable code (from their
/// business ID). New sellers can enter it on their verification form;
/// the count of businesses that joined with your code syncs down here.
class ReferralsScreen extends StatelessWidget {
  const ReferralsScreen({super.key});

  Future<({String code, int count})> _load() async {
    final p = await AppServices.db.getProfile();
    final code = referralCodeFor(p?.businessId ?? p?.phone ?? 'me');
    final raw = await const FlutterSecureStorage().read(key: 'referral_count');
    return (code: code, count: int.tryParse(raw ?? '') ?? 0);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Refer & Grow')),
        body: FutureBuilder(
          future: _load(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final d = snap.data!;
            return ListView(padding: const EdgeInsets.all(20), children: [
              const Icon(Icons.group_add, size: 56, color: Color(0xFF14532D)),
              const SizedBox(height: 12),
              const Text('Invite other sellers to CA',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('When a seller joins and enters your code on their '
                  'Business Verification form, they count as your referral.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    const Text('YOUR CODE', style: TextStyle(letterSpacing: 2, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(d.code,
                        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('Share my code'),
                onPressed: () => SharePlus.instance.share(ShareParams(
                    text: 'I use CA to issue signed e-receipts that work offline. '
                        'Join with my referral code ${d.code} — enter it on your '
                        'Business Verification form in the CA app.')),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.people),
                title: Text('${d.count}'),
                subtitle: const Text('Sellers joined with your code (updates on Sync)'),
              ),
            ]);
          },
        ),
      );
}
