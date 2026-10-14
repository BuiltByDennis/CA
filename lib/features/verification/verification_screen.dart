import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../core/db/app_db.dart';
import '../../core/services.dart';
import '../../core/sync/sync_service.dart';
import '../../core/verification/verification_logic.dart';

/// Business Verification (Phase 3).
/// Local-first: the form + document photos live on this phone. Submitting
/// marks the record Pending and queues everything; Sync (here or on Home)
/// sends it to Supabase when online, where an admin reviews it.
/// The Ghana Card NUMBER field never leaves this device.
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});
  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _legal = TextEditingController();
  final _trading = TextEditingController();
  final _orc = TextEditingController();
  final _tin = TextEditingController();
  final _address = TextEditingController();
  final _category = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _ghanaCard = TextEditingController();
  String _type = 'sole_prop';
  bool _vat = false;
  String _status = 'unverified';
  String? _note;
  List<VerificationDocRow> _docs = [];
  bool _loaded = false;
  bool _busy = false;
  final _picker = ImagePicker();

  static const _docLabels = {
    'orc_certificate': 'ORC Certificate',
    'tin_certificate': 'TIN Certificate',
    'ghana_card': 'Ghana Card (photo)',
    'business_permit': 'Business Permit',
    'other': 'Other Document',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await AppServices.db.getVerification();
    final profile = await AppServices.db.getProfile();
    if (v != null) {
      _legal.text = v.legalName;
      _trading.text = v.tradingName;
      _orc.text = v.orcNumber ?? '';
      _tin.text = v.tin ?? '';
      _address.text = v.address ?? '';
      _category.text = v.category ?? '';
      _phone.text = v.contactPhone ?? '';
      _email.text = v.contactEmail ?? '';
      _ghanaCard.text = v.ghanaCardNo ?? '';
      _type = v.businessType;
      _vat = v.vatRegistered;
      _status = v.status;
      _note = v.note;
    } else {
      _trading.text = profile?.businessName ?? '';
      _legal.text = profile?.businessName ?? '';
      _phone.text = profile?.phone ?? '';
    }
    _docs = await AppServices.db.verificationDocsList();
    if (mounted) setState(() => _loaded = true);
  }

  VerificationForm get _form => VerificationForm(
        legalName: _legal.text,
        tradingName: _trading.text,
        businessType: _type,
        orcNumber: _orc.text,
        tin: _tin.text,
        vatRegistered: _vat,
        address: _address.text,
        category: _category.text,
        contactPhone: _phone.text,
        contactEmail: _email.text,
        ghanaCardNo: _ghanaCard.text,
        docTypes: _docs.map((d) => d.docType).toSet().toList(),
      );

  Future<void> _save({required bool submit}) async {
    if (submit) {
      final errors = validateVerification(_form);
      if (errors.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errors.first)));
        return;
      }
    }
    await AppServices.db.saveVerification(BusinessVerificationCompanion.insert(
      id: 'me',
      legalName: _legal.text.trim(),
      tradingName: _trading.text.trim(),
      businessType: _type,
      orcNumber: Value(_orc.text.trim().isEmpty ? null : _orc.text.trim()),
      tin: Value(_tin.text.trim().isEmpty ? null : _tin.text.trim()),
      vatRegistered: Value(_vat),
      address: Value(_address.text.trim().isEmpty ? null : _address.text.trim()),
      category: Value(_category.text.trim().isEmpty ? null : _category.text.trim()),
      contactPhone: Value(_phone.text.trim().isEmpty ? null : _phone.text.trim()),
      contactEmail: Value(_email.text.trim().isEmpty ? null : _email.text.trim()),
      ghanaCardNo:
          Value(_ghanaCard.text.trim().isEmpty ? null : _ghanaCard.text.trim()),
      status: Value(submit ? 'pending' : _status),
      submittedAtUnix: Value(submit
          ? DateTime.now().millisecondsSinceEpoch ~/ 1000
          : null),
    ));
    if (submit) setState(() => _status = 'pending');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(submit
            ? 'Submitted on this phone as Pending. Tap Sync Now (internet needed) to send it for review.'
            : 'Saved on this phone.')));
  }

  Future<void> _addDoc(String docType) async {
    final XFile? file;
    try {
      file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    } catch (_) {
      return;
    }
    if (file == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final docsDir = Directory(p.join(dir.path, 'verification_docs'));
    await docsDir.create(recursive: true);
    final dest = p.join(docsDir.path,
        '${docType}_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await File(file.path).copy(dest);
    await AppServices.db.addVerificationDoc(docType, dest);
    _docs = await AppServices.db.verificationDocsList();
    if (mounted) setState(() {});
  }

  Future<void> _sync() async {
    setState(() => _busy = true);
    final report = await SyncService.syncNow();
    await _load();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(report.message)));
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final editable = _status != 'verified';
    return Scaffold(
      appBar: AppBar(title: const Text('Business Verification')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          color: _status == 'verified'
              ? Colors.green.shade50
              : _status == 'rejected'
                  ? Colors.red.shade50
                  : Colors.amber.shade50,
          child: ListTile(
            leading: Icon(_status == 'verified'
                ? Icons.verified
                : Icons.pending_actions),
            title: Text('Status: ${_status.toUpperCase()}'),
            subtitle: Text(verificationStatusMessage(_status, _note)),
          ),
        ),
        const SizedBox(height: 8),
        const Text('Your Ghana Card number stays on this phone — only the '
            'document photos you attach are sent for review, when you sync.'),
        TextField(controller: _legal, enabled: editable,
            decoration: const InputDecoration(labelText: 'Legal business name')),
        TextField(controller: _trading, enabled: editable,
            decoration: const InputDecoration(labelText: 'Trading name (as customers know it)')),
        DropdownButtonFormField<String>(
          initialValue: _type,
          decoration: const InputDecoration(labelText: 'Business type'),
          items: const [
            DropdownMenuItem(value: 'sole_prop', child: Text('Sole proprietor')),
            DropdownMenuItem(value: 'informal', child: Text('Informal trader (no ORC registration)')),
            DropdownMenuItem(value: 'limited', child: Text('Limited company')),
            DropdownMenuItem(value: 'company', child: Text('Company / institution')),
          ],
          onChanged: editable ? (v) => setState(() => _type = v ?? 'sole_prop') : null,
        ),
        TextField(controller: _orc, enabled: editable,
            decoration: const InputDecoration(labelText: 'ORC registration no. (companies)')),
        TextField(controller: _tin, enabled: editable,
            decoration: const InputDecoration(labelText: 'TIN (GRA)')),
        SwitchListTile(
          title: const Text('VAT-registered'),
          value: _vat,
          onChanged: editable ? (v) => setState(() => _vat = v) : null,
        ),
        TextField(controller: _address, enabled: editable,
            decoration: const InputDecoration(labelText: 'Business address / location')),
        TextField(controller: _category, enabled: editable,
            decoration: const InputDecoration(labelText: 'Category (e.g. Provisions, Pharmacy, Hardware)')),
        TextField(controller: _phone, enabled: editable,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Contact phone')),
        TextField(controller: _email, enabled: editable,
            decoration: const InputDecoration(labelText: 'Contact email (optional)')),
        TextField(controller: _ghanaCard, enabled: editable,
            decoration: const InputDecoration(
                labelText: 'Owner Ghana Card no. (stays on this phone)')),
        const Divider(height: 32),
        const Text('Documents', style: TextStyle(fontWeight: FontWeight.bold)),
        for (final d in _docs)
          ListTile(
            leading: const Icon(Icons.description),
            title: Text(_docLabels[d.docType] ?? d.docType),
            subtitle: Text(d.uploaded ? 'Uploaded for review' : 'On this phone — will upload on sync'),
            trailing: Icon(d.uploaded ? Icons.cloud_done : Icons.smartphone),
          ),
        if (editable)
          Wrap(spacing: 8, children: [
            for (final e in _docLabels.entries)
              ActionChip(
                avatar: const Icon(Icons.add_a_photo, size: 16),
                label: Text(e.value),
                onPressed: () => _addDoc(e.key),
              ),
          ]),
        const SizedBox(height: 20),
        if (editable) ...[
          OutlinedButton(
              onPressed: () => _save(submit: false),
              child: const Text('Save (on this phone)')),
          const SizedBox(height: 8),
          FilledButton(
              onPressed: () => _save(submit: true),
              child: Text(_status == 'rejected' ? 'Resubmit for Verification' : 'Submit for Verification')),
          const SizedBox(height: 8),
        ],
        FilledButton.tonalIcon(
          icon: const Icon(Icons.sync),
          label: const Text('Sync Now (needs internet)'),
          onPressed: _busy ? null : _sync,
        ),
      ]),
    );
  }
}
