import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';

import '../../data/api.dart';
import '../../data/contacts_repository.dart';
import '../../ui/em_ui.dart';

const _trustedRelations = ['Mother', 'Father', 'Sister', 'Brother', 'Partner', 'Friend', 'Other'];
const _callerRelations = ['Mother', 'Sister', 'Partner', 'Friend', 'Boss', 'Coworker', 'Other'];

/// Add or edit a trusted contact or a fake-call caller. Returns true when saved.
Future<bool> showContactSheet(BuildContext context, {required ContactKind kind, Contact? existing}) async {
  final saved = await showEmSheet<bool>(
    context,
    builder: (_) => _ContactForm(kind: kind, existing: existing),
  );
  return saved ?? false;
}

class _ContactForm extends StatefulWidget {
  const _ContactForm({required this.kind, this.existing});

  final ContactKind kind;
  final Contact? existing;

  @override
  State<_ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<_ContactForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _phone = TextEditingController(text: widget.existing?.phone);
  late String? _relation = widget.existing?.relation.isEmpty ?? true ? null : widget.existing!.relation;
  bool _saving = false;
  String? _error;

  List<String> get _relations => widget.kind == ContactKind.trusted ? _trustedRelations : _callerRelations;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final picked = await FlutterNativeContactPicker().selectPhoneNumber();
      if (picked == null) return;
      setState(() {
        if ((picked.fullName ?? '').isNotEmpty) _name.text = picked.fullName!;
        final number = picked.selectedPhoneNumber ?? (picked.phoneNumbers?.isNotEmpty == true ? picked.phoneNumbers!.first : null);
        if (number != null) _phone.text = number;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Couldn’t open your contacts. Type the number instead.');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_relation == null) {
      setState(() => _error = 'Choose how you know them.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ContactsRepository(widget.kind);
    try {
      if (widget.existing == null) {
        await repo.create(name: _name.text.trim(), phone: _phone.text.trim(), relation: _relation!);
      } else {
        await repo.update(widget.existing!.id, name: _name.text.trim(), phone: _phone.text.trim(), relation: _relation!);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    final title = switch ((widget.kind, editing)) {
      (ContactKind.trusted, false) => 'Add trusted contact',
      (ContactKind.trusted, true) => 'Edit trusted contact',
      (ContactKind.caller, false) => 'Add caller',
      (ContactKind.caller, true) => 'Edit caller',
    };
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          if (widget.kind == ContactKind.caller) ...[
            const SizedBox(height: 6),
            Text('This name shows on the fake incoming call. Nobody is actually called.', style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 16),
          EmButton(label: 'Choose from phone contacts', icon: Icons.contacts_outlined, variant: EmButtonVariant.tonal, onPressed: _pick),
          const SizedBox(height: 16),
          EmTextField(
            label: 'Name',
            controller: _name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a name' : null,
          ),
          const SizedBox(height: 14),
          EmTextField(
            label: 'Phone number',
            controller: _phone,
            keyboardType: TextInputType.phone,
            helper: widget.kind == ContactKind.trusted ? 'Include the country code if the number is outside Indonesia.' : null,
            validator: (v) {
              final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
              if (digits.isEmpty) return 'Enter a phone number';
              if (digits.length < 8) return 'This number looks too short';
              return null;
            },
          ),
          const SizedBox(height: 14),
          Text(widget.kind == ContactKind.trusted ? 'Relationship' : 'Shows as', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in _relations) EmChip(label: r, selected: r == _relation, onTap: () => setState(() => _relation = r)),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 20),
          EmButton(label: 'Save', loading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}
