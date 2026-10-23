import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/api.dart';
import '../../data/contacts_repository.dart';
import '../../ui/em_ui.dart';
import 'contact_sheet.dart';
import 'sos_controller.dart';

/// Add, edit and remove the people who receive the SOS text.
class TrustedContactsScreen extends StatefulWidget {
  const TrustedContactsScreen({super.key});

  @override
  State<TrustedContactsScreen> createState() => _TrustedContactsScreenState();
}

class _TrustedContactsScreenState extends State<TrustedContactsScreen> {
  final _repo = ContactsRepository(ContactKind.trusted);

  List<Contact>? _contacts;
  String? _error;
  int? _removingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<List<Contact>?> _load() async {
    try {
      final contacts = await _repo.list();
      if (!mounted) return null;
      setState(() {
        _contacts = contacts;
        _error = null;
      });
      return contacts;
    } catch (e) {
      if (!mounted) return null;
      final message = e is ApiException ? e.message : 'Couldn’t load your trusted contacts.';
      if (_contacts == null) {
        setState(() => _error = message);
      } else {
        showEmToast(context, message);
      }
      return null;
    }
  }

  Future<void> _retry() async {
    setState(() => _error = null);
    await _load();
  }

  Future<void> _add() async {
    final before = {for (final c in _contacts ?? const <Contact>[]) c.id};
    final saved = await showContactSheet(context, kind: ContactKind.trusted);
    if (!saved || !mounted) return;
    final after = await _load();
    if (!mounted) return;
    // The sheet only reports success, so find the new entry to name it in the toast.
    final added = after?.where((c) => !before.contains(c.id)).firstOrNull;
    showEmToast(
      context,
      added == null ? 'Trusted contact added' : '${added.name} added to trusted contacts',
      icon: Icons.check_circle_outline_rounded,
    );
  }

  Future<void> _edit(Contact contact) async {
    final saved = await showContactSheet(context, kind: ContactKind.trusted, existing: contact);
    if (!saved || !mounted) return;
    await _load();
    if (mounted) showEmToast(context, 'Changes saved', icon: Icons.check_circle_outline_rounded);
  }

