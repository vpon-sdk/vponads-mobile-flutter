import 'package:flutter/cupertino.dart';

import 'ad_containers.dart';
import 'interstitial_ad.dart';

typedef AdEventCallback = void Function(Ad ad);
typedef GenericAdEventCallback<Ad> = void Function(Ad ad);
typedef FullScreenAdLoadErrorCallback = void Function(Map error);
typedef AdLoadErrorCallback = void Function(Ad ad, Map error);
class FullScreenContentCallback<Ad> {
  const FullScreenContentCallback({
    this.onAdWillShowFullScreenContent,
    this.onAdImpression,
    this.onAdFailedToShowFullScreenContent,
    this.onAdWillDismissFullScreenContent,
    this.onAdDismissedFullScreenContent,
    this.onAdClicked,
  });

  final GenericAdEventCallback<Ad>? onAdWillShowFullScreenContent;

  final GenericAdEventCallback<Ad>? onAdDismissedFullScreenContent;

  final GenericAdEventCallback<Ad>? onAdWillDismissFullScreenContent;

  final GenericAdEventCallback<Ad>? onAdImpression;

  final GenericAdEventCallback<Ad>? onAdClicked;

  final void Function(Ad ad, Map error)? onAdFailedToShowFullScreenContent;
}

abstract class FullScreenAdLoadCallback<T> {
  const FullScreenAdLoadCallback({
    required this.onAdLoaded,
    required this.onAdFailedToLoad,
  });

  final GenericAdEventCallback<T> onAdLoaded;

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
