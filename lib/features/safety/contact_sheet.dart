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

  // Bumped when the contact picker fills a field, to flash it briefly so the
  // user sees what changed.
  int _nameFilled = 0;
  int _phoneFilled = 0;

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
        if ((picked.fullName ?? '').isNotEmpty) {
          _name.text = picked.fullName!;
          _nameFilled++;
        }
        final number = picked.selectedPhoneNumber ?? (picked.phoneNumbers?.isNotEmpty == true ? picked.phoneNumbers!.first : null);
        if (number != null) {
          _phone.text = number;
          _phoneFilled++;
        }
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
          _FillFlash(
            trigger: _nameFilled,
            child: EmTextField(
              label: 'Name',
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a name' : null,
            ),
          ),
          const SizedBox(height: 14),
          _FillFlash(
            trigger: _phoneFilled,
            child: EmTextField(
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
          AnimatedSize(
            duration: EmMotion.reduced(context) ? Duration.zero : EmMotion.medium,
            curve: EmMotion.enter,
            alignment: Alignment.topCenter,
            child: _error == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    // Keyed on the text so a different error slides in again.
                    child: EmFadeSlideIn(
                      key: ValueKey(_error),
                      offset: const Offset(0, -8),
                      duration: EmMotion.medium,
                      child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          EmButton(label: 'Save', loading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}

/// Briefly tints the area behind a field each time [trigger] changes.
class _FillFlash extends StatefulWidget {
  const _FillFlash({required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  State<_FillFlash> createState() => _FillFlashState();
}

class _FillFlashState extends State<_FillFlash> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final Animation<double> _glow = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: EmMotion.enter)), weight: 20),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: EmMotion.exit)), weight: 45),
  ]).animate(_c);

  @override
  void didUpdateWidget(_FillFlash old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger && !EmMotion.reduced(context)) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -8,
          right: -8,
          top: -6,
          bottom: -6,
          child: IgnorePointer(
            child: FadeTransition(
              opacity: _glow,
              child: DecoratedBox(decoration: BoxDecoration(color: AppColors.blush, borderRadius: BorderRadius.circular(14))),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}
