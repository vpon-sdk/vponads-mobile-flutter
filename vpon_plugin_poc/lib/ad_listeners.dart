import 'package:flutter/cupertino.dart';

import 'ad_containers.dart';

/// The callback type to handle an event occurring for an [Ad].
typedef AdEventCallback = void Function(Ad ad);

/// Generic callback type for an event occurring on an Ad.
typedef GenericAdEventCallback<Ad> = void Function(Ad ad);

/// A callback type for when an error occurs loading a full screen ad.
typedef FullScreenAdLoadErrorCallback = void Function(LoadAdError error);

/// The callback type to handle an error loading an [Ad].
typedef AdLoadErrorCallback = void Function(Ad ad, LoadAdError error);

/// Callback events for for full screen ads, such as Interstitial.
class FullScreenContentCallback<Ad> {
  /// Construct a new [FullScreenContentCallback].
  ///
  /// [Ad.dispose] should be called from [onAdFailedToShowFullScreenContent]
  /// and [onAdDismissedFullScreenContent], in order to free up resources.
  const FullScreenContentCallback({
    this.onAdShowedFullScreenContent,
    this.onAdImpression,
    this.onAdFailedToShowFullScreenContent,
    this.onAdWillDismissFullScreenContent,
    this.onAdDismissedFullScreenContent,
    this.onAdClicked,
  });

  /// Called when an ad shows full screen content.
  final GenericAdEventCallback<Ad>? onAdShowedFullScreenContent;

  /// Called when an ad dismisses full screen content.
  final GenericAdEventCallback<Ad>? onAdDismissedFullScreenContent;

  /// For iOS only. Called before dismissing a full screen view.
  final GenericAdEventCallback<Ad>? onAdWillDismissFullScreenContent;

  /// Called when an ad impression occurs.
  final GenericAdEventCallback<Ad>? onAdImpression;

  /// Called when an ad is clicked.
  final GenericAdEventCallback<Ad>? onAdClicked;

  /// Called when ad fails to show full screen content.
  final void Function(Ad ad, AdError error)? onAdFailedToShowFullScreenContent;
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
  /// Construct a [InterstitialAdLoadCallback].
  const InterstitialAdLoadCallback({
    required GenericAdEventCallback<InterstitialAd> onAdLoaded,
    required FullScreenAdLoadErrorCallback onAdFailedToLoad,
  }) : super(onAdLoaded: onAdLoaded, onAdFailedToLoad: onAdFailedToLoad);
}

/// Shared event callbacks used in Native and Banner ads.
abstract class AdWithViewListener {
  /// Default constructor for [AdWithViewListener], meant to be used by subclasses.
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

  /// Called when an ad is successfully received.
  final AdEventCallback? onAdLoaded;

  /// Called when an ad request failed.
  final AdLoadErrorCallback? onAdFailedToLoad;

  /// A full screen view/overlay is presented in response to the user clicking
  /// on an ad. You may want to pause animations and time sensitive
  /// interactions.
  final AdEventCallback? onAdOpened;

  /// For iOS only. Called before dismissing a full screen view.
  final AdEventCallback? onAdWillDismissScreen;

  /// Called when the full screen view has been closed. You should restart
  /// anything paused while handling onAdOpened.
  final AdEventCallback? onAdClosed;

  /// Called when an impression occurs on the ad.
  final AdEventCallback? onAdImpression;

  /// Called when the ad is clicked.
  final AdEventCallback? onAdClicked;
}

/// A listener for receiving notifications for the lifecycle of a [BannerAd].
class BannerAdListener extends AdWithViewListener {
  /// Constructs a [BannerAdListener] that notifies for the provided event callbacks.
  ///
  /// Typically you will override [onAdLoaded] and [onAdFailedToLoad]:
  /// ```dart
  /// BannerAdListener(
  ///   onAdLoaded: (ad) {
  ///     // Ad successfully loaded - display an AdWidget with the banner ad.
  ///   },
  ///   onAdFailedToLoad: (ad, error) {
  ///     // Ad failed to load - log the error and dispose the ad.
  ///   },
  ///   ...
  /// )
  /// ```
  const BannerAdListener({
    AdEventCallback? onAdLoaded,
    AdLoadErrorCallback? onAdFailedToLoad,
    AdEventCallback? onAdOpened,
    AdEventCallback? onAdClosed,
    AdEventCallback? onAdWillDismissScreen,
    AdEventCallback? onAdImpression,
    AdEventCallback? onAdClicked,
  }) : super(
    onAdLoaded: onAdLoaded,
    onAdFailedToLoad: onAdFailedToLoad,
    onAdOpened: onAdOpened,
    onAdClosed: onAdClosed,
    onAdWillDismissScreen: onAdWillDismissScreen,
    onAdImpression: onAdImpression,
    onAdClicked: onAdClicked,
  );
}