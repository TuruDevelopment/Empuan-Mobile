import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../styles/style.dart';

typedef ChatLinkLauncher = Future<void> Function(Uri uri);

class ChatMarkdownMessage extends StatelessWidget {
  const ChatMarkdownMessage({
    super.key,
    required this.data,
    this.linkLauncher,
  });

  final String data;
  final ChatLinkLauncher? linkLauncher;

  @override
  Widget build(BuildContext context) {
    final baseStyle = const TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: 14,
      color: AppColors.textPrimary,
      height: 1.5,
    );

    return MarkdownBody(
      data: data,
      selectable: true,
      softLineBreak: true,
      onTapLink: (text, href, title) {
        final uri = href == null ? null : Uri.tryParse(href);
        if (uri == null || !_isAllowedLink(uri)) {
          return;
        }

        unawaited(_openLink(context, uri));
      },
      styleSheet: MarkdownStyleSheet(
        p: baseStyle,
        pPadding: EdgeInsets.zero,
        a: baseStyle.copyWith(
          color: AppColors.primary,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
        strong: const TextStyle(fontWeight: FontWeight.w700),
        em: const TextStyle(fontStyle: FontStyle.italic),
        del: const TextStyle(decoration: TextDecoration.lineThrough),
        h1: baseStyle.copyWith(
          fontSize: 20,
          height: 1.3,
          fontWeight: FontWeight.w700,
        ),
        h1Padding: const EdgeInsets.only(bottom: 6),
        h2: baseStyle.copyWith(
          fontSize: 18,
          height: 1.35,
          fontWeight: FontWeight.w700,
        ),
        h2Padding: const EdgeInsets.only(bottom: 6),
        h3: baseStyle.copyWith(
          fontSize: 16,
          height: 1.4,
          fontWeight: FontWeight.w700,
        ),
        h3Padding: const EdgeInsets.only(bottom: 4),
        h4: baseStyle.copyWith(fontWeight: FontWeight.w700),
        h5: baseStyle.copyWith(fontWeight: FontWeight.w700),
        h6: baseStyle.copyWith(fontWeight: FontWeight.w700),
        blockSpacing: 10,
        listIndent: 20,
        listBullet: baseStyle.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
        listBulletPadding: const EdgeInsets.only(right: 6),
        blockquote: baseStyle.copyWith(color: AppColors.textSecondary),
        blockquotePadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        blockquoteDecoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: const Border(
            left: BorderSide(color: AppColors.primary, width: 3),
          ),
        ),
        code: baseStyle.copyWith(
          fontFamily: 'monospace',
          fontSize: 13,
          backgroundColor: AppColors.background,
        ),
        codeblockPadding: const EdgeInsets.all(12),
        codeblockDecoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.45)),
        ),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.accent.withValues(alpha: 0.7),
              width: 1,
            ),
          ),
        ),
        tableHead: baseStyle.copyWith(fontWeight: FontWeight.w700),
        tableBody: baseStyle,
        tableBorder: TableBorder.all(
          color: AppColors.accent.withValues(alpha: 0.6),
        ),
        tableCellsPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
      ),
    );
  }

  bool _isAllowedLink(Uri uri) {
    return uri.hasScheme &&
        (uri.scheme.toLowerCase() == 'https' ||
            uri.scheme.toLowerCase() == 'http');
  }

  Future<void> _openLink(BuildContext context, Uri uri) async {
    try {
      if (linkLauncher != null) {
        await linkLauncher!(uri);
        return;
      }

      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        _showLinkError(context);
      }
    } catch (_) {
      if (context.mounted) {
        _showLinkError(context);
      }
    }
  }

  void _showLinkError(BuildContext context) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('Tautan tidak dapat dibuka.')),
    );
  }
}
