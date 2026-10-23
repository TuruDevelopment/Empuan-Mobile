import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/content_repository.dart';
import '../../ui/em_ui.dart';
import '../safety/sos_controller.dart';
import 'places_screen.dart';

class PlaceScreen extends StatelessWidget {
  const PlaceScreen({super.key, required this.place});

  final Place place;

  Future<void> _open(BuildContext context, Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Falls through to the toast.
    }
    if (context.mounted) showEmToast(context, 'Couldn’t open that link.');
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final directions = Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': '${place.name}, ${place.address}'});
    final website = place.website == null
        ? null
        : Uri.tryParse(place.website!.startsWith('http') ? place.website! : 'https://${place.website}');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: AppColors.background,
            automaticallyImplyLeading: false,
            leading: Padding(
              padding: const EdgeInsets.all(6),
              child: EmIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                label: 'Back',
                style: EmIconButtonStyle.soft,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(6),
                child: EmIconButton(
                  icon: Icons.share_outlined,
                  label: 'Share place',
                  style: EmIconButtonStyle.soft,
                  onPressed: () => SharePlus.instance.share(ShareParams(text: '${place.name}\n${place.address}\n$directions')),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(background: PlacePhoto(place: place, height: 250, width: double.infinity, radius: 0)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            sliver: SliverList.list(
              children: [
                Text(place.name, style: text.headlineMedium),
                const SizedBox(height: 8),
                PlaceStatus(place: place),
                const SizedBox(height: 18),
                Row(
                  children: [
                    if (place.phone != null)
                      _QuickAction(icon: Icons.call_outlined, label: 'Call', onTap: () => SosController.dial(place.phone!)),
                    _QuickAction(icon: Icons.directions_outlined, label: 'Directions', onTap: () => _open(context, directions)),
                    if (website != null) _QuickAction(icon: Icons.language_rounded, label: 'Website', onTap: () => _open(context, website)),
                  ].expand((w) => [Expanded(child: w), const SizedBox(width: 8)]).toList()
                    ..removeLast(),
                ),
                const SizedBox(height: 18),
                EmGroup(
                  children: [
                    if (place.address.isNotEmpty) EmRow(leading: const EmIconTile(Icons.location_on_outlined), title: place.address),
                    if (place.hoursLabel != null) EmRow(leading: const EmIconTile(Icons.schedule_rounded), title: 'Every day, ${place.hoursLabel}'),
                    if (place.priceLabel != null) EmRow(leading: const EmIconTile(Icons.sell_outlined), title: place.priceLabel!),
                    if (place.phone != null) EmRow(leading: const EmIconTile(Icons.call_outlined), title: place.phone!),
                  ],
                ),
                if (place.description.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('About', style: text.titleMedium),
                  const SizedBox(height: 8),
                  Text(place.description, style: text.bodyMedium),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.blush,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
