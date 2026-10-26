import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/account_repository.dart';
import '../../data/api.dart';
import '../../ui/em_ui.dart';
import 'form_motion.dart';
import 'login_screen.dart' show isEmail;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  bool _sending = false;
  String? _sentTo;
  String? _error;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await AccountRepository().requestPasswordReset(_email.text.trim());
      setState(() {
        _sentTo = _email.text.trim();
        _cooldown = 60;
      });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted || _cooldown <= 1) {
          t.cancel();
          if (mounted) setState(() => _cooldown = 0);
        } else {
          setState(() => _cooldown--);
        }
      });
    } on ApiException catch (e) {
      setState(() => _error = e.notAvailable
          ? 'Password reset isn’t available in the app yet. Contact support to reset it.'
          : e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final wait = '0:${_cooldown.toString().padLeft(2, '0')}';
    return Scaffold(
      appBar: const EmTopBar(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: staggered([
            Text('Reset your password', style: text.headlineLarge),
            const SizedBox(height: 8),
            Text('Enter your account email. We’ll send you a link to set a new password.',
                style: text.bodyMedium?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 28),
            EmTextField(
              label: 'Email',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: (v) => isEmail(v) ? null : 'Enter a valid email address',
            ),
            AnimatedFormMessage(message: _error, padding: const EdgeInsets.only(top: 12)),
            const SizedBox(height: 24),
            EmButton(
              label: _cooldown > 0 ? 'Send again in $wait' : (_sentTo == null ? 'Send reset link' : 'Send again'),
              loading: _sending,
              onPressed: _cooldown > 0 ? null : _send,
            ),
            // Slides up into place once the link has been sent.
            AnimatedReveal(
              switchKey: _sentTo,
              offset: const Offset(0, 0.15),
              child: _sentTo == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: EmCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const EmIconTile(Icons.mail_outline_rounded),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Check your inbox', style: text.titleMedium),
                                  const SizedBox(height: 4),
                                  Text('Sent to $_sentTo. Didn’t get it? Check your spam folder.', style: text.bodySmall),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ]),
        ),
      ),
    );
  }
}
