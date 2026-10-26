import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/app_version_repository.dart';
import '../../services/api_client.dart';
import '../../ui/em_ui.dart';
import 'update_required_screen.dart';

/// Shows the blocking update screen when the server says this build is too
/// old, either at startup or through a 426 on any request.
class UpdateGate {
  static bool _showing = false;

  /// True once the update screen has replaced the app.
  static bool get showing => _showing;

  /// Replaces every route with [UpdateRequiredScreen]. Several requests can
  /// fail with 426 at once; only the first one pushes it.
  static void require(AppVersionStatus status) {
    if (_showing) return;
    final navigator = navigatorKey.currentState;
    // Too early to navigate; the next request or the startup check will retry.
    if (navigator == null) return;
    _showing = true;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => UpdateRequiredScreen(status: status)),
      (_) => false,
    );
  }

  @visibleForTesting
  static void reset() => _showing = false;
}

const _playStoreUrl = 'https://play.google.com/store/apps/details?id=com.turudev.empuan';
const _appStoreSearchUrl = 'https://apps.apple.com/search?term=Empuan';

/// Starts the update. On Android this is Google Play's in-app immediate
/// update when Play offers one (it doesn't for sideloaded or debug builds),
/// otherwise the store page. Returns false when nothing could be opened.
Future<bool> openAppUpdate(String? storeUrl) async {
  final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  if (android) {
    try {
      final info = await InAppUpdate.checkForUpdate();
      final ready = info.updateAvailability == UpdateAvailability.updateAvailable ||
          info.updateAvailability == UpdateAvailability.developerTriggeredUpdateInProgress;
      if (ready && info.immediateUpdateAllowed) {
        final result = await InAppUpdate.performImmediateUpdate();
        // Declining is the user's choice; don't bounce them to the store too.
        if (result != AppUpdateResult.inAppUpdateFailed) return true;
      }
    } catch (_) {
      // Not installed from Play, or Play services are missing.
    }
  }
  final url = storeUrl ?? (android ? _playStoreUrl : _appStoreSearchUrl);
  try {
    return await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// The optional "new version" sheet. The caller decides whether it's due.
Future<void> showUpdateAvailableSheet(BuildContext context, AppVersionStatus status) {
  final version = status.latestVersion;
  return showEmSheet<void>(
    context,
    builder: (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EmFadeSlideIn(
          child: EmSheetHeader(
            icon: Icons.system_update_rounded,
            title: version.isEmpty ? 'A new version of Empuan is ready' : 'Empuan $version is ready',
            message: 'Update to get the latest fixes and improvements. It only takes a minute.',
          ),
        ),
        const SizedBox(height: 20),
        EmFadeSlideIn(
          index: 1,
          child: EmButton(
            label: 'Update now',
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (!await openAppUpdate(status.storeUrl) && context.mounted) {
                showEmToast(context, 'Couldn’t open the store. Search for Empuan there to update.');
              }
            },
          ),
        ),
        const SizedBox(height: 8),
        EmFadeSlideIn(
          index: 2,
          child: EmButton(label: 'Not now', variant: EmButtonVariant.text, onPressed: () => Navigator.of(ctx).pop()),
        ),
      ],
    ),
  );
}
