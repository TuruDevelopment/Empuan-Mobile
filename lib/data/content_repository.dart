import '../config/api_config.dart';
import '../ui/em_ui.dart' show apiDate, parseDate;
import 'api.dart';
import 'community_repository.dart' show Reply;

class ArticleCategory {
  const ArticleCategory(this.id, this.name);

  final int id;
  final String name;
}

class Article {
  const Article({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.date,
    this.categoryId,
  });

  final int id;
  final String title;
  final String body;
  final String? imageUrl;
  final DateTime? date;
  final int? categoryId;

  int get readMinutes {
    final words = body.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    return (words / 200).ceil().clamp(1, 60);
  }

  factory Article.fromJson(Map<String, dynamic> json) => Article(
        id: asInt(json['id']),
        title: asString(json['title']),
        body: asString(json['content']),
        imageUrl: json['media'] == null || asString(json['media']).isEmpty ? null : asString(json['media']),
        date: parseDate(json['dop'] ?? json['created_at']),
        categoryId: json['kategori_id'] == null ? null : asInt(json['kategori_id']),
      );
}

/// Her Voice articles (`/suara-puan`).
class ArticlesRepository {
  ArticlesRepository({Api? api}) : _api = api ?? Api();

  final Api _api;

  Future<List<Article>> articles() async {
    final list = asMapList(await _api.get(ApiConfig.suaraPuan)).map(Article.fromJson).toList();
    list.sort((a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)));
    return list;
  }

  Future<List<ArticleCategory>> categories() async {
    return asMapList(await _api.get(ApiConfig.kategoriSuaraPuan))
        .map((j) => ArticleCategory(asInt(j['id']), asString(j['nama'] ?? j['name'] ?? j['nama_kategori'], 'Other')))
        .toList();
  }

  Future<List<Reply>> comments(int articleId) async {
    return asMapList(await _api.get(ApiConfig.suaraPuanComments(articleId))).map(Reply.fromJson).toList();
  }

  Future<void> addComment(int articleId, String text) {
    return _api.post(ApiConfig.suaraPuanComments(articleId), body: {'comment': text, 'dop': apiDate(DateTime.now())});
  }
}

class PlaceCategory {
  const PlaceCategory(this.id, this.name);

  final int id;
  final String name;
}

class Place {
  const Place({
    required this.id,
    required this.name,
    required this.address,
    required this.description,
    this.phone,
    this.opensAt,
    this.closesAt,
    this.photoUrl,
    this.price,
    this.website,
    this.categoryId,
  });

  final int id;
  final String name;
  final String address;
  final String description;
  final String? phone;
  final String? opensAt;
  final String? closesAt;
  final String? photoUrl;
  final String? price;
  final String? website;
  final int? categoryId;

  static String? _opt(dynamic v) {
    final s = asString(v).trim();
    return s.isEmpty ? null : s;
  }

  factory Place.fromJson(Map<String, dynamic> json) => Place(
        id: asInt(json['id']),
        name: asString(json['nama'], 'Place'),
        address: asString(json['alamat']),
        description: asString(json['deskripsi']),
        phone: _opt(json['phoneNumber']),
        opensAt: _opt(json['jamBuka']),
        closesAt: _opt(json['jamTutup']),
        photoUrl: _opt(json['foto']),
        price: _opt(json['price']),
        website: _opt(json['website']),
        categoryId: json['kategori_id'] == null ? null : asInt(json['kategori_id']),
      );

  /// "Open until 21:00", "Closed · opens 09:00", or null when hours are unknown.
  ({String label, bool open})? openStatus([DateTime? now]) {
    final open = _minutes(opensAt);
    final close = _minutes(closesAt);
    if (open == null || close == null) return null;
    final t = now ?? DateTime.now();
    final m = t.hour * 60 + t.minute;
    final isOpen = close > open ? (m >= open && m < close) : (m >= open || m < close);
    return isOpen
        ? (label: 'Open until ${_hhmm(closesAt!)}', open: true)
        : (label: 'Closed · opens ${_hhmm(opensAt!)}', open: false);
  }

  String? get hoursLabel => opensAt == null || closesAt == null ? null : '${_hhmm(opensAt!)}–${_hhmm(closesAt!)}';

  /// Formats the stored price ("150000") as "From Rp 150.000".
  String? get priceLabel {
    final digits = price?.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits == null || digits.isEmpty) return price;
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
      buf.write(digits[i]);
    }
    return 'From Rp $buf';
  }

  static int? _minutes(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  static String _hhmm(String value) {
    final parts = value.split(':');
    return parts.length >= 2 ? '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}' : value;
  }
}

/// Places for her (`/untuk-puan`).
class PlacesRepository {
  PlacesRepository({Api? api}) : _api = api ?? Api();

  final Api _api;

  Future<List<PlaceCategory>> categories() async {
    return asMapList(await _api.get(ApiConfig.kategoriUntukPuan))
        .map((j) => PlaceCategory(asInt(j['id']), asString(j['nama_kategori'] ?? j['nama'], 'Other')))
        .toList();
  }

  Future<List<Place>> places() async => asMapList(await _api.get(ApiConfig.untukPuan)).map(Place.fromJson).toList();
}
