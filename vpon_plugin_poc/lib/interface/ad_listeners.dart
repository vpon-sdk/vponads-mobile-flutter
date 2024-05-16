import 'package:flutter/cupertino.dart';

import 'ad_containers.dart';
import 'insterstitial_ad.dart';

/// The callback type to handle an event occurring for an [Ad].
typedef AdEventCallback = void Function(Ad ad);

/// Generic callback type for an event occurring on an Ad.
typedef GenericAdEventCallback<Ad> = void Function(Ad ad);

/// A callback type for when an error occurs loading a full screen ad.
typedef FullScreenAdLoadErrorCallback = void Function(Map error);

/// The callback type to handle an error loading an [Ad].
typedef AdLoadErrorCallback = void Function(Ad ad, Map error);

/// Callback events for for full screen ads, such as Interstitial.
class FullScreenContentCallback<Ad> {
  /// Construct a new [FullScreenContentCallback].
  ///
  /// [Ad.dispose] should be called from [onAdFailedToShowFullScreenContent]
  /// and [onAdDismissedFullScreenContent], in order to free up resources.
  const FullScreenContentCallback({
    this.onAdWillShowFullScreenContent,
    this.onAdImpression,
    this.onAdFailedToShowFullScreenContent,
    this.onAdWillDismissFullScreenContent,
    this.onAdDismissedFullScreenContent,
    this.onAdClicked,
  });

  /// Called when an ad is going to show full screen content.
  final GenericAdEventCallback<Ad>? onAdWillShowFullScreenContent;

  /// Called when an ad dismisses full screen content.
  final GenericAdEventCallback<Ad>? onAdDismissedFullScreenContent;

  /// For iOS only. Called before dismissing a full screen view.
  final GenericAdEventCallback<Ad>? onAdWillDismissFullScreenContent;

  /// Called when an ad impression occurs.
  final GenericAdEventCallback<Ad>? onAdImpression;

  /// Called when an ad is clicked.
  final GenericAdEventCallback<Ad>? onAdClicked;

  /// Called when ad fails to show full screen content.
  final void Function(Ad ad, Map error)? onAdFailedToShowFullScreenContent;
}

/// Generic parent class for ad load callbacks.
abstract class FullScreenAdLoadCallback<T> {
  /// Default constructor for [FullScreenAdLoadCallback[, used by subclasses.
  const FullScreenAdLoadCallback({
    required this.onAdLoaded,
    required this.onAdFailedToLoad,
  });

  /// Called when the ad successfully loads.
  final GenericAdEventCallback<T> onAdLoaded;

  /// Called when an error occurs loading the ad.
  final FullScreenAdLoadErrorCallback onAdFailedToLoad;
}

class InterstitialAdLoadCallback
    extends FullScreenAdLoadCallback<InterstitialAd> {
  const InterstitialAdLoadCallback({
    required GenericAdEventCallback<InterstitialAd> onAdLoaded,
    required FullScreenAdLoadErrorCallback onAdFailedToLoad,
    GenericAdEventCallback<InterstitialAd>? onAdWillShowFullScreenContent,
    GenericAdEventCallback<InterstitialAd>? onAdImpression,
    GenericAdEventCallback<InterstitialAd>? onAdClicked,
    GenericAdEventCallback<InterstitialAd>? onAdWillDismissFullScreenContent,
    GenericAdEventCallback<InterstitialAd>? onAdDismissedFullScreenContent,
  })  : _onAdWillShowFullScreenContent = onAdWillShowFullScreenContent,
        _onAdImpression = onAdImpression,
        _onAdClicked = onAdClicked,
        _onAdWillDismissFullScreenContent = onAdWillDismissFullScreenContent,
        _onAdDismissedFullScreenContent = onAdDismissedFullScreenContent,
        super(onAdLoaded: onAdLoaded, onAdFailedToLoad: onAdFailedToLoad);

  final GenericAdEventCallback<InterstitialAd>? _onAdWillShowFullScreenContent;
  final GenericAdEventCallback<InterstitialAd>? _onAdImpression;
  final GenericAdEventCallback<InterstitialAd>? _onAdClicked;
  final GenericAdEventCallback<InterstitialAd>? _onAdWillDismissFullScreenContent;
  final GenericAdEventCallback<InterstitialAd>? _onAdDismissedFullScreenContent;

  void onAdWillShowFullScreenContent(InterstitialAd ad) {
    _onAdWillShowFullScreenContent?.call(ad);
  }

  void onAdImpression(InterstitialAd ad) {
    _onAdImpression?.call(ad);
  }

  void onAdClicked(InterstitialAd ad) {
    _onAdClicked?.call(ad);
  }

  void onAdWillDismissFullScreenContent(InterstitialAd ad) {
    _onAdWillDismissFullScreenContent?.call(ad);
  }

  void onAdDismissedFullScreenContent(InterstitialAd ad) {
    _onAdDismissedFullScreenContent?.call(ad);
  }
}

abstract class AdWithViewListener {
  @protected
  const AdWithViewListener({
    this.onAdLoaded,
    this.onAdFailedToLoad,
    this.onAdOpened,
    this.onAdWillDismissScreen,
    this.onAdImpression,
    this.onAdClosed,
    this.onAdClicked,
  });

  final AdEventCallback? onAdLoaded;

  final AdLoadErrorCallback? onAdFailedToLoad;

  final AdEventCallback? onAdOpened;

  final AdEventCallback? onAdWillDismissScreen;

  final AdEventCallback? onAdClosed;

  final AdEventCallback? onAdImpression;

  final AdEventCallback? onAdClicked;
}

class BannerAdListener extends AdWithViewListener {
  const BannerAdListener({
    AdEventCallback? onAdLoaded,
    AdLoadErrorCallback? onAdFailedToLoad,
    AdEventCallback? onAdImpression,
    AdEventCallback? onAdClicked,
  }) : super(
          onAdLoaded: onAdLoaded,
          onAdFailedToLoad: onAdFailedToLoad,
          onAdImpression: onAdImpression,
          onAdClicked: onAdClicked,
        );
}

class NativeAdListener extends AdWithViewListener {
  NativeAdListener({
    AdEventCallback? onAdLoaded,
    Function(Ad ad, Map error)? onAdFailedToLoad,
    AdEventCallback? onAdImpression,
    AdEventCallback? onAdClicked,
  }) : super(
            onAdLoaded: onAdLoaded,
            onAdFailedToLoad: onAdFailedToLoad,
            onAdImpression: onAdImpression,
            onAdClicked: onAdClicked);
}