  Future<void> _remove(Contact contact) async {
    final others = (_contacts ?? const <Contact>[]).where((c) => c.id != contact.id).toList();
    final consequence = others.isEmpty
        ? 'SOS will have no one to alert until you add someone.'
        : '${namesList(others)} will still be alerted.';
    final confirmed = await showEmConfirm(
      context,
      title: 'Remove ${contact.name}?',
      message: '${contact.name} won’t get your SOS anymore. $consequence',
      confirmLabel: 'Remove',
      danger: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _removingId = contact.id);
    try {
      await _repo.delete(contact.id);
      if (!mounted) return;
      setState(() => _contacts = others);
      showEmToast(context, '${contact.name} removed');
    } on ApiException catch (e) {
      if (mounted) showEmToast(context, e.message);
    } finally {
      if (mounted) setState(() => _removingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contacts = _contacts;
    final state = _error != null ? 'error' : contacts == null ? 'loading' : 'list';
    return Scaffold(
      appBar: const EmTopBar(title: 'Trusted contacts'),
      body: EmStateSwitcher(stateKey: state, child: _body()),
    );
  }

  Widget _body() {
    if (_error != null) {
      return Center(child: EmStateView.error(message: _error!, onRetry: _retry));
    }
    final contacts = _contacts;
    if (contacts == null) {
      return const SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [EmSkeleton(height: 64, radius: 16), SizedBox(height: 16), ContactsSkeleton(count: 3)],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const EmFadeSlideIn(
            child: EmNote(
              child: Text('These people get your SOS text and location. They aren’t notified when you add them, so let them know.'),
            ),
          ),
          const SizedBox(height: 16),
          EmStateSwitcher(
            stateKey: contacts.isEmpty,
            child: contacts.isEmpty
                ? EmStateView(
                    icon: Icons.person_add_alt_1_rounded,
                    title: 'No trusted contacts yet',
                    message: 'Add at least one person so SOS has someone to text.',
                    actionLabel: 'Add trusted contact',
                    onAction: _add,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      EmGroup(
                        children: [
                          _ContactRows(
                            contacts: contacts,
                            rowBuilder: (c, leaving) => EmStateSwitcher(
                              // Cross-fades the row when an edit changes what it shows.
                              stateKey: '${c.name}|${c.relation}|${c.phone}',
                              child: EmRow(
                                leading: EmAvatar(name: c.name),
                                title: c.name,
                                subtitle: [c.relation, c.phone].where((s) => s.isNotEmpty).join(' · '),
                                trailing: leaving
                                    ? const SizedBox(width: 88)
                                    : _removingId == c.id
                                        ? const SizedBox(
                                            width: 88,
                                            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4))),
                                          )
                                        : Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              EmIconButton(icon: Icons.edit_outlined, label: 'Edit ${c.name}', onPressed: () => _edit(c)),
                                              EmIconButton(
                                                icon: Icons.delete_outline_rounded,
                                                label: 'Remove ${c.name}',
                                                onPressed: _removingId == null ? () => _remove(c) : null,
                                              ),
                                            ],
                                          ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      EmFadeSlideIn(
                        index: math.min(contacts.length + 1, 8),
                        child: EmButton(label: 'Add trusted contact', icon: Icons.add_rounded, variant: EmButtonVariant.tonal, onPressed: _add),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Rows of a contact list that stagger in on first load, grow in when a
/// contact is added and fold away in place when one is removed. The caller
/// just passes the current list; this widget keeps a removed row around
/// long enough to animate it out.
class _ContactRows extends StatefulWidget {
  const _ContactRows({required this.contacts, required this.rowBuilder});

  final List<Contact> contacts;

  /// [leaving] is true while a removed row folds away, so it can drop its actions.
  final Widget Function(Contact contact, bool leaving) rowBuilder;

  @override
  State<_ContactRows> createState() => _ContactRowsState();
}

class _ContactRowsState extends State<_ContactRows> {
  late List<Contact> _shown = widget.contacts;
  late final Set<int> _initial = {for (final c in widget.contacts) c.id};
  final Set<int> _leaving = {};

  @override
  void didUpdateWidget(_ContactRows old) {
    super.didUpdateWidget(old);
    final ids = {for (final c in widget.contacts) c.id};
    final merged = [...widget.contacts];
    for (var i = 0; i < _shown.length; i++) {
      final c = _shown[i];
      if (!ids.contains(c.id)) {
        _leaving.add(c.id);
        merged.insert(math.min(i, merged.length), c);
      }
    }
    _leaving.removeWhere(ids.contains);
    _shown = merged;
  }

  void _drop(int id) {
    if (!mounted || !_leaving.contains(id)) return;
    setState(() {
      _leaving.remove(id);
      _shown = _shown.where((c) => c.id != id).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (i, c) in _shown.indexed)
          _RowPresence(
            key: ValueKey(c.id),
            visible: !_leaving.contains(c.id),
            animateIn: !_initial.contains(c.id),
            onGone: () => _drop(c.id),
            child: EmFadeSlideIn(
              index: _initial.contains(c.id) ? i : 0,
              child: Column(
                children: [
                  if (i > 0) const Divider(height: 1),
                  widget.rowBuilder(c, _leaving.contains(c.id)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _RowPresence extends StatefulWidget {
  const _RowPresence({super.key, required this.visible, required this.animateIn, required this.onGone, required this.child});

  final bool visible;
  final bool animateIn;
  final VoidCallback onGone;
  final Widget child;

  @override
  State<_RowPresence> createState() => _RowPresenceState();
}

class _RowPresenceState extends State<_RowPresence> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: EmMotion.slow,
    reverseDuration: EmMotion.medium,
    value: widget.animateIn ? 0 : 1,
  )..addStatusListener((status) {
      if (status == AnimationStatus.dismissed && !widget.visible) {
        // Removing the row rebuilds the parent, which can't happen mid-build.
        WidgetsBinding.instance.addPostFrameCallback((_) => widget.onGone());
      }
    });
  late final Animation<double> _size = CurvedAnimation(parent: _c, curve: EmMotion.enter, reverseCurve: EmMotion.exit);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.animateIn) _animate(true);
  }

  @override
  void didUpdateWidget(_RowPresence old) {
    super.didUpdateWidget(old);
    if (old.visible != widget.visible) _animate(widget.visible);
  }

  void _animate(bool show) {
    if (EmMotion.reduced(context)) {
      _c.value = show ? 1 : 0;
    } else if (show) {
      _c.forward();
    } else {
      _c.reverse();
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
      sizeFactor: _size,
      alignment: Alignment.topCenter,
      child: FadeTransition(opacity: _c, child: IgnorePointer(ignoring: !widget.visible, child: widget.child)),
    );
  }
}

/// Loading placeholder shaped like a group of contact rows.
class ContactsSkeleton extends StatelessWidget {
  const ContactsSkeleton({super.key, this.count = 2});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            for (var i = 0; i < count; i++) ...[
              if (i > 0) const Divider(height: 1),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    EmSkeleton(width: 40, height: 40, radius: 20),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          EmSkeleton(height: 14, width: 120),
                          SizedBox(height: 8),
                          EmSkeleton(height: 12, width: 170),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
