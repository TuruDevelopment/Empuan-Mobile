import 'package:flutter/material.dart';

import '../../data/api.dart';
import '../../data/contacts_repository.dart';
import '../../ui/em_ui.dart';
import 'contact_sheet.dart';
import 'fake_call_screen.dart';
import 'help_lines.dart';
import 'siren_screen.dart';
import 'sos_controller.dart';
import 'trusted_contacts_screen.dart';

/// Tab root for SOS setup, trusted contacts and the get-away tools.
class SafetyTab extends StatefulWidget {
  const SafetyTab({super.key});

  @override
  State<SafetyTab> createState() => _SafetyTabState();
}

class _SafetyTabState extends State<SafetyTab> {
  List<Contact>? _contacts;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final contacts = await SosController.instance.trustedContacts();
      if (!mounted) return;
      setState(() {
        _contacts = contacts;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.message : 'Couldn’t load your trusted contacts.';
      // Keep showing the last list on a failed refresh; only an empty screen gets the error state.
      if (_contacts == null) {
        setState(() => _error = message);
      } else {
        showEmToast(context, message);
      }
    }
  }

  Future<void> _retry() async {
    setState(() => _error = null);
    await _load();
  }

  Future<void> _open(Widget screen) async {
    await pushScreen<void>(context, screen);
    if (mounted) await _load();
  }

  Future<void> _addContact() async {
    final saved = await showContactSheet(context, kind: ContactKind.trusted);
    if (!saved || !mounted) return;
    showEmToast(context, 'Trusted contact added', icon: Icons.check_circle_outline_rounded);
    await _load();
  }

  Future<void> _call(Contact contact) async {
    final opened = await SosController.dial(contact.phone);
    if (!opened && mounted) showEmToast(context, 'Couldn’t open the phone app.');
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text('Safety', style: text.headlineLarge),
              const SizedBox(height: 16),
              EmFadeSlideIn(child: _HowSosWorks(contacts: _contacts, failed: _error != null)),
              const SizedBox(height: 22),
              EmFadeSlideIn(
                index: 1,
                child: EmSectionHeader(
                  'Trusted contacts',
                  actionLabel: _contacts?.isNotEmpty == true ? 'Manage' : null,
                  onAction: () => _open(const TrustedContactsScreen()),
                ),
              ),
              const SizedBox(height: 8),
              EmFadeSlideIn(
                index: 2,
                child: EmStateSwitcher(
                  stateKey: _contactsState,
                  child: SizedBox(width: double.infinity, child: _contactsSection()),
                ),
              ),
              const SizedBox(height: 22),
              const EmFadeSlideIn(index: 3, child: EmSectionHeader('Get out of a situation')),
              const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: EmFadeSlideIn(
                        index: 4,
                        child: _ToolCard(
                          icon: Icons.phone_in_talk_rounded,
                          title: 'Fake call',
                          message: 'Your phone rings with a caller you choose',
                          onTap: () => _open(const FakeCallScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: EmFadeSlideIn(
                        index: 5,
                        child: _ToolCard(
                          icon: Icons.campaign_rounded,
                          tone: EmTileTone.danger,
                          title: 'Siren',
                          message: 'Play a loud alarm to draw attention',
                          onTap: () => _open(const SirenScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const EmFadeSlideIn(index: 6, child: EmSectionHeader('Emergency numbers')),
              const SizedBox(height: 12),
              const EmFadeSlideIn(index: 7, child: HelpLinesGroup()),
              const SizedBox(height: 8),
              EmFadeSlideIn(
                index: 7,
                child: Text('Calls use your phone network, so they work without internet.', style: Theme.of(context).textTheme.bodySmall),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _contactsState => switch (_contacts) {
        _ when _error != null => 'error',
        null => 'loading',
        final c when c.isEmpty => 'empty',
        _ => 'list',
      };

  Widget _contactsSection() {
    if (_error != null) {
      return EmCard(child: EmStateView.error(message: _error!, onRetry: _retry));
    }
    final contacts = _contacts;
    if (contacts == null) return const ContactsSkeleton();
    if (contacts.isEmpty) {
      return EmCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EmIconTile(Icons.person_add_alt_1_rounded),
            const SizedBox(height: 12),
            Text('No one to alert yet', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Add someone you trust. When you hold SOS, they get your help text and location.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            EmButton(label: 'Add a trusted contact', icon: Icons.add_rounded, onPressed: _addContact),
          ],
        ),
      );
    }
    final shown = contacts.take(3).toList();
    return EmGroup(
      children: [
        for (final (i, c) in shown.indexed)
          EmFadeSlideIn(
            key: ValueKey(c.id),
            index: i,
            child: EmRow(
              leading: EmAvatar(name: c.name),
              title: c.name,
              subtitle: [c.relation, c.phone].where((s) => s.isNotEmpty).join(' · '),
              trailing: EmIconButton(
                icon: Icons.call_rounded,
                label: 'Call ${c.name}',
                style: EmIconButtonStyle.tint,
                onPressed: () => _call(c),
              ),
            ),
          ),
        if (contacts.length > 3)
          EmFadeSlideIn(
            index: 3,
            child: EmRow(
              title: 'See all ${contacts.length} contacts',
              titleColor: AppColors.primary,
              onTap: () => _open(const TrustedContactsScreen()),
            ),
          ),
      ],
    );
  }
}

class _HowSosWorks extends StatelessWidget {
  const _HowSosWorks({required this.contacts, required this.failed});

  final List<Contact>? contacts;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final count = contacts?.length;
    final (status, warning) = switch (count) {
      _ when failed => ('Couldn’t check your trusted contacts', true),
      null => ('Checking your trusted contacts', false),
      0 => ('Not ready · add a trusted contact first', true),
      1 => ('Ready · 1 trusted contact', false),
      _ => ('Ready · $count trusted contacts', false),
    };
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                  child: const Text(
                    'SOS',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.6),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('How SOS works', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    EmAnimatedSwap(
                      valueKey: status,
                      child: Row(
                        children: [
                          if (warning) ...[
                            const Icon(Icons.error_outline_rounded, size: 16, color: Colors.white),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Text(
                              status,
                              style: TextStyle(
                                color: warning ? Colors.white : AppColors.surfaceAlt,
                                fontSize: 13,
                                fontWeight: warning ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _Step(number: 1, text: 'Press and hold SOS for 3 seconds'),
          const SizedBox(height: 12),
          const _Step(number: 2, text: 'Your messages app opens with a help text and your location'),
          const SizedBox(height: 12),
          const _Step(number: 3, text: 'Tap send. Tap “I’m safe” when it’s over'),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step $number. $text',
      excludeSemantics: true,
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), shape: BoxShape.circle),
            child: Text('$number', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, height: 18 / 13))),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.icon, required this.title, required this.message, required this.onTap, this.tone = EmTileTone.normal});

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onTap;
  final EmTileTone tone;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: EmCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EmIconTile(icon, tone: tone),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(message, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
