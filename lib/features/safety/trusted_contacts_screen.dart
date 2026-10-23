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
    return Scaffold(
      appBar: const EmTopBar(title: 'Trusted contacts'),
      body: _body(),
    );
  }

  Widget _body() {
    if (_error != null) {
      return Center(child: EmStateView.error(message: _error!, onRetry: _retry));
    }
    final contacts = _contacts;
    if (contacts == null) return const EmLoading();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const EmNote(
            child: Text('These people get your SOS text and location. They aren’t notified when you add them, so let them know.'),
          ),
          const SizedBox(height: 16),
          if (contacts.isEmpty)
            EmStateView(
              icon: Icons.person_add_alt_1_rounded,
              title: 'No trusted contacts yet',
              message: 'Add at least one person so SOS has someone to text.',
              actionLabel: 'Add trusted contact',
              onAction: _add,
            )
          else ...[
            EmGroup(
              children: [
                for (final c in contacts)
                  EmRow(
                    leading: EmAvatar(name: c.name),
                    title: c.name,
                    subtitle: [c.relation, c.phone].where((s) => s.isNotEmpty).join(' · '),
                    trailing: _removingId == c.id
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
              ],
            ),
            const SizedBox(height: 16),
            EmButton(label: 'Add trusted contact', icon: Icons.add_rounded, variant: EmButtonVariant.tonal, onPressed: _add),
          ],
        ],
      ),
    );
  }
}
