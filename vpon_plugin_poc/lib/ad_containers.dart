import 'package:flutter/cupertino.dart';

import 'ad_instance_manager.dart';
import 'ad_listeners.dart';
import 'ad_request.dart';

/// The base class for all ads.
///
/// A valid [licenseKey] is required.
abstract class Ad {
  /// Default constructor, used by subclasses.
  Ad({required this.licenseKey});

  /// Identifies the source of [Ad]s for your application.
  final String licenseKey;

  /// Frees the plugin resources associated with this ad.
  Future<void> dispose() {
    return instanceManager.disposeAd(this);
  }
}

/// An [Ad] that is overlaid on top of the UI.
abstract class AdWithoutView extends Ad {
  /// Default constructor used by subclasses.
  AdWithoutView({required String licenseKey}) : super(licenseKey: licenseKey);
}

/// A full-screen interstitial ad for the Google Mobile Ads Plugin.
class InterstitialAd extends AdWithoutView {
  /// Creates an [InterstitialAd].
  InterstitialAd._({
    required String licenseKey,
    required this.request,
    required this.adLoadCallback,
  }) : super(licenseKey: licenseKey);

  /// Targeting information used to fetch an [Ad].
  final AdRequest request;

  /// Callback to be invoked when the ad finishes loading.
  final InterstitialAdLoadCallback adLoadCallback;

  /// Callbacks to be invoked when ads show and dismiss full screen content.
  FullScreenContentCallback<InterstitialAd>? fullScreenContentCallback;

  /// Loads an [InterstitialAd] with the given [licenseKey] and [request].
  static Future<void> load({
    required String licenseKey,
    required AdRequest request,
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

/*
class AdSize {
  /// Constructs an [AdSize] with the given [width] and [height].
  const AdSize({
    required this.width,
    required this.height,
  });

  /// The vertical span of an ad.
  final int height;

  /// The horizontal span of an ad.
  final int width;

  /// The standard banner (320x50) size.
  static const AdSize banner = AdSize(width: 320, height: 50);

  /// The large banner (320x100) size.
  static const AdSize largeBanner = AdSize(width: 320, height: 100);

  /// The medium rectangle (300x250) size.
  static const AdSize mediumRectangle = AdSize(width: 300, height: 250);

  /// The full banner (468x60) size.
  static const AdSize fullBanner = AdSize(width: 468, height: 60);

  /// The leaderboard (728x90) size.
  static const AdSize leaderboard = AdSize(width: 728, height: 90);

  /// A dynamically sized banner that matches its parent's width and expands/contracts its height to match the ad's content after loading completes.
  static const AdSize fluid = FluidAdSize();

  static Future<AnchoredAdaptiveBannerAdSize?> getAnchoredAdaptiveBannerAdSize(
      Orientation orientation,
      int width,
      ) async {
    final num? height = await instanceManager.channel.invokeMethod<num?>(
      'AdSize#getAnchoredAdaptiveBannerAdSize',
      <String, Object?>{
        'orientation': orientation.name,
        'width': width,
      },
    );

    if (height == null) return null;
    return AnchoredAdaptiveBannerAdSize(
      orientation,
      width: width,
      height: height.truncate(),
    );
  }

  static Future<AnchoredAdaptiveBannerAdSize?>
  getCurrentOrientationAnchoredAdaptiveBannerAdSize(int width) async {
    final num? height = await instanceManager.channel.invokeMethod<num?>(
      'AdSize#getAnchoredAdaptiveBannerAdSize',
      <String, Object?>{
        'width': width,
      },
    );

    if (height == null) return null;
    return AnchoredAdaptiveBannerAdSize(
      null,
      width: width,
      height: height.truncate(),
    );
  }


  static InlineAdaptiveSize getCurrentOrientationInlineAdaptiveBannerAdSize(
      int width) {
    return InlineAdaptiveSize._(width: width);
  }

  static InlineAdaptiveSize getLandscapeInlineAdaptiveBannerAdSize(int width) {
    return InlineAdaptiveSize._(
        width: width, orientation: Orientation.landscape);
  }

  static InlineAdaptiveSize getPortraitInlineAdaptiveBannerAdSize(int width) {
    return InlineAdaptiveSize._(
        width: width, orientation: Orientation.portrait);
  }

  static InlineAdaptiveSize getInlineAdaptiveBannerAdSize(
      int width, int maxHeight) {
    return InlineAdaptiveSize._(width: width, maxHeight: maxHeight);
  }

  @override
  bool operator ==(Object other) {
    return other is AdSize && width == other.width && height == other.height;
  }
}*/

/// Error information about why an ad operation failed.
class AdError {
  /// Creates an [AdError] with the given [code], [domain] and [message].
  @protected
  AdError(this.code, this.domain, this.message);

  final int code;

  /// The domain from which the error came.
  final String domain;
  final String message;

  @override
  String toString() {
    return '$runtimeType(code: $code, domain: $domain, message: $message)';
  }
}

class LoadAdError extends AdError {
  /// Default constructor for [LoadAdError].
  @protected
  LoadAdError(int code, String domain, String message)
      : super(code, domain, message);

  @override
  String toString() {
    return '$runtimeType(code: $code, domain: $domain, message: $message'
        ')';
  }
}
