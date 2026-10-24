import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/api.dart';
import '../../data/contacts_repository.dart';
import '../../ui/em_ui.dart';
import 'call_screens.dart';
import 'contact_sheet.dart';
import 'trusted_contacts_screen.dart' show ContactsSkeleton;

/// Ringtones bundled in assets/, keyed by the AssetSource path.
const fakeCallRingtones = {'ringtone.mp3': 'Classic', 'ringtone2.mp3': 'Soft'};

const _ringtoneKey = 'fake_call_ringtone';
const _vibrateKey = 'fake_call_vibrate';
const _callerKey = 'fake_call_caller_id';

/// Pick a caller and ring the phone with a fake incoming call.
///
/// The delay timer lives only in this screen. Nothing is scheduled with the
/// system, so leaving the screen cancels a pending call.
class FakeCallScreen extends StatefulWidget {
  const FakeCallScreen({super.key});

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen> {
  final _repo = ContactsRepository(ContactKind.caller);

  List<Contact>? _callers;
  String? _error;
  int? _selectedId;
  String _ringtone = fakeCallRingtones.keys.first;
  bool _vibrate = true;

  Timer? _ticker;
  DateTime? _ringAt;
  Contact? _pendingCaller;

  @override
  void initState() {
    super.initState();
    _restorePrefs();
    _load();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _restorePrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        final ringtone = prefs.getString(_ringtoneKey);
        if (fakeCallRingtones.containsKey(ringtone)) _ringtone = ringtone!;
        _vibrate = prefs.getBool(_vibrateKey) ?? true;
        _selectedId ??= prefs.getInt(_callerKey);
      });
    } catch (_) {
      // Defaults are fine if preferences can't be read.
    }
  }

  Future<void> _save(Future<void> Function(SharedPreferences prefs) write) async {
    try {
      await write(await SharedPreferences.getInstance());
    } catch (_) {
      // Not worth interrupting the user over a setting that didn't stick.
    }
  }

  Future<List<Contact>?> _load() async {
    try {
      final callers = await _repo.list();
      if (!mounted) return null;
      setState(() {
        _callers = callers;
        _error = null;
      });
      return callers;
    } catch (e) {
      if (!mounted) return null;
      final message = e is ApiException ? e.message : 'Couldn’t load your callers.';
      if (_callers == null) {
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

  /// The chosen caller, or the first one when nothing valid is chosen.
  Contact? get _caller {
    final callers = _callers;
    if (callers == null || callers.isEmpty) return null;
    return callers.where((c) => c.id == _selectedId).firstOrNull ?? callers.first;
  }

  void _select(Contact caller) {
    setState(() => _selectedId = caller.id);
    _save((p) => p.setInt(_callerKey, caller.id));
  }

  Future<void> _addCaller() async {
    final before = {for (final c in _callers ?? const <Contact>[]) c.id};
    final saved = await showContactSheet(context, kind: ContactKind.caller);
    if (!saved || !mounted) return;
    final after = await _load();
    final added = after?.where((c) => !before.contains(c.id)).firstOrNull;
    if (added != null) _select(added);
    if (mounted) showEmToast(context, 'Caller added', icon: Icons.check_circle_outline_rounded);
  }

  Future<void> _editCaller(Contact caller) async {
    final saved = await showContactSheet(context, kind: ContactKind.caller, existing: caller);
    if (!saved || !mounted) return;
    await _load();
    if (mounted) showEmToast(context, 'Changes saved', icon: Icons.check_circle_outline_rounded);
  }

  Future<void> _pickRingtone() async {
    final picked = await showEmSheet<String>(
      context,
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const EmSheetHeader(title: 'Ringtone'),
          const SizedBox(height: 16),
          for (final entry in fakeCallRingtones.entries) ...[
            EmOption(
              label: entry.value,
              selected: entry.key == _ringtone,
              onTap: () => Navigator.of(ctx).pop(entry.key),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _ringtone = picked);
    await _save((p) => p.setString(_ringtoneKey, picked));
  }

  void _setVibrate(bool value) {
    setState(() => _vibrate = value);
    _save((p) => p.setBool(_vibrateKey, value));
  }

  Future<void> _ringMe() async {
    final caller = _caller;
    if (caller == null) return;
    final delay = await showEmSheet<Duration>(context, builder: (_) => _TimerSheet(callerName: caller.name));
    if (delay == null || !mounted) return;
    if (delay == Duration.zero) {
      _ring(caller);
      return;
    }
    _ticker?.cancel();
    setState(() {
      _pendingCaller = caller;
      _ringAt = DateTime.now().add(delay);
    });
    // Compare against a wall-clock target so the countdown stays right if
    // ticks are delayed while the app is in the background.
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      if (_remaining <= Duration.zero) {
        final pending = _pendingCaller!;
        _cancel();
        _ring(pending);
      } else {
        setState(() {});
      }
    });
  }

  Duration get _remaining => _ringAt == null ? Duration.zero : _ringAt!.difference(DateTime.now());

  void _cancel() {
    _ticker?.cancel();
    _ticker = null;
    setState(() {
      _ringAt = null;
      _pendingCaller = null;
    });
  }

  void _ring(Contact caller) {
    pushScreen<void>(
      context,
      IncomingCallScreen(name: caller.name, relation: caller.relation, ringtone: _ringtone, vibrate: _vibrate),
    );
  }

  @override
  Widget build(BuildContext context) {
    final caller = _caller;
    final pending = _ringAt != null;
    return Scaffold(
      appBar: const EmTopBar(title: 'Fake call'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              'Your phone rings like a real call, so you have a reason to step away. No one is actually called.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            // Grows in when a timer starts and folds away on cancel; the
            // switcher keeps the last card on screen while it leaves.
            AnimatedSwitcher(
              duration: EmMotion.reduced(context) ? Duration.zero : EmMotion.slow,
              reverseDuration: EmMotion.reduced(context) ? Duration.zero : EmMotion.medium,
              switchInCurve: EmMotion.enter,
              switchOutCurve: EmMotion.exit,
              transitionBuilder: (child, a) => SizeTransition(
                sizeFactor: a,
                alignment: Alignment.topCenter,
                child: FadeTransition(
                  opacity: a,
                  child: SlideTransition(position: Tween(begin: const Offset(0, -0.15), end: Offset.zero).animate(a), child: child),
                ),
              ),
              child: pending
                  ? Padding(
                      key: const ValueKey('waiting'),
                      padding: const EdgeInsets.only(top: 18),
                      child: _WaitingCard(name: _pendingCaller!.name, remaining: _remaining, onCancel: _cancel),
                    )
                  : const SizedBox(key: ValueKey('idle'), width: double.infinity),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: Text('Who’s calling?', style: Theme.of(context).textTheme.labelMedium)),
                if (_callers?.isNotEmpty == true) TextButton(onPressed: _addCaller, child: const Text('Add caller')),
              ],
            ),
            const SizedBox(height: 4),
            EmStateSwitcher(
              stateKey: _callersState,
              child: SizedBox(width: double.infinity, child: _callersSection(caller)),
            ),
            const SizedBox(height: 18),
            EmGroup(
              children: [
                EmRow(
                  leading: const EmIconTile(Icons.music_note_rounded),
                  title: 'Ringtone',
                  trailing: Text(fakeCallRingtones[_ringtone]!, style: Theme.of(context).textTheme.bodySmall),
                  showChevron: true,
                  onTap: _pickRingtone,
                ),
                MergeSemantics(
                  child: EmRow(
                    leading: const EmIconTile(Icons.vibration_rounded),
                    title: 'Vibrate',
                    trailing: Switch(value: _vibrate, onChanged: _setVibrate),
                    onTap: () => _setVibrate(!_vibrate),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: EmBottomBar(
        bordered: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_callers != null && caller == null) ...[
              Text('Add a caller to use fake call', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
            ],
            EmButton(
              label: pending ? 'Ring now' : 'Ring me',
              icon: Icons.call_rounded,
              onPressed: caller == null
                  ? null
                  : pending
                      ? () {
                          final p = _pendingCaller!;
                          _cancel();
                          _ring(p);
                        }
                      : _ringMe,
            ),
          ],
        ),
      ),
    );
  }

  String get _callersState => switch (_callers) {
        _ when _error != null => 'error',
        null => 'loading',
        final c when c.isEmpty => 'empty',
        _ => 'list',
      };

  Widget _callersSection(Contact? selected) {
    if (_error != null) {
      return EmCard(child: EmStateView.error(message: _error!, onRetry: _retry));
    }
    final callers = _callers;
    if (callers == null) return const ContactsSkeleton();
    if (callers.isEmpty) {
      return EmCard(
        child: EmStateView(
          icon: Icons.person_add_alt_1_rounded,
          title: 'No callers yet',
          message: 'Add the name you want on the call screen, like Ibu or your boss.',
          actionLabel: 'Add caller',
          onAction: _addCaller,
        ),
      );
    }
    return EmGroup(
      children: [
        for (final (i, c) in callers.indexed)
          EmFadeSlideIn(
            key: ValueKey(c.id),
            index: i,
            child: Semantics(
              selected: c.id == selected?.id,
              inMutuallyExclusiveGroup: true,
              child: EmRow(
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RadioMark(selected: c.id == selected?.id),
                    const SizedBox(width: 12),
                    EmAvatar(name: c.name),
                  ],
                ),
                title: c.name,
                subtitle: 'Shows as “${c.name} · ${c.relation.isEmpty ? 'Mobile' : c.relation}”',
                highlighted: c.id == selected?.id,
                onTap: () => _select(c),
                trailing: EmIconButton(icon: Icons.edit_outlined, label: 'Edit ${c.name}', onPressed: () => _editCaller(c)),
              ),
            ),
          ),
      ],
    );
  }
}

class _RadioMark extends StatelessWidget {
  const _RadioMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: EmMotion.reduced(context) ? Duration.zero : EmMotion.medium,
      curve: EmMotion.enter,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: selected ? AppColors.primary : AppColors.line2, width: selected ? 7 : 2),
      ),
    );
  }
}

