import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/app_info.dart';
import '../../core/feedback/feedback_service.dart';
import '../../core/services.dart';
import '../../core/supabase_config.dart';

/// Help & Feedback (Phase 6, pilot prep): offline quick-start guides per
/// mode + a feedback form. Feedback goes to the pilot feedback table when
/// Supabase is set up; otherwise it offers the share sheet so nothing is lost.
class HelpFeedbackScreen extends StatefulWidget {
  const HelpFeedbackScreen({super.key});
  @override
  State<HelpFeedbackScreen> createState() => _HelpFeedbackScreenState();
}

class _HelpFeedbackScreenState extends State<HelpFeedbackScreen> {
  String _category = 'Bug';
  final _message = TextEditingController();
  bool _includeDiagnostics = true;
  bool _sending = false;
  String? _status;

  Future<String> _diagnostics() async {
    final profile = await AppServices.db.getProfile();
    final verification = await AppServices.db.getVerification();
    return FeedbackService.buildDiagnostics(
      mode: profile?.mode ?? 'unknown',
      issued: await AppServices.db.receiptCount('issued'),
      received: await AppServices.db.receiptCount('received'),
      verificationStatus: verification?.status,
      supabaseConfigured: SupabaseConfig.isConfigured,
    );
  }

  Future<void> _send() async {
    if (_message.text.trim().isEmpty) {
      setState(() => _status = 'Write a few words first — what happened or what you wish CA did.');
      return;
    }
    setState(() { _sending = true; _status = null; });
    final profile = await AppServices.db.getProfile();
    final diag = _includeDiagnostics ? await _diagnostics() : '';
    final result = await FeedbackService.send(
      category: _category,
      message: _message.text.trim(),
      diagnostics: diag,
      mode: profile?.mode ?? 'unknown',
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      _status = switch (result) {
        FeedbackResult.sent => 'Thank you — feedback sent to the CA pilot team.',
        FeedbackResult.notConfigured =>
          'No pilot server is connected on this phone yet. Use "Send via share" below so your feedback is not lost.',
        FeedbackResult.failed =>
          'Could not send (are you online?). Use "Send via share" below so your feedback is not lost.',
      };
      if (result == FeedbackResult.sent) _message.clear();
    });
  }

  Future<void> _shareFallback() async {
    final diag = _includeDiagnostics ? await _diagnostics() : '';
    await SharePlus.instance.share(ShareParams(
      subject: 'CA feedback ($_category)',
      text: 'CA feedback — $_category\n\n${_message.text.trim()}\n\n'
          'App: $appBuildLabel\n${diag.isEmpty ? '' : 'Diagnostics: $diag'}',
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Help & Feedback')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          const Text('Quick start', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const ExpansionTile(
            title: Text('Buyers — getting a receipt'),
            children: [ListTile(title: Text(
                '1. First time with a seller, open Scan and scan their Seller Key QR (they show it from their Seller dashboard).\n'
                '2. After paying, scan the receipt QR they show you.\n'
                '3. "Verified ✓" means the receipt is genuine and unchanged. Your receipts live in History — tap one for details or to share it.'))],
          ),
          const ExpansionTile(
            title: Text('Sellers (manual) — issuing'),
            children: [ListTile(title: Text(
                '1. Design your receipt once (name, footer, defaults).\n'
                '2. New Receipt → add items → Issue. Show the buyer the QR.\n'
                '3. MoMo sale? Leave "already received" off and confirm in History when the money lands.\n'
                '4. Back up your signing key (Seller Key screen) — it is your business identity.'))],
          ),
          const ExpansionTile(
            title: Text('Sellers (receipt system) — capturing'),
            children: [ListTile(title: Text(
                '1. Capture Receipt → photograph your printed/POS receipt (best: screenshot on the PC, send it to your phone, pick from gallery).\n'
                '2. Check the items and totals CA read — fix anything wrong.\n'
                '3. Approve → CA issues its signed QR for the buyer.'))],
          ),
          const ExpansionTile(
            title: Text('Verification, sync & printing'),
            children: [ListTile(title: Text(
                '• Business Verification: submit documents once; status (and reviewer notes) appear in the app.\n'
                '• Sync Now (Home) backs up receipts and refreshes verified sellers — selling and scanning always work offline.\n'
                '• Printing: pair a Bluetooth thermal printer in Android Settings, then Print QR Slip on any issued receipt.'))],
          ),
          const Divider(height: 32),
          const Text('Send feedback', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('Bugs, confusing screens, ideas — the pilot team reads every one.'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Type'),
            items: const ['Bug', 'Confusing', 'Idea', 'Other']
                .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _category = v ?? 'Bug'),
          ),
          TextField(controller: _message, maxLines: 4,
              decoration: const InputDecoration(
                  labelText: 'What happened / what do you wish CA did?')),
          SwitchListTile(
            title: const Text('Include a short device summary'),
            subtitle: const Text('Mode, receipt counts, verification status — no receipt contents, no personal data.'),
            value: _includeDiagnostics,
            onChanged: (v) => setState(() => _includeDiagnostics = v),
          ),
          if (_status != null)
            Padding(padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(_status!)),
          FilledButton(
              onPressed: _sending ? null : _send,
              child: Text(_sending ? 'Sending…' : 'Send feedback')),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.share),
            label: const Text('Send via share instead (WhatsApp/email)'),
            onPressed: _shareFallback,
          ),
          const SizedBox(height: 20),
          const Center(child: Text(appBuildLabel, style: TextStyle(color: Colors.grey))),
        ]),
      );
}
