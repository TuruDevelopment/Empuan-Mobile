import 'package:flutter/material.dart';

import '../../data/account_repository.dart';
import '../../data/api.dart';
import '../../ui/em_ui.dart';
import '../profile/legal_screen.dart';
import 'interests_screen.dart';
import 'login_screen.dart' show isEmail;

const _minimumAge = 18;

/// Steps 1 and 2 of sign-up. The account is created at the end of step 2;
/// steps 3 and 4 (interests, trusted contact) can be skipped.
class SignupFlow extends StatefulWidget {
  const SignupFlow({super.key});

  @override
  State<SignupFlow> createState() => _SignupFlowState();
}

class _SignupFlowState extends State<SignupFlow> {
  final _accountForm = GlobalKey<FormState>();
  final _profileForm = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _dobText = TextEditingController();
  DateTime? _dob;
  bool _agreed = false;
  bool _showAgreeError = false;
  int _step = 1;
  bool _creating = false;
  String? _serverError;

  @override
  void initState() {
    super.initState();
    _password.addListener(() => setState(() {}));
    _confirm.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [_email, _password, _confirm, _name, _username, _dobText]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _longEnough => _password.text.length >= 8;
  bool get _hasNumber => RegExp(r'\d').hasMatch(_password.text);
  bool get _matches => _confirm.text.isNotEmpty && _confirm.text == _password.text;
  bool get _dirty => [_email, _password, _name, _username].any((c) => c.text.isNotEmpty);

  Future<bool> _confirmLeave() async {
    if (!_dirty) return true;
    return showEmConfirm(
      context,
      title: 'Leave sign-up?',
      message: 'Nothing is saved yet. You can start again any time.',
      confirmLabel: 'Keep going',
      cancelLabel: 'Leave',
    ).then((keepGoing) => !keepGoing);
  }

  void _next() {
    FocusScope.of(context).unfocus();
    final valid = _accountForm.currentState!.validate();
    setState(() => _showAgreeError = !_agreed);
    if (valid && _agreed) setState(() => _step = 2);
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final latest = DateTime(now.year - _minimumAge, now.month, now.day);
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
    _profileForm.currentState?.validate();
    if (picked.isAfter(latest) && mounted) {
      showEmToast(context, 'Empuan is for adults 18 and over.');
    }
  }

  Future<void> _create() async {
    FocusScope.of(context).unfocus();
    if (!_profileForm.currentState!.validate()) return;
    setState(() {
      _creating = true;
      _serverError = null;
    });
    try {
      await AccountRepository().register(
        name: _name.text.trim(),
        username: _username.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        dob: _dob!,
      );
      try {
        await AccountRepository().fetchMe();
      } catch (_) {
        // Not needed to continue onboarding.
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const InterestsScreen()), (_) => false);
    } on ApiException catch (e) {
      setState(() => _serverError = e.message);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  String? _validateDob(String? _) {
    if (_dob == null) return 'Choose your date of birth';
    final now = DateTime.now();
    final latest = DateTime(now.year - _minimumAge, now.month, now.day);
    if (_dob!.isAfter(latest)) return 'You must be 18 or older to use Empuan';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_step == 2) {
          setState(() => _step = 1);
          return;
        }
        if (await _confirmLeave() && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: OnboardingTopBar(step: _step, closeIcon: _step == 1, onBack: () => Navigator.of(context).maybePop()),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _step == 1 ? _accountStep(context) : _profileStep(context),
        ),
        bottomNavigationBar: EmBottomBar(
          bordered: false,
          child: _step == 1
              ? EmButton(label: 'Continue', onPressed: _next)
              : EmButton(label: 'Create account', loading: _creating, onPressed: _create),
        ),
      ),
    );
  }

  Widget _accountStep(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Form(
      key: _accountForm,
      child: ListView(
        key: const ValueKey('account'),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text('Create your account', style: text.headlineLarge),
          const SizedBox(height: 8),
          Text('You’ll use this email and password to log in.', style: text.bodyMedium?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
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
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            validator: (_) => _longEnough && _hasNumber ? null : 'Use at least 8 characters, including a number',
          ),
          EmCheckLine(label: 'At least 8 characters', met: _longEnough),
          EmCheckLine(label: 'Includes a number', met: _hasNumber),
          const SizedBox(height: 16),
          EmTextField(
            label: 'Confirm password',
            controller: _confirm,
            password: true,
            textInputAction: TextInputAction.done,
            validator: (v) => v == _password.text ? null : 'Passwords don’t match',
          ),
          if (_confirm.text.isNotEmpty) EmCheckLine(label: _matches ? 'Passwords match' : 'Passwords don’t match yet', met: _matches),
          const SizedBox(height: 20),
          InkWell(
            onTap: () => setState(() {
              _agreed = !_agreed;
              if (_agreed) _showAgreeError = false;
            }),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _agreed,
                    onChanged: (v) => setState(() {
                      _agreed = v ?? false;
                      if (_agreed) _showAgreeError = false;
                    }),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text.rich(
                        TextSpan(
                          style: text.bodySmall?.copyWith(fontSize: 14, color: AppColors.textPrimary),
                          children: [
                            const TextSpan(text: 'I agree to the '),
                            TextSpan(text: 'Terms of Service', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                            const TextSpan(text: ' and '),
                            TextSpan(text: 'Privacy Policy', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                            const TextSpan(text: ', and I’m 18 or older.'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => pushScreen(context, const LegalScreen(doc: LegalDoc.terms)), child: const Text('Read terms')),
              TextButton(onPressed: () => pushScreen(context, const LegalScreen(doc: LegalDoc.privacy)), child: const Text('Read privacy policy')),
            ],
          ),
          if (_showAgreeError)
            const Text('Please agree to continue', style: TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _profileStep(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Form(
      key: _profileForm,
      child: ListView(
        key: const ValueKey('profile'),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text('A bit about you', style: text.headlineLarge),
          const SizedBox(height: 8),
          Text('Your name shows on posts and certificates. Your birth date stays private.',
              style: text.bodyMedium?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          EmTextField(
            label: 'Full name',
            controller: _name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            validator: (v) => (v ?? '').trim().length < 2 ? 'Enter your name' : null,
          ),
          const SizedBox(height: 16),
          EmTextField(
            label: 'Username',
            controller: _username,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newUsername],
            validator: (v) {
              final value = (v ?? '').trim();
              if (value.length < 3) return 'Use at least 3 characters';
              if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(value)) return 'Use letters, numbers, dots or underscores';
              return null;
            },
          ),
          const SizedBox(height: 16),
          EmTextField(
            label: 'Date of birth',
            controller: _dobText,
            readOnly: true,
            onTap: _pickDob,
            suffixIcon: Icons.calendar_today_outlined,
            hint: 'Choose a date',
            helper: 'Empuan is for adults 18 and over. We also use this to pick courses for your stage of life.',
            validator: _validateDob,
          ),
          if (_serverError != null) ...[
            const SizedBox(height: 16),
            Text(_serverError!, style: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}

/// Top bar with back/close, a 4-segment progress bar and an optional Skip.
class OnboardingTopBar extends StatelessWidget implements PreferredSizeWidget {
  const OnboardingTopBar({super.key, required this.step, this.closeIcon = false, this.onBack, this.onSkip});

  final int step;
  final bool closeIcon;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            const SizedBox(width: 8),
            if (onBack != null)
              EmIconButton(
                icon: closeIcon ? Icons.close_rounded : Icons.arrow_back_ios_new_rounded,
                label: closeIcon ? 'Leave sign-up' : 'Back',
                onPressed: onBack,
              )
            else
              const SizedBox(width: 44),
            Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: EmStepBar(step: step, total: 4))),
            if (onSkip != null)
              TextButton(onPressed: onSkip, child: const Text('Skip'))
            else
              SizedBox(width: 56, child: Center(child: Text('$step of 4', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)))),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
