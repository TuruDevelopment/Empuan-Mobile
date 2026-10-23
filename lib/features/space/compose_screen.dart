import 'package:flutter/material.dart';

import '../../data/account_repository.dart';
import '../../data/api.dart';
import '../../data/community_repository.dart';
import '../../ui/em_ui.dart';
import '../profile/legal_screen.dart';

/// New Her Space post. Pops with true once the post is published.
class ComposeScreen extends StatefulWidget {
  const ComposeScreen({super.key});

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  static const _maxLength = 500;

  final _repo = CommunityRepository();
  final _text = TextEditingController();
  bool _posting = false;

  bool get _hasText => _text.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    if (!_hasText || _posting) return;
    setState(() => _posting = true);
    try {
      await _repo.createPost(_text.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) showEmToast(context, 'Your post wasn’t published. ${e.message}');
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _confirmDiscard() async {
    final discard = await showEmConfirm(
      context,
      title: 'Discard this post?',
      message: 'What you’ve written will be lost.',
      confirmLabel: 'Discard',
      cancelLabel: 'Keep writing',
      danger: true,
    );
    if (discard && mounted) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final name = Session.user.value?.name ?? 'Member';
    return PopScope<bool>(
      canPop: !_hasText || _posting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: EmTopBar(
          title: 'New post',
          closeIcon: true,
          backgroundColor: AppColors.surface,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: AnimatedSwitcher(
                  duration: EmMotion.reduced(context) ? Duration.zero : EmMotion.medium,
                  switchInCurve: EmMotion.enter,
                  switchOutCurve: EmMotion.exit,
                  transitionBuilder: (child, a) => FadeTransition(
                    opacity: a,
                    child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(a), child: child),
                  ),
                  child: EmButton(
                    key: ValueKey(_hasText),
                    label: 'Post',
                    small: true,
                    expand: false,
                    loading: _posting,
                    onPressed: _hasText ? _post : null,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                children: [
                  Row(
                    children: [
                      ExcludeSemantics(child: EmAvatar(name: name)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            const Text(
                              'Visible to everyone in Her Space',
                              style: TextStyle(fontSize: 12, height: 16 / 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _text,
                    autofocus: true,
                    readOnly: _posting,
                    minLines: 7,
                    maxLines: null,
                    maxLength: _maxLength,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(fontSize: 18, height: 27 / 18, color: AppColors.textPrimary),
                    buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                        _Counter(length: currentLength, max: maxLength!),
                    decoration: const InputDecoration(
                      hintText: 'What would you like to ask or share?',
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + MediaQuery.paddingOf(context).bottom),
              child: const _GuidelinesNote(),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidelinesNote extends StatelessWidget {
  const _GuidelinesNote();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      hint: 'Opens the community guidelines',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => pushScreen<void>(context, const LegalScreen(doc: LegalDoc.guidelines)),
        child: const EmNote(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'By posting you agree to the '),
                TextSpan(
                  text: 'community guidelines',
                  style: TextStyle(fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
                ),
                TextSpan(text: '. Be kind, and don’t share anyone’s phone number or address, including your own.'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Character count that warms up as the post nears the limit.
class _Counter extends StatelessWidget {
  const _Counter({required this.length, required this.max});

  final int length;
  final int max;

  @override
  Widget build(BuildContext context) {
    final left = max - length;
    final (color, weight) = left <= 0
        ? (AppColors.danger, FontWeight.w700)
        : left <= 50
            ? (AppColors.primary, FontWeight.w700)
            : (AppColors.textSecondary, FontWeight.w400);
    return AnimatedDefaultTextStyle(
      duration: EmMotion.reduced(context) ? Duration.zero : EmMotion.medium,
      curve: EmMotion.enter,
      style: TextStyle(fontFamily: AppFonts.body, fontSize: 12, color: color, fontWeight: weight),
      child: Text(
        '$length / $max',
        semanticsLabel: left <= 50 ? '$left characters left' : '$length of $max characters',
      ),
    );
  }
}
