import 'package:flutter/material.dart';

import '../../data/api.dart';
import '../../data/community_repository.dart';
import '../../ui/em_ui.dart';

const _contentReasons = [
  'Harassment or bullying',
  'Hate speech',
  'Sexual content',
  'Spam or scam',
  'Shares someone’s private info',
  'Something else',
];

const _aiReasons = [
  'Harmful or unsafe',
  'Offensive or hateful',
  'Wrong or misleading',
  'Something else',
];

/// Report a post, reply, comment or AI answer, and optionally block the
/// author. Returns true when a report was sent.
Future<bool> showReportSheet(
  BuildContext context, {
  required ReportTarget target,
  required String targetId,
  String? authorName,
  int? authorId,
}) async {
  final sent = await showEmSheet<bool>(
    context,
    builder: (_) => _ReportForm(target: target, targetId: targetId, authorName: authorName, authorId: authorId),
  );
  if (sent == true && context.mounted) {
    showEmToast(context, 'Thanks. We’ll review your report.', icon: Icons.check_rounded);
  }
  return sent ?? false;
}

class _ReportForm extends StatefulWidget {
  const _ReportForm({required this.target, required this.targetId, this.authorName, this.authorId});

  final ReportTarget target;
  final String targetId;
  final String? authorName;
  final int? authorId;

  @override
  State<_ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<_ReportForm> {
  final _details = TextEditingController();
  final _repo = ModerationRepository();
  String? _reason;
  bool _block = false;
  bool _sending = false;
  String? _error;

  bool get _isAi => widget.target == ReportTarget.aiAnswer;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_reason == null) {
      setState(() => _error = 'Choose a reason');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await _repo.report(target: widget.target, targetId: widget.targetId, reason: _reason!, details: _details.text);
      if (_block && widget.authorId != null) await _repo.blockUser(widget.authorId!);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.notAvailable
          ? 'Reporting isn’t available yet. Email support@empuan.com and we’ll look into it.'
          : e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.target) {
      ReportTarget.communityPost => 'Report this post',
      ReportTarget.communityReply || ReportTarget.articleComment => 'Report this comment',
      ReportTarget.aiAnswer => 'Report this answer',
    };
    final reasons = _isAi ? _aiReasons : _contentReasons;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EmSheetHeader(
          title: title,
          message: _isAi
              ? 'Reports help us fix answers that are harmful or wrong.'
              : 'Your report is anonymous. Our team reviews every report.',
        ),
        const SizedBox(height: 12),
        for (final r in reasons)
          RadioListTile<String>(
            value: r,
            groupValue: _reason,
            onChanged: (v) => setState(() {
              _reason = v;
              _error = null;
            }),
            title: Text(r, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        if (_isAi || _reason == 'Something else') ...[
          const SizedBox(height: 8),
          EmTextField(label: 'Details (optional)', controller: _details, hint: 'What went wrong?', maxLines: 3, maxLength: 300),
        ],
        if (!_isAi && widget.authorId != null) ...[
          const Divider(),
          SwitchListTile(
            value: _block,
            onChanged: (v) => setState(() => _block = v),
            contentPadding: EdgeInsets.zero,
            title: Text('Also block ${widget.authorName ?? 'this member'}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            subtitle: const Text('You won’t see their posts or replies'),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
        const SizedBox(height: 16),
        EmButton(label: 'Send report', loading: _sending, onPressed: _send),
      ],
    );
  }
}

/// Block without reporting. Returns true when blocked.
Future<bool> confirmBlock(BuildContext context, {required String name, required int userId}) async {
  final ok = await showEmConfirm(
    context,
    title: 'Block $name?',
    message: 'You won’t see $name’s posts or replies. They aren’t told that you blocked them.',
    confirmLabel: 'Block',
    danger: true,
  );
  if (!ok) return false;
  try {
    await ModerationRepository().blockUser(userId);
    if (context.mounted) showEmToast(context, '$name is blocked');
    return true;
  } on ApiException catch (e) {
    if (context.mounted) {
      showEmToast(context, e.notAvailable ? 'Blocking isn’t available yet.' : e.message);
    }
    return false;
  }
}
