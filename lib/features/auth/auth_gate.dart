import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/db/app_db.dart';
import '../../core/models.dart';
import '../../core/services.dart';
import '../../core/staff/staff_logic.dart' as staff_logic;
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
          if (!SessionService.unlocked) return PersonPickerScreen(profile: profile);
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

class PersonPickerScreen extends StatelessWidget {
  const PersonPickerScreen({super.key, required this.profile});
  final ProfileRow profile;

  void _openPin(BuildContext context, String label, Future<bool> Function(String) verify) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PinEntryScreen(label: label, verify: verify)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Who is using CA?')),
        body: FutureBuilder<List<StaffMemberRow>>(
          future: AppServices.db.staffList(),
          builder: (context, snap) {
            final staff = (snap.data ?? const <StaffMemberRow>[])
                .where((s) => s.active)
                .toList();
            return ListView(padding: const EdgeInsets.all(20), children: [
              Text('Hello — tap your name and enter your PIN.',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Card(child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(profile.name),
                subtitle: const Text('Owner'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openPin(context, profile.name, SessionService.tryUnlock),
              )),
              for (final s in staff)
                Card(child: ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: Text(s.name),
                  subtitle: Text(staff_logic.roleLabel(s.role)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openPin(context, s.name, (pin) async {
                    final ok = await staff_logic.verifyPin(pin, s.pinSalt, s.pinHash);
                    if (ok) SessionService.unlockAsStaff(s.name, s.role);
                    return ok;
                  }),
                )),
            ]);
          },
        ),
      );
}

class PinEntryScreen extends StatefulWidget {
  const PinEntryScreen({super.key, required this.label, required this.verify});
  final String label;
  final Future<bool> Function(String) verify;
  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  final _pin = TextEditingController();
  String? _error;
  Future<void> _go() async {
    if (await widget.verify(_pin.text.trim())) {
      if (mounted) context.go('/home');
    } else {
      setState(() => _error = 'Wrong PIN. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.label)),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          TextField(controller: _pin, keyboardType: TextInputType.number,
              obscureText: true, autofocus: true,
              decoration: const InputDecoration(labelText: 'Enter your PIN'),
              onSubmitted: (_) => _go()),
          if (_error != null)
            Padding(padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 20),
          FilledButton(onPressed: _go, child: const Text('Open CA')),
        ]),
      );
}
