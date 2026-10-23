import 'package:flutter/material.dart';

import '../../data/account_repository.dart';
import '../../data/api.dart';
import '../../data/contacts_repository.dart';
import '../../ui/em_ui.dart';
import '../auth/form_motion.dart';
import '../auth/interests_screen.dart';
import '../auth/welcome_screen.dart';
import '../learning/screens/learning_certificates_screen.dart';
import '../safety/fake_call_screen.dart';
import '../safety/trusted_contacts_screen.dart';
import 'animated_avatar.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'legal_screen.dart';

class MeScreen extends StatefulWidget {
  const MeScreen({super.key});

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  int? _trusted;
  int? _callers;

  @override
  void initState() {
    super.initState();
    _loadCounts();
    if (Session.user.value == null) AccountRepository().fetchMe().ignore();
  }

  Future<void> _loadCounts() async {
    final results = await Future.wait([
      ContactsRepository(ContactKind.trusted).list().then((l) => l.length).catchError((_) => -1),
      ContactsRepository(ContactKind.caller).list().then((l) => l.length).catchError((_) => -1),
    ]);
    if (!mounted) return;
    setState(() {
      _trusted = results[0] < 0 ? null : results[0];
      _callers = results[1] < 0 ? null : results[1];
    });
  }

  Future<void> _open(Widget screen) async {
    await pushScreen(context, screen);
    if (mounted) await _loadCounts();
  }

  Future<void> _signOut() async {
    final ok = await showEmConfirm(
      context,
      title: 'Sign out of Empuan?',
      message: 'Your posts, courses and contacts stay saved. You’ll need your password to log back in.',
      confirmLabel: 'Sign out',
      extra: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: AppColors.dangerTint, borderRadius: BorderRadius.circular(12)),
        child: const Text('While you’re signed out, SOS won’t work.', style: TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
    if (!ok) return;
    await AccountRepository().logout();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true)
        .pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const WelcomeScreen()), (_) => false);
  }

  Future<void> _deleteAccount() async {
    final deleted = await showEmSheet<bool>(context, builder: (_) => const _DeleteAccountForm());
    if (deleted == true && mounted) {
      Navigator.of(context, rootNavigator: true)
          .pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const WelcomeScreen()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    String? count(int? n) => n?.toString();
    return Scaffold(
      appBar: const EmTopBar(title: 'Me'),
      body: ValueListenableBuilder<UserProfile?>(
        valueListenable: Session.user,
        builder: (context, user, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: staggered([
            Row(
              children: [
                AnimatedAvatar(name: user?.name ?? '', size: 72),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? '', style: text.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        [if (user?.username.isNotEmpty ?? false) '@${user!.username}', user?.email ?? ''].where((s) => s.isNotEmpty).join(' · '),
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
                EmButton(label: 'Edit', variant: EmButtonVariant.tonal, small: true, expand: false, onPressed: () => _open(const EditProfileScreen())),
              ],
            ),
            const SizedBox(height: 24),
            _group('Safety', [
              EmRow(
                leading: const EmIconTile(Icons.shield_outlined),
                title: 'Trusted contacts',
                trailing: _count(count(_trusted)),
                showChevron: true,
                onTap: () => _open(const TrustedContactsScreen()),
              ),
              EmRow(
                leading: const EmIconTile(Icons.phone_in_talk_outlined),
                title: 'Fake call callers',
                trailing: _count(count(_callers)),
                showChevron: true,
                onTap: () => _open(const FakeCallScreen()),
              ),
            ]),
            _group('Learning', [
              EmRow(
                leading: const EmIconTile(Icons.favorite_border_rounded),
                title: 'Your interests',
                subtitle: 'Used to suggest courses and articles',
                onTap: () => _open(InterestsScreen(editing: true, initial: Session.user.value?.interests ?? const [])),
              ),
              EmRow(
                leading: const EmIconTile(Icons.workspace_premium_outlined),
                title: 'My certificates',
                onTap: () => _open(const LearningCertificatesScreen()),
              ),
            ]),
            _group('Account', [
              EmRow(leading: const EmIconTile(Icons.person_outline_rounded), title: 'Personal details', onTap: () => _open(const EditProfileScreen())),
              EmRow(leading: const EmIconTile(Icons.lock_outline_rounded), title: 'Change password', onTap: () => _open(const ChangePasswordScreen())),
            ]),
            _group('About', [
              EmRow(leading: const EmIconTile(Icons.forum_outlined), title: 'Community guidelines', onTap: () => _open(const LegalScreen(doc: LegalDoc.guidelines))),
              EmRow(leading: const EmIconTile(Icons.description_outlined), title: 'Terms of Service', onTap: () => _open(const LegalScreen(doc: LegalDoc.terms))),
              EmRow(leading: const EmIconTile(Icons.privacy_tip_outlined), title: 'Privacy Policy', onTap: () => _open(const LegalScreen(doc: LegalDoc.privacy))),
              const EmRow(leading: EmIconTile(Icons.mail_outline_rounded), title: 'Contact support', subtitle: supportEmail),
            ]),
            EmButton(label: 'Sign out', variant: EmButtonVariant.secondary, onPressed: _signOut),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _deleteAccount,
              style: TextButton.styleFrom(foregroundColor: AppColors.danger, minimumSize: const Size.fromHeight(52)),
              child: const Text('Delete account'),
            ),
            const SizedBox(height: 4),
            Text('Empuan 1.0.0', textAlign: TextAlign.center, style: text.bodySmall),
          ]),
        ),
      ),
    );
  }

  /// Counts load after the screen opens, so they slide in rather than pop.
  Widget _count(String? value) => EmAnimatedSwap(
        valueKey: value ?? '',
        child: value == null ? const SizedBox.shrink() : Text(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 14)),
      );

  Widget _group(String title, List<Widget> rows) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: EmCaption(title)),
            EmGroup(children: rows),
          ],
        ),
      );
}

class _DeleteAccountForm extends StatefulWidget {
  const _DeleteAccountForm();

  @override
  State<_DeleteAccountForm> createState() => _DeleteAccountFormState();
}

class _DeleteAccountFormState extends State<_DeleteAccountForm> {
  final _password = TextEditingController();
  bool _deleting = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_password.text.isEmpty) {
      setState(() => _error = 'Enter your password');
      return;
    }
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await AccountRepository().deleteAccount(_password.text);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.notAvailable
          ? 'In-app deletion isn’t available yet. Email $supportEmail from your account email and we’ll delete it.'
          : e.message);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const EmSheetHeader(title: 'Delete your account?', message: 'This can’t be undone. We’ll permanently remove:'),
        const SizedBox(height: 10),
        for (final line in const [
          'Your profile and login',
          'Posts and comments in Her Space',
          'Your chat history with Empuan AI',
          'Trusted contacts, callers and certificates',
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(padding: EdgeInsets.only(top: 8, right: 10), child: CircleAvatar(radius: 2.5, backgroundColor: AppColors.textPrimary)),
                Expanded(child: Text(line, style: text.bodyMedium)),
              ],
            ),
          ),
        const SizedBox(height: 12),
        EmTextField(label: 'Enter your password to confirm', controller: _password, password: true, errorText: _error),
        const SizedBox(height: 20),
        EmButton(label: 'Delete my account', variant: EmButtonVariant.danger, loading: _deleting, onPressed: _delete),
        const SizedBox(height: 8),
        EmButton(label: 'Keep my account', variant: EmButtonVariant.text, onPressed: () => Navigator.of(context).pop(false)),
      ],
    );
  }
}
