import 'package:flutter/foundation.dart';

import 'ad_containers.dart';
import 'ad_listeners.dart';
import 'ad_request.dart';
import 'ad_instance_manager.dart';

/// A full-screen interstitial ad for the Vpon Plugin.
class InterstitialAd extends AdWithoutView {
  /// Creates an [InterstitialAd].
  InterstitialAd._({
    required String licenseKey,
    required this.request,
    required this.adLoadCallback,
  }) : super(licenseKey: licenseKey);

  /// Targeting information used to fetch an [Ad].
  final VponAdRequest request;

  /// Callback to be invoked when the ad finishes loading.
  final InterstitialAdLoadCallback adLoadCallback;

  /// Callbacks to be invoked when ads show and dismiss full screen content.
  FullScreenContentCallback<InterstitialAd>? fullScreenContentCallback;

  /// Loads an [InterstitialAd] with the given [licenseKey] and [request].
  static Future<void> load({
    required String licenseKey,
    required VponAdRequest request,
    required InterstitialAdLoadCallback adLoadCallback,
  }) async {
    InterstitialAd ad = InterstitialAd._(
        licenseKey: licenseKey,
        adLoadCallback: adLoadCallback,
        request: request);

    await instanceManager.loadInterstitialAd(ad);
  }

  /// Displays this on top of the application.
  ///
  /// Set [fullScreenContentCallback] before calling this method to be
  /// notified of events that occur when showing the ad.
  Future<void> show() {
    debugPrint('InterstitialAd call show()');
    return instanceManager.showAdWithoutView(this);
  }
}