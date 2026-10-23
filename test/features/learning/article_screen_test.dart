import 'package:Empuan/data/account_repository.dart';
import 'package:Empuan/data/community_repository.dart';
import 'package:Empuan/data/content_repository.dart';
import 'package:Empuan/features/learn/article_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final article = Article(
    id: 5,
    title: 'What to do if you’re harassed on the KRL',
    body: 'Harassment is never your fault.\n\nMove toward people or staff.',
    date: DateTime(2026, 10, 1),
  );

  setUp(() {
    Session.user.value = const UserProfile(id: 1, name: 'Ayu Lestari', username: 'ayu', email: 'ayu@example.com');
  });
  tearDown(() => Session.user.value = null);

  Future<_FakeArticles> pump(WidgetTester tester, List<Reply> comments) async {
    final repo = _FakeArticles(comments);
    await tester.pumpWidget(
      MaterialApp(home: ArticleScreen(article: article, categoryName: 'Safety', repository: repo)),
    );
    await tester.pumpAndSettle();
    return repo;
  }

  testWidgets('shows the article with paragraphs and an empty comments state', (tester) async {
    await pump(tester, []);

    expect(find.text('Her Voice · Safety'), findsOneWidget);
    expect(find.text(article.title), findsOneWidget);
    expect(find.text('1 Oct 2026 · 1 min read'), findsOneWidget);
    expect(find.text('Harassment is never your fault.'), findsOneWidget);
    expect(find.text('Move toward people or staff.'), findsOneWidget);
    expect(find.text('No comments yet. Start the conversation.'), findsOneWidget);
  });

  testWidgets('posts a comment and shows it', (tester) async {
    final repo = await pump(tester, []);

    await tester.enterText(find.byType(TextField), 'Saving this for my sister.');
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Post comment'));
    await tester.pumpAndSettle();

    expect(repo.posted, ['Saving this for my sister.']);
    expect(find.text('Saving this for my sister.'), findsOneWidget);
    expect(find.text('No comments yet. Start the conversation.'), findsNothing);
  });

  testWidgets('offers report and block for other people’s comments only', (tester) async {
    await pump(tester, [
      Reply(id: 1, text: 'Saying it loudly works.', authorName: 'Dewi', authorId: 2, date: DateTime.now()),
      Reply(id: 2, text: 'My own comment', authorName: 'Ayu Lestari', authorId: 1, date: DateTime.now()),
    ]);

    final options = find.byTooltip('Comment options');
    expect(options, findsOneWidget);
    await tester.ensureVisible(options);
    await tester.pumpAndSettle();
    await tester.tap(options);
    await tester.pumpAndSettle();

    expect(find.text('Report comment'), findsOneWidget);
    expect(find.text('Block Dewi'), findsOneWidget);
  });
}

class _FakeArticles extends ArticlesRepository {
  _FakeArticles(this._comments);

  final List<Reply> _comments;
  final List<String> posted = [];

  @override
  Future<List<Reply>> comments(int articleId) async => List.of(_comments);

  @override
  Future<void> addComment(int articleId, String text) async {
    posted.add(text);
    _comments
        .add(Reply(id: 100 + posted.length, text: text, authorName: 'Ayu Lestari', authorId: 1, date: DateTime.now()));
  }
}
