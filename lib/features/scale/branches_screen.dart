import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/branches/branch_logic.dart';
import '../../core/db/app_db.dart';
import '../../core/services.dart';
import '../../core/tiers/tiers.dart';

/// Multi-branch management (Phase 7). Receipts are stamped with the active
/// branch's name; analytics can filter per branch. Free plan: 1 branch.
/// Pro: unlimited. The main shop needs no branch entry — receipts issued
/// with no active branch count as 'Main' in analytics.
class BranchesScreen extends StatefulWidget {
  const BranchesScreen({super.key});
  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  List<BranchRow> _branches = [];
  String? _active;
  PlanTier _tier = PlanTier.free;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final b = await AppServices.db.branchList();
    final a = await BranchService.activeBranchName();
    final t = await TierStore.current();
    if (mounted) {
      setState(() {
        _branches = b;
        _active = a;
        _tier = t;
        _loaded = true;
      });
    }
  }

  Future<void> _add() async {
    if (!PlanLimits.canAddBranch(_tier, _branches.length + 1)) {
      // +1 counts the implicit 'Main' shop.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Free plan covers 1 branch. Pro unlocks unlimited branches — see Plans.')));
      return;
    }
    final name = TextEditingController();
    final location = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add branch'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Branch name (e.g. Tarkwa)')),
          TextField(controller: location, decoration: const InputDecoration(labelText: 'Location (optional)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      await AppServices.db.saveBranch(BranchesCompanion.insert(
        id: 'br-${DateTime.now().millisecondsSinceEpoch}',
        name: name.text.trim(),
        location: Value(location.text.trim().isEmpty ? null : location.text.trim()),
        createdAtUnix: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ));
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Branches')),
        floatingActionButton: FloatingActionButton(
          onPressed: _add,
          child: const Icon(Icons.add),
        ),
        body: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : ListView(padding: const EdgeInsets.all(16), children: [
                const Text('Choose which branch this phone is selling from. '
                    'New receipts are stamped with it automatically.'),
                const SizedBox(height: 12),
                RadioGroup<String?>(
                  groupValue: _active,
                  onChanged: (v) async {
                    await BranchService.setActiveBranch(v);
                    _refresh();
                  },
                  child: Column(children: [
                    RadioListTile<String?>(
                      value: null,
                      title: const Text('Main shop'),
                      subtitle: const Text('No branch stamp'),
                    ),
                    for (final b in _branches)
                      RadioListTile<String?>(
                        value: b.name,
                        title: Text(b.name),
                        subtitle: Text(b.location ?? ''),
                        secondary: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await AppServices.db.deleteBranch(b.id);
                            if (_active == b.name) {
                              await BranchService.setActiveBranch(null);
                            }
                            _refresh();
                          },
                        ),
                      ),
                  ]),
                ),
                if (_tier == PlanTier.free)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.workspace_premium),
                      title: const Text('Free plan: main shop + 1 branch'),
                      subtitle: const Text('Pro unlocks unlimited branches.'),
                      trailing: TextButton(
                        child: const Text('Plans'),
                        onPressed: () => context.push('/seller/plans'),
                      ),
                    ),
                  ),
              ]),
      );
}
