import 'package:flutter/material.dart';

import '../../data/account_repository.dart';
import '../../data/api.dart';
import '../../ui/em_ui.dart';
import '../auth/login_screen.dart' show isEmail;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _dobText = TextEditingController();
  DateTime? _dob;
  UserProfile? _original;
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
    for (final c in [_name, _username, _email]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _username, _email, _dobText]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final me = await AccountRepository().fetchMe();
      _original = me;
      _name.text = me.name;
      _username.text = me.username;
      _email.text = me.email;
      _dob = me.dob;
      _dobText.text = formatDate(me.dob);
    } on ApiException catch (e) {
      _loadError = e.message;
    }
    if (mounted) setState(() => _loading = false);
  }

  bool get _changed {
    final o = _original;
    if (o == null) return false;
    return _name.text.trim() != o.name ||
        _username.text.trim() != o.username ||
        _email.text.trim() != o.email ||
        (_dob != null && (o.dob == null || apiDate(_dob!) != apiDate(o.dob!)));
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'Date of birth',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked == null) return;
    setState(() {
      _dob = picked;
      _dobText.text = formatDate(picked);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = await AccountRepository().updateProfile(
        name: _name.text.trim(),
        username: _username.text.trim(),
        email: _email.text.trim(),
        dob: _dob,
      );
      _original = updated;
      if (mounted) {
        showEmToast(context, 'Changes saved', icon: Icons.check_rounded);
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) showEmToast(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirmDiscard() => showEmConfirm(
        context,
        title: 'Discard changes?',
        message: 'Your edits haven’t been saved.',
        confirmLabel: 'Discard',
        cancelLabel: 'Keep editing',
        danger: true,
      );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_changed || _saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) {
          _original = null;
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: const EmTopBar(title: 'Personal details'),
        body: _loading
            ? const EmLoading()
            : _loadError != null
                ? Center(child: EmStateView.error(message: _loadError!, onRetry: _load))
                : Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        Center(child: EmAvatar(name: _name.text, size: 88)),
                        const SizedBox(height: 24),
                        EmTextField(
                          label: 'Full name',
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => (v ?? '').trim().length < 2 ? 'Enter your name' : null,
                        ),
                        const SizedBox(height: 16),
                        EmTextField(
                          label: 'Username',
                          controller: _username,
                          validator: (v) {
                            final value = (v ?? '').trim();
                            if (value.length < 3) return 'Use at least 3 characters';
                            if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(value)) return 'Use letters, numbers, dots or underscores';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        EmTextField(
                          label: 'Email',
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => isEmail(v) ? null : 'Enter a valid email address',
                        ),
                        const SizedBox(height: 16),
                        EmTextField(
                          label: 'Date of birth',
                          controller: _dobText,
                          readOnly: true,
                          onTap: _pickDob,
                          hint: 'Choose a date',
                          suffixIcon: Icons.calendar_today_outlined,
                          validator: (_) {
                            if (_dob == null) return null;
                            final now = DateTime.now();
                            return _dob!.isAfter(DateTime(now.year - 18, now.month, now.day)) ? 'You must be 18 or older to use Empuan' : null;
                          },
                        ),
                      ],
                    ),
                  ),
        bottomNavigationBar: _loading || _loadError != null
            ? null
            : EmBottomBar(
                bordered: false,
                child: EmButton(label: 'Save changes', loading: _saving, onPressed: _changed ? _save : null),
              ),
      ),
    );
  }
}