class _WaitingCard extends StatelessWidget {
  const _WaitingCard({required this.name, required this.remaining, required this.onCancel});

  final String name;
  final Duration remaining;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final seconds = (remaining.inMilliseconds / 1000).ceil().clamp(0, 24 * 3600);
    final clock = '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    return EmCard(
      color: AppColors.blush,
      borderColor: AppColors.blush,
      child: Row(
        children: [
          const EmIconTile(Icons.timer_outlined, tone: EmTileTone.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  label: '$name calls in $clock',
                  excludeSemantics: true,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(child: Text('$name calls in ', style: Theme.of(context).textTheme.titleSmall)),
                      // Only the time ticks; the name stays put.
                      EmAnimatedSwap(
                        valueKey: clock,
                        child: Text(
                          clock,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text('Leaving this screen cancels the call.', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          EmButton(label: 'Cancel', variant: EmButtonVariant.secondary, small: true, expand: false, onPressed: onCancel),
        ],
      ),
    );
  }
}

class _TimerSheet extends StatefulWidget {
  const _TimerSheet({required this.callerName});

  final String callerName;

  @override
  State<_TimerSheet> createState() => _TimerSheetState();
}

class _TimerSheetState extends State<_TimerSheet> {
  static const _options = [
    ('Right now', Duration.zero),
    ('In 10 seconds', Duration(seconds: 10)),
    ('In 1 minute', Duration(minutes: 1)),
    ('In 5 minutes', Duration(minutes: 5)),
  ];

  Duration _delay = const Duration(seconds: 10);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EmSheetHeader(
          title: 'When should ${widget.callerName} call?',
          message: 'Keep Empuan open in the background. The call screen appears when the timer ends.',
        ),
        const SizedBox(height: 18),
        for (var row = 0; row < _options.length; row += 2) ...[
          if (row > 0) const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = row; i < row + 2; i++) ...[
                  if (i > row) const SizedBox(width: 10),
                  Expanded(
                    child: _DelayOption(
                      label: _options[i].$1,
                      selected: _options[i].$2 == _delay,
                      onTap: () => setState(() => _delay = _options[i].$2),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        EmButton(
          label: _delay == Duration.zero ? 'Ring now' : 'Start timer',
          onPressed: () => Navigator.of(context).pop(_delay),
        ),
      ],
    );
  }
}

class _DelayOption extends StatelessWidget {
  const _DelayOption({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: Material(
        color: selected ? AppColors.blush : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: selected ? AppColors.primary : AppColors.line2, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            alignment: Alignment.center,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primaryVariant : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
