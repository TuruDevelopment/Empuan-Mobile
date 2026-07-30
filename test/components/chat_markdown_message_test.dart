import 'package:Empuan/components/chat_markdown_message.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject(
    String data, {
    ChatLinkLauncher? linkLauncher,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ChatMarkdownMessage(
          data: data,
          linkLauncher: linkLauncher,
        ),
      ),
    );
  }

  List<InlineSpan> renderedSpans(WidgetTester tester) {
    return [
      ...tester.widgetList<SelectableText>(find.byType(SelectableText)).map(
            (widget) => widget.textSpan ?? TextSpan(text: widget.data ?? ''),
          ),
      ...tester
          .widgetList<RichText>(find.byType(RichText))
          .map((widget) => widget.text),
    ];
  }

  String renderedText(WidgetTester tester) {
    return renderedSpans(tester).map((span) => span.toPlainText()).join('\n');
  }

  bool hasBoldText(InlineSpan span, String text) {
    if (span is! TextSpan) {
      return false;
    }

    if (span.text == text &&
        (span.style?.fontWeight == FontWeight.bold ||
            span.style?.fontWeight == FontWeight.w700)) {
      return true;
    }

    return span.children?.any((child) => hasBoldText(child, text)) ?? false;
  }

  bool hasTapRecognizer(InlineSpan span) {
    if (span is! TextSpan) {
      return false;
    }

    if (span.recognizer is TapGestureRecognizer) {
      return true;
    }

    return span.children?.any(hasTapRecognizer) ?? false;
  }

  testWidgets('renders common assistant markdown without raw markers',
      (tester) async {
    await tester.pumpWidget(
      buildSubject(
        '# Ringkasan\n\n'
        '* **Halo?**\n'
        '* Pilihan kedua\n\n'
        '> Catatan penting\n\n'
        '`kode`',
      ),
    );

    final text = renderedText(tester);
    expect(text, contains('Ringkasan'));
    expect(text, contains('Halo?'));
    expect(text, contains('Pilihan kedua'));
    expect(text, contains('Catatan penting'));
    expect(text, contains('kode'));
    expect(text, isNot(contains('**')));
    expect(text, isNot(contains('# Ringkasan')));

    expect(
      renderedSpans(tester).any((span) => hasBoldText(span, 'Halo?')),
      isTrue,
    );
  });

  testWidgets('handles incomplete markdown while a response is streaming',
      (tester) async {
    await tester.pumpWidget(buildSubject('Jawaban sedang **diproses'));

    expect(renderedText(tester), contains('Jawaban sedang **diproses'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens only http and https markdown links', (tester) async {
    final openedUris = <Uri>[];

    await tester.pumpWidget(
      buildSubject(
        '[Dokumentasi](https://example.com)',
        linkLauncher: (uri) async => openedUris.add(uri),
      ),
    );

    final safeLink = find.byWidgetPredicate(
      (widget) =>
          widget is SelectableText &&
          (widget.textSpan?.toPlainText() ?? widget.data ?? '')
              .contains('Dokumentasi'),
    );
    await tester.tap(safeLink);
    await tester.pump();

    expect(openedUris, [Uri.parse('https://example.com')]);

    await tester.pumpWidget(
      buildSubject(
        '[Jangan buka](javascript:alert(1))',
        linkLauncher: (uri) async => openedUris.add(uri),
      ),
    );

    final unsafeLink = find.byWidgetPredicate(
      (widget) =>
          widget is SelectableText &&
          (widget.textSpan?.toPlainText() ?? widget.data ?? '')
              .contains('Jangan buka'),
    );
    final unsafeText = tester.widget<SelectableText>(unsafeLink);
    final unsafeSpan =
        unsafeText.textSpan ?? TextSpan(text: unsafeText.data ?? '');
    expect(
      hasTapRecognizer(unsafeSpan),
      isTrue,
    );

    await tester.tap(unsafeLink);
    await tester.pump();
    expect(openedUris, [Uri.parse('https://example.com')]);
  });
}
