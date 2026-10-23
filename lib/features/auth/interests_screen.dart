import 'package:flutter/material.dart';

import '../../data/account_repository.dart';
import '../../data/api.dart';
import '../../ui/em_ui.dart';
import 'safety_setup_screen.dart';
import 'signup_flow.dart' show OnboardingTopBar;

const interestOptions = [
  'Career and work',
  'Managing money',
  'Personal safety',
  'Digital skills',
  'Starting a business',
];

/// Step 3 of sign-up, also opened from Me › Your interests.
class InterestsScreen extends StatefulWidget {
  const InterestsScreen({super.key, this.editing = false, this.initial = const []});

  /// True when opened from Me: no step bar, saves and pops.
  final bool editing;
  final List<String> initial;

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  late final Set<String> _picked = widget.initial.where(interestOptions.contains).toSet();
  late bool _other = widget.initial.any((i) => !interestOptions.contains(i));
  late final _otherText = TextEditingController(text: widget.initial.where((i) => !interestOptions.contains(i)).join(', '));
  bool _saving = false;

  @override
  void dispose() {
    _otherText.dispose();
    super.dispose();
  }

  void _next() {
    if (widget.editing) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SafetySetupScreen()));
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await AccountRepository().saveInterests(_picked.toList(), other: _other ? _otherText.text : null);
      if (widget.editing && mounted) showEmToast(context, 'Interests saved');
    } on ApiException catch (e) {
      // Interests only tune suggestions; during sign-up a failure shouldn't stop the user.
      if (widget.editing && mounted) {
        showEmToast(context, e.message);
        setState(() => _saving = false);
        return;
      }
    }
    if (mounted) {
      setState(() => _saving = false);
      _next();
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final nothingPicked = _picked.isEmpty && !_other;
    return Scaffold(
      appBar: widget.editing
          ? const EmTopBar(title: 'Your interests')
          : OnboardingTopBar(step: 3, onSkip: _next) as PreferredSizeWidget,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text('What do you want to learn about?', style: text.headlineMedium),
          const SizedBox(height: 8),
          Text('Choose any that apply. We use this to suggest courses and articles.', style: text.bodySmall?.copyWith(fontSize: 14)),
          const SizedBox(height: 20),
          for (final option in interestOptions) ...[
            EmOption(
              label: option,
              multi: true,
              selected: _picked.contains(option),
              onTap: () => setState(() => _picked.contains(option) ? _picked.remove(option) : _picked.add(option)),
            ),
            const SizedBox(height: 8),
          ],
          EmOption(label: 'Something else', multi: true, selected: _other, onTap: () => setState(() => _other = !_other)),
          if (_other) ...[
            const SizedBox(height: 8),
            EmTextField(
              label: 'Tell us more',
              hideLabel: true,
              controller: _otherText,
              hint: 'Tell us in a few words',
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ],
      ),
      bottomNavigationBar: EmBottomBar(
        bordered: false,
        child: EmButton(
          label: widget.editing ? 'Save' : 'Continue',
          loading: _saving,
          onPressed: nothingPicked ? (widget.editing ? null : _next) : _save,
        ),
      ),
    );
  }
}
