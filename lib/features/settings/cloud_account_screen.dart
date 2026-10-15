import 'package:flutter/material.dart';
import '../../core/account/account_service.dart';
import '../../core/account/restore_service.dart';
import '../../core/sync/sync_service.dart';
import '../auth/restore_sign_in_screen.dart';

/// Cloud Account (Phase 8): link this phone to an email + password
/// account so the owner's data survives a lost/replaced phone, and
/// manage that link. Selling never needs this — it is backup/restore
/// identity only.
class CloudAccountScreen extends StatefulWidget {
  const CloudAccountScreen({super.key});
  @override
  State<CloudAccountScreen> createState() => _CloudAccountScreenState();
}

class _CloudAccountScreenState extends State<CloudAccountScreen> {
  CloudAccountState? _state;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _message;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await AccountService.state();
    if (mounted) setState(() => _state = s);
  }

  Future<void> _create() async {
    if (_password.text.length < 6) {
      setState(() => _message = 'Password must be at least 6 characters.');
      return;
    }
    if (_password.text != _confirm.text) {
      setState(() => _message = 'Passwords do not match.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    final result = await AccountService.createAccount(_email.text.trim(), _password.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = result ?? 'Cloud account created. Your backups now belong to this account — sign in with it on any new phone to restore everything.';
    });
    _load();
  }

  Future<String?> _askPassword(String title) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(controller: ctrl, obscureText: true,
            decoration: const InputDecoration(labelText: 'Account password')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continue')),
        ],
      ),
    );
    return ok == true ? ctrl.text : null;
  }

  @override
  Widget build(BuildContext context) {
    final s = _state;
    return Scaffold(
      appBar: AppBar(title: const Text('Cloud Account')),
      body: s == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              const Text('Your CA lives on this phone. A cloud account lets you '
                  'move to a new phone without losing your business, receipt '
                  'history, price list or seller key — sign in there and '
                  'everything comes back. Backups upload when you Sync.'),
              const SizedBox(height: 16),
              if (!s.configured)
                const Text('Supabase is not configured on this build, so cloud '
                    'accounts are unavailable. Everything still works offline.')
              else if (s.signedOut) ...[
                const Text('You are signed out of your cloud account.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const RestoreSignInScreen(freshPhone: false))),
                  child: const Text('Sign in & restore'),
                ),
              ] else if (s.anonymous) ...[
                const Text('Create your account',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                TextField(controller: _email, keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email')),
                TextField(controller: _password, obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password (6+ characters)')),
                TextField(controller: _confirm, obscureText: true,
                    decoration: const InputDecoration(labelText: 'Repeat password')),
                if (_message != null)
                  Padding(padding: const EdgeInsets.only(top: 12), child: Text(_message!)),
                const SizedBox(height: 16),
                FilledButton(
                    onPressed: _busy ? null : _create,
                    child: const Text('Create cloud account')),
                const Divider(height: 32),
                const Text('Already created one on another phone?'),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const RestoreSignInScreen(freshPhone: false))),
                  child: const Text('Sign in & restore instead'),
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.cloud_done),
                  title: Text(s.email ?? 'Cloud account'),
                  subtitle: const Text('Backups belong to this account'),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.sync),
                  label: const Text('Sync now (back up)'),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final r = await SyncService.syncNow();
                    messenger.showSnackBar(SnackBar(content: Text(r.message)));
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.key),
                  label: const Text('Update seller key backup'),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final pw = await _askPassword('Back up seller key');
                    if (pw == null) return;
                    final err = await AccountService.refreshKeyBackup(pw);
                    messenger.showSnackBar(SnackBar(
                        content: Text(err ?? 'Seller key backup updated.')));
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Restore from cloud'),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final pw = await _askPassword('Restore from cloud');
                    if (pw == null) return;
                    final report = await RestoreService.restore(password: pw);
                    messenger.showSnackBar(SnackBar(
                        content: Text(report.error ??
                            'Restored: ${report.summary}.')));
                  },
                ),
                const Divider(height: 32),
                TextButton(
                  onPressed: () async {
                    await AccountService.signOut();
                    _load();
                  },
                  child: const Text('Sign out of cloud account'),
                ),
                const Text('Signing out never deletes anything on this phone. '
                    'Sync pauses until you sign in again.',
                    style: TextStyle(fontSize: 12)),
              ],
            ]),
    );
  }
}
