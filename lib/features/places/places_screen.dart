import 'package:flutter/material.dart';

import '../../data/api.dart';
import '../../data/content_repository.dart';
import '../../ui/em_ui.dart';
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
      body: _loading
          ? const EmLoading()
          : _error != null
              ? Center(child: EmStateView.error(message: _error!, onRetry: _load))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    children: [
                      TextField(
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
                      const SizedBox(height: 14),
                      if (_categories.isNotEmpty) ...[
                        EmChipBar(
                          labels: ['All', ..._categories.map((c) => c.name)],
                          selected: _category,
                          onSelected: (i) => setState(() => _category = i),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (visible.isEmpty)
                        EmStateView(
                          icon: Icons.storefront_outlined,
                          title: _places.isEmpty ? 'No places yet' : 'No places match',
                          message: _places.isEmpty ? 'We’re adding places soon.' : 'Try another name, area or category.',
                        )
                      else
                        for (var i = 0; i < visible.length; i++) ...[
                          if (i == 0) _FeaturedPlace(place: visible[i]) else _PlaceRow(place: visible[i]),
                          const SizedBox(height: 12),
                        ],
                    ],
                  ),
                ),
    );
  }
}

class PlacePhoto extends StatelessWidget {
  const PlacePhoto({super.key, required this.place, required this.height, this.width, this.radius = 14});

  final Place place;
  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: AppColors.blush,
      child: Icon(Icons.storefront_outlined, color: AppColors.secondary, size: height > 120 ? 40 : 26),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: place.photoUrl == null
          ? placeholder
          : Image.network(
              place.photoUrl!,
              width: width,
              height: height,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder: (_, __, ___) => placeholder,
            ),
    );
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
      onTap: () => pushScreen(context, PlaceScreen(place: place)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlacePhoto(place: place, height: 150, width: double.infinity, radius: 0),
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
      onTap: () => pushScreen(context, PlaceScreen(place: place)),
      child: Row(
        children: [
          PlacePhoto(place: place, height: 84, width: 84),
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
