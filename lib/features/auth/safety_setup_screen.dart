import 'package:flutter/material.dart';

import '../../app/main_shell.dart';
import '../../data/contacts_repository.dart';
import '../../ui/em_ui.dart';
import '../safety/contact_sheet.dart';
import '../safety/location_consent_screen.dart';
import 'form_motion.dart';
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

  /// Contacts animating out while their delete is in flight.
  final Set<int> _leaving = {};

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
    setState(() => _leaving.add(c.id));
    try {
      // Wait at least as long as the collapse so the row doesn't vanish mid-animation.
      await Future.wait([_repo.delete(c.id), Future<void>.delayed(EmMotion.medium)]);
    } catch (_) {
      if (mounted) showEmToast(context, 'Couldn’t remove ${c.name}. Try again.');
    }
    await _reload();
    if (mounted) setState(() => _leaving.remove(c.id));
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
    final shown = _contacts.where((c) => !_leaving.contains(c.id)).toList();
    final firstShown = shown.isEmpty ? null : shown.first.id;
    return Scaffold(
      appBar: OnboardingTopBar(step: 4, onSkip: _toApp),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: staggered([
          const Align(alignment: Alignment.centerLeft, child: EmIconTile(Icons.shield_outlined, tone: EmTileTone.danger, size: 48)),
          const SizedBox(height: 16),
          Text('Who should we alert in an emergency?', style: text.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'When you hold SOS, Empuan opens your messages app with a text and your location, addressed to these people.',
            style: text.bodySmall?.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 20),
          AnimatedReveal(
            child: shown.isEmpty
                ? null
                : Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    // Same look as EmGroup, but each row (with its divider) can
                    // grow in when added and collapse when removed.
                    child: Material(
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.line)),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          for (final c in _contacts)
                            _ContactItem(
                              key: ValueKey(c.id),
                              visible: !_leaving.contains(c.id),
                              divider: c.id != firstShown,
                              child: EmRow(
                                leading: EmAvatar(name: c.name),
                                title: c.name,
                                subtitle: [c.relation, c.phone].where((s) => s.isNotEmpty).join(' · '),
                                trailing: EmIconButton(icon: Icons.close_rounded, label: 'Remove ${c.name}', onPressed: () => _remove(c)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
          EmButton(
            label: _contacts.isEmpty ? 'Add a trusted contact' : 'Add another',
            icon: Icons.person_add_alt_1_outlined,
            variant: EmButtonVariant.tonal,
            onPressed: _add,
          ),
          const SizedBox(height: 16),
          const EmNote(child: Text('Add at least two people if you can, in case one doesn’t pick up. They aren’t notified when you add them.')),
        ]),
      ),
      bottomNavigationBar: EmBottomBar(
        bordered: false,
        child: AnimatedEnabled(
          enabled: _contacts.isNotEmpty,
          child: EmButton(label: 'Continue', onPressed: _contacts.isEmpty ? null : _continue),
        ),
      ),
    );
  }
}

/// A contact row that grows in when first shown and collapses when [visible]
/// turns false.
class _ContactItem extends StatefulWidget {
  const _ContactItem({super.key, required this.visible, required this.divider, required this.child});

  final bool visible;
  final bool divider;
  final Widget child;

  @override
  State<_ContactItem> createState() => _ContactItemState();
}

class _ContactItemState extends State<_ContactItem> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: EmMotion.medium);
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: EmMotion.enter, reverseCurve: EmMotion.exit);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (EmMotion.reduced(context)) {
      _c.value = widget.visible ? 1 : 0;
    } else if (widget.visible) {
      _c.forward();
    }
  }

  @override
  void didUpdateWidget(_ContactItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible == oldWidget.visible) return;
    if (EmMotion.reduced(context)) {
      _c.value = widget.visible ? 1 : 0;
    } else {
      widget.visible ? _c.forward() : _c.reverse();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _t,
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: _t,
        child: Column(
          children: [
            if (widget.divider) const Divider(height: 1),
            widget.child,
          ],
        ),
      ),
    );
  }
}
