import 'package:flutter/material.dart';

import '../../app/main_shell.dart';
import '../../data/account_repository.dart';
import '../../services/auth_service.dart';
import '../../ui/em_ui.dart';
import 'forgot_password_screen.dart';
import 'signup_flow.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final ok = await AuthService().login(email: _email.text.trim(), password: _password.text);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _loading = false;
        _error = 'That email and password don’t match. Check them and try again.';
      });
      return;
    }
    try {
      await AccountRepository().fetchMe();
    } catch (_) {
      // The shell loads the profile again; a failure here shouldn't block login.
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MainShell()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: const EmTopBar(),
      body: AutofillGroup(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text('Welcome back', style: text.headlineLarge),
              const SizedBox(height: 8),
              Text('Log in with the email you signed up with.', style: text.bodyMedium?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 28),
              EmTextField(
                label: 'Email',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: (v) => isEmail(v) ? null : 'Enter a valid email address',
              ),
              const SizedBox(height: 16),
              EmTextField(
                label: 'Password',
                controller: _password,
                password: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _submit(),
                validator: (v) => (v ?? '').isEmpty ? 'Enter your password' : null,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => pushScreen(context, ForgotPasswordScreen(initialEmail: _email.text.trim())),
                  child: const Text('Forgot password?'),
                ),
              ),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
              EmButton(label: 'Log in', loading: _loading, onPressed: _submit),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('New to Empuan?', style: text.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SignupFlow())),
                    child: const Text('Create an account'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool isEmail(String? value) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((value ?? '').trim());
