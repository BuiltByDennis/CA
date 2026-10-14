import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import '../../core/db/app_db.dart';
import '../../core/services.dart';
import '../../core/staff/staff_logic.dart' as staff_logic;
import '../auth/session_service.dart';

/// Staff management (Phase 4) — owner only. Add people who work on this
/// device under the business, each with a role and their own PIN. Every
/// receipt they issue is stamped with their name.
class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});
  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  List<StaffMemberRow> _staff = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _staff = await AppServices.db.staffList();
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _add() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final pin = TextEditingController();
    var role = staff_logic.roleCashier;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add staff member'),
        content: StatefulBuilder(builder: (context, setLocal) {
          return Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: phone, keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone (optional)')),
            TextField(controller: pin, keyboardType: TextInputType.number, obscureText: true,
                decoration: const InputDecoration(labelText: 'Their PIN (4+ digits)')),
            DropdownButton<String>(
              value: role,
              items: const [
                DropdownMenuItem(value: staff_logic.roleManager, child: Text('Manager')),
                DropdownMenuItem(value: staff_logic.roleCashier, child: Text('Cashier')),
                DropdownMenuItem(value: staff_logic.roleAccountant, child: Text('Accountant')),
              ],
              onChanged: (v) => setLocal(() => role = v ?? staff_logic.roleCashier),
            ),
            const Text('Manager: issue, capture, analytics, verification. '
                'Cashier: issue, capture, history. '
                'Accountant: analytics and history only.',
                style: TextStyle(fontSize: 12)),
          ]);
        }),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    );
    if (ok != true) return;
    if (name.text.trim().isEmpty || pin.text.trim().length < 4) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Name and a PIN of at least 4 digits are required.')));
      }
      return;
    }
    final salt = staff_logic.newPinSalt();
    await AppServices.db.saveStaff(StaffMembersCompanion.insert(
      id: 'staff-${DateTime.now().millisecondsSinceEpoch}',
      name: name.text.trim(),
      phone: Value(phone.text.trim().isEmpty ? null : phone.text.trim()),
      role: role,
      pinSalt: salt,
      pinHash: await staff_logic.hashPin(pin.text.trim(), salt),
      createdAtUnix: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    ));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (!staff_logic.canManageStaff(SessionService.currentRole)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Staff')),
        body: const Center(child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Only the business owner can manage staff. '
              'You are signed in with a staff role.'),
        )),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Staff')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add, icon: const Icon(Icons.person_add), label: const Text('Add staff')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : _staff.isEmpty
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No staff yet. Add cashiers, a manager, or an '
                      'accountant — each signs in with their own PIN and '
                      'their receipts are stamped with their name.'),
                ))
              : ListView(children: [
                  for (final s in _staff)
                    ListTile(
                      leading: const Icon(Icons.badge_outlined),
                      title: Text(s.name),
                      subtitle: Text('${staff_logic.roleLabel(s.role)}'
                          '${s.active ? '' : ' · deactivated'}'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Switch(
                          value: s.active,
                          onChanged: (v) async {
                            await AppServices.db.setStaffActive(s.id, v);
                            await _load();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await AppServices.db.deleteStaff(s.id);
                            await _load();
                          },
                        ),
                      ]),
                    ),
                ]),
    );
  }
}
