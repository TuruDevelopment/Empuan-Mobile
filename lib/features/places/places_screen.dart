import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../data/api.dart';
import '../../data/content_repository.dart';
import '../../ui/em_ui.dart';
import '../auth/form_motion.dart';
import 'place_screen.dart';

class PlacesScreen extends StatefulWidget {
  const PlacesScreen({super.key});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  final _repo = PlacesRepository();
  final _search = TextEditingController();
  List<PlaceCategory> _categories = const [];
  List<Place> _places = const [];
  int _category = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([_repo.categories(), _repo.places()]);
      _categories = results[0] as List<PlaceCategory>;
      _places = results[1] as List<Place>;
    } on ApiException catch (e) {
      _error = e.message;
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Place> get _visible {
    final q = _search.text.trim().toLowerCase();
    final categoryId = _category == 0 || _category > _categories.length ? null : _categories[_category - 1].id;
    return _places.where((p) {
      if (categoryId != null && p.categoryId != categoryId) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) || p.address.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    return Scaffold(
      appBar: const EmTopBar(title: 'Places for her'),
      body: EmStateSwitcher(
        stateKey: _loading ? 'loading' : (_error != null ? 'error' : 'content'),
        child: _loading
            ? const EmSkeletonList(thumbnail: 84, padding: EdgeInsets.fromLTRB(20, 4, 20, 32))
            : _error != null
                ? Center(child: EmStateView.error(message: _error!, onRetry: _load))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                      children: [
                        StaggerItem(
                          index: 0,
                          child: TextField(
                            controller: _search,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: 'Search by name or area',
                              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                              suffixIcon: _search.text.isEmpty
                                  ? null
                                  : IconButton(tooltip: 'Clear search', icon: const Icon(Icons.close_rounded), onPressed: _search.clear),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (_categories.isNotEmpty) ...[
                          StaggerItem(
                            index: 1,
                            child: EmChipBar(
                              labels: ['All', ..._categories.map((c) => c.name)],
                              selected: _category,
                              onSelected: (i) => setState(() => _category = i),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (visible.isEmpty)
                          StaggerItem(
                            key: ValueKey('empty-$_category-${_places.isEmpty}'),
                            index: 2,
                            child: EmStateView(
                              icon: Icons.storefront_outlined,
                              title: _places.isEmpty ? 'No places yet' : 'No places match',
                              message: _places.isEmpty ? 'We’re adding places soon.' : 'Try another name, area or category.',
                            ),
                          )
                        else
                          for (var i = 0; i < visible.length; i++) _placeItem(visible, i),
                      ],
                    ),
                  ),
      ),
    );
  }

  /// Keyed by category so switching category re-staggers the new results,
  /// while typing in search only adds or drops rows without replaying the
  /// ones still shown. Rows past the first screen just appear: animating them
  /// in as they scroll into view would only make the list feel slow.
  Widget _placeItem(List<Place> visible, int i) {
    final place = visible[i];
    final key = ValueKey('place-$_category-${place.id}');
    final child = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: i == 0 ? _FeaturedPlace(place: place) : _PlaceRow(place: place),
    );
    return i < 6 ? StaggerItem(key: key, index: i + 2, child: child) : KeyedSubtree(key: key, child: child);
  }
}

/// Hero tag for a place's photo in this list. Each list that opens a place
/// uses its own prefix so photos don't fly between two lists of places.
Object _listPhotoTag(Place place) => 'places-list-photo-${place.id}';

class PlacePhoto extends StatelessWidget {
  const PlacePhoto({super.key, required this.place, required this.height, this.width, this.radius = 14, this.heroTag});

  final Place place;
  final double height;
  final double? width;
  final double radius;

  /// When set, the photo flies to and from a [PlaceScreen] given the same tag.
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: AppColors.blush,
      child: Icon(Icons.storefront_outlined, color: AppColors.secondary, size: height > 120 ? 40 : 26),
    );
    final photo = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: place.photoUrl == null
          ? placeholder
          : Image(
image: CachedNetworkImageProvider(place.photoUrl!),
              width: width,
              height: height,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder: (_, __, ___) => placeholder,
            ),
    );
    return heroTag == null ? photo : Hero(tag: heroTag!, child: photo);
  }
}

class PlaceStatus extends StatelessWidget {
  const PlaceStatus({super.key, required this.place, this.small = false});

  final Place place;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final status = place.openStatus();
    if (status == null) return const SizedBox.shrink();
    final color = status.open ? AppColors.primary : AppColors.textSecondary;
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: status.open ? AppColors.primary : AppColors.quietIcon, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(status.label, style: TextStyle(color: color, fontSize: small ? 12 : 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _FeaturedPlace extends StatelessWidget {
  const _FeaturedPlace({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return EmCard(
      padding: EdgeInsets.zero,
      onTap: () => pushScreen(context, PlaceScreen(place: place, heroTag: _listPhotoTag(place))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlacePhoto(place: place, height: 150, width: double.infinity, radius: 0, heroTag: _listPhotoTag(place)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(place.name, style: text.titleMedium)),
                    if (place.priceLabel != null) Text(place.priceLabel!.replaceFirst('From ', ''), style: text.labelMedium),
                  ],
                ),
                const SizedBox(height: 4),
                Text(place.address, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.bodySmall),
                const SizedBox(height: 6),
                PlaceStatus(place: place),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return EmCard(
      padding: const EdgeInsets.all(12),
      onTap: () => pushScreen(context, PlaceScreen(place: place, heroTag: _listPhotoTag(place))),
      child: Row(
        children: [
          PlacePhoto(place: place, height: 84, width: 84, heroTag: _listPhotoTag(place)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(place.name, style: text.titleSmall),
                const SizedBox(height: 4),
                Text(place.address, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.bodySmall?.copyWith(fontSize: 12)),
                const SizedBox(height: 4),
                PlaceStatus(place: place, small: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
