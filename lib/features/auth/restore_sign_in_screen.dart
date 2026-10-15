import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/account/account_service.dart';
import '../../core/account/restore_service.dart';
import 'session_service.dart';

/// New-phone restore (Phase 8): sign in with the cloud account, CA pulls
/// the business, history, price list and seller key back down, and the
/// owner sets a fresh PIN for THIS phone. Also used from Settings
/// (merge mode) to pull cloud data onto a phone that already has a
/// local profile.
class RestoreSignInScreen extends StatefulWidget {
  const RestoreSignInScreen({super.key, required this.freshPhone});
  final bool freshPhone;
  @override
  State<RestoreSignInScreen> createState() => _RestoreSignInScreenState();
}

class _RestoreSignInScreenState extends State<RestoreSignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _pin = TextEditingController();
  final _pin2 = TextEditingController();
  String? _error;
  bool _busy = false;

  Future<void> _go() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.length < 6) {
      setState(() => _error = 'Enter your account email and password (6+ characters).');
      return;
    }
    if (widget.freshPhone) {
      if (_pin.text.trim().length < 4 || _pin.text.trim() != _pin2.text.trim()) {
        setState(() => _error = 'Set a PIN for this phone (4+ digits, typed twice the same).');
        return;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final signInError = await AccountService.signIn(email, password);
    if (signInError != null) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = signInError;
        });
      }
      return;
    }
    final report = await RestoreService.restore(password: password);
    if (!mounted) return;
    if (report.error != null) {
      setState(() {
        _busy = false;
        _error = report.error;
      });
      return;
    }
    if (widget.freshPhone) {
      await SessionService.setPin(_pin.text.trim());
      SessionService.accountRevision.value++;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Welcome back'),
        content: Text('Restored: ${report.summary}.'
            '${report.keyFailed ? '\n\nNote: the seller key could not be unlocked with that password — your history is restored, and you can import your CAKEYBACKUP1 file on the Seller Key screen to recover signing.' : ''}'
            '${report.businessFound ? '\n\nYour business and its verification status came back too.' : ''}'),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))],
      ),
    );
    if (!mounted) return;
    if (widget.freshPhone) {
      context.go('/home');
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Sign in & restore')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const Text('Moving to a new phone? Sign in with the cloud account '
              'you created on your old phone and CA brings back your business, '
              'receipt history, My Items price list and seller key.'),
          const SizedBox(height: 16),
          TextField(controller: _email, keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Account email')),
          TextField(controller: _password, obscureText: true,
              decoration: const InputDecoration(labelText: 'Account password')),
          if (widget.freshPhone) ...[
            const SizedBox(height: 16),
            const Text('Set a PIN for THIS phone (each phone keeps its own PIN):',
                style: TextStyle(fontWeight: FontWeight.w600)),
            TextField(controller: _pin, keyboardType: TextInputType.number, obscureText: true,
                decoration: const InputDecoration(labelText: 'New PIN (4+ digits)')),
            TextField(controller: _pin2, keyboardType: TextInputType.number, obscureText: true,
                decoration: const InputDecoration(labelText: 'Repeat the PIN')),
          ],
          if (_error != null)
            Padding(padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 20),
          FilledButton(
              onPressed: _busy ? null : _go,
              child: Text(_busy ? 'Restoring…' : 'Sign in & restore')),
        ]),
      );
}
