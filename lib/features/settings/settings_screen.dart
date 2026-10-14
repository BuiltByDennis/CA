import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services.dart';
import '../../core/supabase_config.dart';
import '../auth/session_service.dart';

/// Settings (fix pack) — account summary and COMPLETE account deletion.
/// Deletion is deliberately multi-step so it can never happen by accident:
///  1. Read exactly what will be erased (and what cannot be pulled back).
///  2. Tick the acknowledgements (sellers: the signing-key warning).
///  3. Re-enter the account PIN.
///  4. Final confirm dialog.
/// Then: best-effort server cleanup (own profile/business/backup rows),
/// full local wipe (database + secure storage), sign-out, back to sign-up.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: FutureBuilder(
          future: AppServices.db.getProfile(),
          builder: (context, snap) {
            final p = snap.data;
            return ListView(padding: const EdgeInsets.all(16), children: [
              const Text('Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (p != null) ...[
                ListTile(leading: const Icon(Icons.person), title: Text(p.name), subtitle: const Text('Name')),
                ListTile(leading: const Icon(Icons.phone), title: Text(p.phone), subtitle: const Text('Phone')),
                ListTile(leading: const Icon(Icons.badge), title: Text(p.mode), subtitle: const Text('Mode')),
                if (p.businessName != null)
                  ListTile(leading: const Icon(Icons.store), title: Text(p.businessName!), subtitle: const Text('Business')),
              ],
              const Divider(height: 32),
              const Text('Danger zone',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
              const SizedBox(height: 8),
              const Text('Deleting your account erases everything on this phone and cannot be undone.'),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const DeleteAccountScreen())),
                child: const Text('Delete my account completely'),
              ),
            ]);
          },
        ),
      );
}

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});
  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _ackErase = false;
  bool _ackKey = false;
  bool _ackServer = false;
  final _pin = TextEditingController();
  bool _deleting = false;
  String? _error;
  bool _isSeller = false;

  @override
  void initState() {
    super.initState();
    AppServices.db.getProfile().then((p) {
      if (mounted) {
        setState(() => _isSeller = (p?.mode ?? 'buyer') != 'buyer');
      }
    });
  }

  bool get _acksDone => _ackErase && _ackServer && (!_isSeller || _ackKey);

  Future<void> _delete() async {
    setState(() { _deleting = true; _error = null; });
    if (!await SessionService.checkPin(_pin.text.trim())) {
      if (mounted) {
        setState(() { _deleting = false; _error = 'That PIN is not correct. Nothing was deleted.'; });
      }
      return;
    }
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete everything, permanently?'),
        content: const Text('This is the last step. Your receipts, business '
            'record, staff, verification and signing key on this phone will '
            'be erased now.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep my account')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete permanently')),
        ],
      ),
    );
    if (confirmed != true) {
      setState(() => _deleting = false);
      return;
    }
    if (!mounted) return;

    // Best-effort server cleanup (own rows only, under RLS).
    var serverNote = 'No server was connected, so only this phone held your data.';
    if (SupabaseConfig.isConfigured) {
      try {
        final client = Supabase.instance.client;
        final uid = client.auth.currentUser?.id;
        if (uid != null) {
          await client.from('receipts_backup').delete().eq('backed_up_by', uid);
          await client.from('businesses').delete().eq('owner_id', uid);
          await client.from('profiles').delete().eq('id', uid);
        }
        await client.auth.signOut();
        serverNote = 'Your profile, business and receipt backups were removed from the server. '
            'Verification documents already submitted for review are retained by the admin for compliance — ask the admin to purge them if you want them gone too.';
      } catch (_) {
        serverNote = 'The server could not be reached, so server copies (if any) may remain — '
            'your phone is fully erased regardless. Contact the admin to purge server data.';
      }
    }

    await AppServices.db.deleteEverything();
    await const FlutterSecureStorage().deleteAll();
    SessionService.lock();
    SessionService.accountRevision.value++;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Account deleted'),
        content: Text('Everything on this phone has been erased.\n\n$serverNote'),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
        ],
      ),
    );
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Delete account')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          const Text('Step 1 — What will be erased',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('• All receipts (issued and received) and their history\n'
              '• Your profile, business record and verification documents on this phone\n'
              '• Staff accounts and their PINs\n'
              '• Paired seller keys and the verified registry cache\n'
              '• Your signing key — receipts you issued can no longer be linked to a key you control\n'
              '• App settings on this phone'),
          const SizedBox(height: 16),
          const Text('Step 2 — Confirm you understand',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          CheckboxListTile(
            value: _ackErase,
            onChanged: (v) => setState(() => _ackErase = v ?? false),
            title: const Text('I understand the receipts and records on this phone will be permanently erased.'),
          ),
          if (_isSeller)
            CheckboxListTile(
              value: _ackKey,
              onChanged: (v) => setState(() => _ackKey = v ?? false),
              title: const Text('I have exported my signing-key backup (Seller Key screen), or I accept losing it forever.'),
            ),
          CheckboxListTile(
            value: _ackServer,
            onChanged: (v) => setState(() => _ackServer = v ?? false),
            title: const Text('I understand verification documents already submitted for review are retained by the admin and removed on request.'),
          ),
          const SizedBox(height: 16),
          const Text('Step 3 — Re-enter your PIN',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          TextField(
            controller: _pin,
            keyboardType: TextInputType.number,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Account PIN'),
          ),
          if (_error != null)
            Padding(padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: (_acksDone && !_deleting) ? _delete : null,
            child: Text(_deleting ? 'Deleting…' : 'Delete my account permanently'),
          ),
        ]),
      );
}
