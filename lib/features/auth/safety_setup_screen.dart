import 'package:flutter/material.dart';

import '../../app/main_shell.dart';
import '../../data/contacts_repository.dart';
import '../../ui/em_ui.dart';
import '../safety/contact_sheet.dart';
import '../safety/location_consent_screen.dart';
import 'signup_flow.dart' show OnboardingTopBar;

/// Step 4 of sign-up: add the first trusted contact, then explain location.
class SafetySetupScreen extends StatefulWidget {
  const SafetySetupScreen({super.key});

  @override
  State<SafetySetupScreen> createState() => _SafetySetupScreenState();
}

class _SafetySetupScreenState extends State<SafetySetupScreen> {
  final _repo = ContactsRepository(ContactKind.trusted);
  List<Contact> _contacts = const [];

  Future<void> _reload() async {
    try {
      final list = await _repo.list();
      if (mounted) setState(() => _contacts = list);
    } catch (_) {
      // Keep what we have; the Safety tab shows errors properly.
    }
  }

  Future<void> _add() async {
    if (await showContactSheet(context, kind: ContactKind.trusted)) await _reload();
  }

  Future<void> _remove(Contact c) async {
    try {
      await _repo.delete(c.id);
    } catch (_) {
      if (mounted) showEmToast(context, 'Couldn’t remove ${c.name}. Try again.');
    }
    await _reload();
  }

  void _toApp() {
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MainShell()), (_) => false);
  }

  void _continue() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => LocationConsentScreen(afterSetup: true, onDone: _toApp)));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: OnboardingTopBar(step: 4, onSkip: _toApp),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const Align(alignment: Alignment.centerLeft, child: EmIconTile(Icons.shield_outlined, tone: EmTileTone.danger, size: 48)),
          const SizedBox(height: 16),
          Text('Who should we alert in an emergency?', style: text.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'When you hold SOS, Empuan opens your messages app with a text and your location, addressed to these people.',
            style: text.bodySmall?.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 20),
          if (_contacts.isNotEmpty) ...[
            EmGroup(
              children: [
                for (final c in _contacts)
                  EmRow(
                    leading: EmAvatar(name: c.name),
                    title: c.name,
                    subtitle: [c.relation, c.phone].where((s) => s.isNotEmpty).join(' · '),
                    trailing: EmIconButton(icon: Icons.close_rounded, label: 'Remove ${c.name}', onPressed: () => _remove(c)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          EmButton(
            label: _contacts.isEmpty ? 'Add a trusted contact' : 'Add another',
            icon: Icons.person_add_alt_1_outlined,
            variant: EmButtonVariant.tonal,
            onPressed: _add,
          ),
          const SizedBox(height: 16),
          const EmNote(child: Text('Add at least two people if you can, in case one doesn’t pick up. They aren’t notified when you add them.')),
        ],
      ),
      bottomNavigationBar: EmBottomBar(
        bordered: false,
        child: EmButton(label: 'Continue', onPressed: _contacts.isEmpty ? null : _continue),
      ),
    );
  }
}
