import 'package:flutter/material.dart';

import '../../data/account_repository.dart';
import '../../data/api.dart';
import '../../ui/em_ui.dart';
import '../auth/forgot_password_screen.dart';
import '../auth/form_motion.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final c in [_current, _next, _confirm]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_current, _next, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _longEnough => _next.text.length >= 8;
  bool get _hasNumber => RegExp(r'\d').hasMatch(_next.text);
  bool get _different => _next.text.isNotEmpty && _next.text != _current.text;
  bool get _matches => _confirm.text.isNotEmpty && _confirm.text == _next.text;
  bool get _valid => _current.text.isNotEmpty && _longEnough && _hasNumber && _different && _matches;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AccountRepository().changePassword(current: _current.text, next: _next.text);
      if (!mounted) return;
      showEmToast(context, 'Password updated', icon: Icons.check_rounded);
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const EmTopBar(title: 'Change password'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: staggered([
          EmTextField(label: 'Current password', controller: _current, password: true, autofillHints: const [AutofillHints.password]),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: () => pushScreen(context, const ForgotPasswordScreen()), child: const Text('Forgot it?')),
          ),
          EmTextField(label: 'New password', controller: _next, password: true, autofillHints: const [AutofillHints.newPassword]),
          AnimatedCheckLine(label: 'At least 8 characters', met: _longEnough),
          AnimatedCheckLine(label: 'Includes a number', met: _hasNumber),
          AnimatedCheckLine(label: 'Different from your current password', met: _different),
          const SizedBox(height: 16),
          EmTextField(
            label: 'Confirm new password',
            controller: _confirm,
            password: true,
            errorText: _confirm.text.isNotEmpty && !_matches ? 'Passwords don’t match yet' : null,
          ),
          AnimatedFormMessage(message: _error, padding: const EdgeInsets.only(top: 12)),
        ]),
      ),
      bottomNavigationBar: EmBottomBar(
        bordered: false,
        child: AnimatedEnabled(
          enabled: _valid,
          child: EmButton(label: 'Update password', loading: _saving, onPressed: _valid ? _save : null),
        ),
      ),
    );
  }
}
