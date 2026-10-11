import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/db/app_db.dart';
import '../../core/models.dart';
import '../../core/services.dart';
import 'session_service.dart';

/// Gate order: no profile -> create account; profile + locked -> PIN unlock;
/// unlocked -> role picker (which routes to the user's mode dashboard).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<ProfileRow?> _profile = AppServices.db.getProfile();
  @override
  Widget build(BuildContext context) => FutureBuilder<ProfileRow?>(
        future: _profile,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final profile = snap.data;
          if (profile == null) return const CreateAccountScreen();
          if (!SessionService.unlocked) return UnlockScreen(profile: profile);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/home');
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        },
      );
}

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});
  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _pin = TextEditingController();
  final _business = TextEditingController();
  UserMode _mode = UserMode.buyer;
  String? _error;
  bool _busy = false;

  Future<void> _create() async {
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty || _pin.text.trim().length < 4) {
      setState(() => _error = 'Enter your name, phone, and a PIN of at least 4 digits.');
      return;
    }
    if (_mode != UserMode.buyer && _business.text.trim().isEmpty) {
      setState(() => _error = 'Sellers: enter your business name (you will register it fully for verification).');
      return;
    }
    setState(() => _busy = true);
    final businessId = _mode == UserMode.buyer
        ? null
        : 'biz-${_phone.text.trim().replaceAll(RegExp(r'\D'), '')}';
    await SessionService.setPin(_pin.text.trim());
    await AppServices.db.saveProfile(ProfilesCompanion.insert(
      id: 'me',
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      mode: _mode.name,
      businessName: Value(_mode == UserMode.buyer ? null : _business.text.trim()),
      businessId: Value(businessId),
    ));
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('CA — Create your account')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const Text('One account for buying and selling. Works fully offline — '
              'your PIN opens the app, no internet needed.'),
          const SizedBox(height: 16),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Your name')),
          TextField(controller: _phone, keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number')),
          TextField(controller: _pin, keyboardType: TextInputType.number, obscureText: true,
              decoration: const InputDecoration(labelText: 'PIN (4+ digits)')),
          const SizedBox(height: 16),
          DropdownButtonFormField<UserMode>(
            initialValue: _mode,
            decoration: const InputDecoration(labelText: 'I am joining as'),
            items: UserMode.values
                .map((m) => DropdownMenuItem(value: m, child: Text(m.label)))
                .toList(),
            onChanged: (m) => setState(() => _mode = m ?? UserMode.buyer),
          ),
          if (_mode != UserMode.buyer)
            TextField(controller: _business,
                decoration: const InputDecoration(labelText: 'Business name')),
          if (_error != null)
            Padding(padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 20),
          FilledButton(
              onPressed: _busy ? null : _create,
              child: const Text('Create account')),
        ]),
      );
}

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key, required this.profile});
  final ProfileRow profile;
  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final _pin = TextEditingController();
  String? _error;
  Future<void> _unlock() async {
    if (await SessionService.tryUnlock(_pin.text.trim())) {
      if (mounted) context.go('/home');
    } else {
      setState(() => _error = 'Wrong PIN. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Welcome back')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Text('Hello, ${widget.profile.name}', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          TextField(controller: _pin, keyboardType: TextInputType.number, obscureText: true,
              decoration: const InputDecoration(labelText: 'Enter your PIN'),
              onSubmitted: (_) => _unlock()),
          if (_error != null)
            Padding(padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 20),
          FilledButton(onPressed: _unlock, child: const Text('Open CA')),
        ]),
      );
}
