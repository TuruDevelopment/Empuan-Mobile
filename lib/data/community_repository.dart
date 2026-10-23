import '../config/api_config.dart';
import '../ui/em_ui.dart' show apiDate, parseDate;
import 'api.dart';

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.text,
    required this.likes,
    required this.comments,
    required this.liked,
    this.date,
    this.authorId,
    this.authorName,
  });

  final int id;
  final String text;
  final int likes;
  final int comments;
  final bool liked;
  final DateTime? date;
  final int? authorId;
  final String? authorName;

  CommunityPost copyWith({int? likes, bool? liked, int? comments}) => CommunityPost(
        id: id,
        text: text,
        likes: likes ?? this.likes,
        comments: comments ?? this.comments,
        liked: liked ?? this.liked,
        date: date,
        authorId: authorId,
        authorName: authorName,
      );

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    final user = asMap(json['user']);
    return CommunityPost(
      id: asInt(json['id']),
      text: asString(json['threadName']),
      likes: asInt(json['likes_total'] ?? json['like']),
      comments: asInt(json['comments_count']),
      liked: asBool(json['is_liked']),
      date: parseDate(json['created_at'] ?? json['threadDate']),
      authorId: user.isEmpty ? (json['user_id'] == null ? null : asInt(json['user_id'])) : asInt(user['id']),
      authorName: user.isEmpty ? null : asString(user['name']),
    );
  }
}

class Reply {
  const Reply({required this.id, required this.text, required this.authorName, this.authorId, this.date});

  final int id;
  final String text;
  final String authorName;
  final int? authorId;
  final DateTime? date;

  factory Reply.fromJson(Map<String, dynamic> json) {
    final user = asMap(json['user']);
    return Reply(
      id: asInt(json['id']),
      text: asString(json['comment']),
      authorName: asString(user['name'], 'Member'),
      authorId: user['id'] == null ? null : asInt(user['id']),
      date: parseDate(json['created_at'] ?? json['dop']),
    );
  }
}

/// Her Space (`/ruang-puan`).
class CommunityRepository {
  CommunityRepository({Api? api}) : _api = api ?? Api();

  final Api _api;
  static const pageSize = 10;

  Future<List<CommunityPost>> posts({int page = 1}) async {
    final json = await _api.get(ApiConfig.ruangPuan, query: {'page': '$page', 'per_page': '$pageSize'});
    return asMapList(json).map(CommunityPost.fromJson).toList();
  }

  Future<void> createPost(String text) {
    return _api.post(ApiConfig.ruangPuan, body: {'threadName': text, 'threadDate': apiDate(DateTime.now()), 'like': 0});
  }

  /// Returns the new like state and total.
  Future<(bool, int)> toggleLike(int postId) async {
    final data = asMap(asMap(await _api.post(ApiConfig.ruangPuanLike(postId)))['data']);
    return (asBool(data['liked']), asInt(data['likes_total']));
  }

  Future<List<Reply>> replies(int postId) async {
    return asMapList(await _api.get(ApiConfig.ruangPuanComments(postId))).map(Reply.fromJson).toList();
  }

  Future<void> addReply(int postId, String text) {
    return _api.post(ApiConfig.ruangPuanComments(postId), body: {'comment': text, 'dop': apiDate(DateTime.now())});
  }
}

enum ReportTarget { communityPost, communityReply, articleComment, aiAnswer }

/// Reporting and blocking, required for user-generated and AI content on Google Play.
class ModerationRepository {
  ModerationRepository({Api? api}) : _api = api ?? Api();

  final Api _api;

  static const _targetNames = {
    ReportTarget.communityPost: 'ruang_puan_post',
    ReportTarget.communityReply: 'ruang_puan_comment',
    ReportTarget.articleComment: 'suara_puan_comment',
    ReportTarget.aiAnswer: 'chatbot_message',
  };

  Future<void> report({
    required ReportTarget target,
    required String targetId,
    required String reason,
    String? details,
  }) {
    return _api.post(ApiConfig.reports, body: {
      'target_type': _targetNames[target],
      'target_id': targetId,
      'reason': reason,
      if (details != null && details.trim().isNotEmpty) 'details': details.trim(),
    });
  }

  Future<void> blockUser(int userId) => _api.post(ApiConfig.blocks, body: {'user_id': userId});
}
