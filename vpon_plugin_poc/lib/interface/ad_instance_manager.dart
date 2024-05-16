import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vpon_plugin_poc/interface/logger.dart';
import 'ad_containers.dart';
import 'ad_request.dart';
import 'insterstitial_ad.dart';
import 'banner_ad.dart';
import 'native_ad.dart';

AdInstanceManager instanceManager = AdInstanceManager(
  'plugins.flutter.io/vpon',
);

/// Maintains access to loaded [Ad] instances and handles sending/receiving
/// messages to platform code.
class AdInstanceManager {
  AdInstanceManager(String channelName)
      : channel = MethodChannel(
          channelName,
          StandardMethodCodec(AdMessageCodec()),
        ) {
    channel.setMethodCallHandler((MethodCall call) async {
      VponLogger.i('channel.setMethodCallHandler $call');

      switch (call.method) {
        case 'nativeLog':
          final String message = call.arguments['message'];
          final String type = call.arguments['type'];
          _consoleLog(message, type);

        case 'onAdEvent':
          final int adId = call.arguments['adId'];
          final String eventName = call.arguments['eventName'];

          final Ad? ad = adFor(adId);
          if (ad != null) {
            _onAdEvent(ad, eventName, call.arguments);
          } else {
            VponLogger.e(
                '$Ad with id `$adId` is not available for $eventName.');
          }
          break;

        default:
          break;
      }
    });
  }

  void _consoleLog(String message, String type) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      switch (type) {
        case 'info':
          VponLogger.i('[native iOS] $message');
        case 'debug':
          VponLogger.d('[native iOS] $message');
        case 'error':
          VponLogger.e('[native iOS] $message');
      }
    }
  }

  int _nextAdId = 0;
  final _BiMap<int, Ad> _loadedAds = _BiMap<int, Ad>();

  /// Invokes load and dispose calls.
  final MethodChannel channel;

  Future<void> initialize() async {
    return (await instanceManager.channel.invokeMethod(
      'initializeSDK',
    ));
  }

  Future<void> setLogLevel(int level) async {
    return await instanceManager.channel
        .invokeMethod('setLogLevel', <String, int>{'level': level});
  }

  /// Set the [VponRequestConfiguration] to apply for future ad requests.
  Future<void> updateRequestConfiguration(
      VponRequestConfiguration requestConfiguration) {
    return channel.invokeMethod<void>(
      'updateRequestConfiguration',
      <dynamic, dynamic>{
        'maxAdContentRating': requestConfiguration.maxAdContentRating,
        'tagForChildDirectedTreatment':
            requestConfiguration.tagForChildDirectedTreatment,
        'testDeviceIds': requestConfiguration.testDeviceIds,
        'tagForUnderAgeOfConsent': requestConfiguration.tagForUnderAgeOfConsent,
      },
    );
  }

  Future<String> getVersionString() async {
    return (await instanceManager.channel
        .invokeMethod<String>('getVersionString'))!;
  }

  Future<String?> getVponID() async {
    String? id;
    try {
      final String result =
          await instanceManager.channel.invokeMethod('getVponID');
      id = result;
    } on PlatformException catch (e) {
      VponLogger.e("Failed to get id: '${e.message}'.");
    }
    return id;
  }

  Future<void> setConsentStatus(int value) async {
    try {
      await instanceManager.channel
          .invokeMethod('setConsentStatus', <String, int>{'status': value});
    } on PlatformException catch (e) {
      VponLogger.e("invokeMethod('setConsentStatus') failed: '${e.message}'.");
    }
  }

  /* ------------------------ Location Manager Service ------------------------ */

  Future<void> setLocationManagerEnable(bool isEnable) async {
    await instanceManager.channel.invokeMethod(
        'setLocationManagerEnable', <String, bool>{'isEnable': isEnable});
  }

  /* -------------------------- Audio Manager Service ------------------------- */

  Future<void> setAudioApplicationManaged(bool isManaged) async {
    try {
      await instanceManager.channel.invokeMethod(
          'setAudioApplicationManaged', <String, bool>{'isManaged': isManaged});
    } on PlatformException catch (e) {
      VponLogger.e(
          "invokeMethod('setAudioApplicationManaged') failed: '${e.message}'.");
    }
  }

  Future<void> noticeApplicationAudioWillStart() async {
    try {
      await instanceManager.channel
          .invokeMethod('noticeApplicationAudioWillStart');
    } on PlatformException catch (e) {
      VponLogger.e(
          "invokeMethod('noticeApplicationAudioWillStart') failed: '${e.message}'.");
    }
  }

  Future<void> noticeApplicationAudioDidEnd() async {
    try {
      await instanceManager.channel
          .invokeMethod('noticeApplicationAudioDidEnd');
    } on PlatformException catch (e) {
      VponLogger.e(
          "invokeMethod('noticeApplicationAudioDidEnd') failed: '${e.message}'.");
    }
  }

  Future<BannerAdSize?> getAdSize(Ad ad) =>
      instanceManager.channel.invokeMethod<BannerAdSize>(
        'getAdSize',
        <String, dynamic>{
          'adId': adIdFor(ad),
        },
      );

  /* ------------------------------- Ad Callback ------------------------------ */

  void _onAdEvent(Ad ad, String eventName, Map<dynamic, dynamic> arguments) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      _onAdEventAndroid(ad, eventName, arguments);
    } else {
      _onAdEventIOS(ad, eventName, arguments);
    }
  }

  void _onAdEventIOS(Ad ad, String eventName, Map<dynamic, dynamic> arguments) {
    VponLogger.d(
        'AdInstanceManager _onAdEventIOS called with $eventName and arg $arguments');
    switch (eventName) {
      case 'onAdLoaded':
        _invokeOnAdLoaded(ad, eventName, arguments);
        break;
      case 'onAdFailedToLoad':
        _invokeOnAdFailedToLoad(ad, eventName, arguments);
        break;
      case 'adDidRecordClick':
        _invokeOnAdClicked(ad, eventName);
        break;
      case 'adDidRecordImpression' ||
            'onBannerImpression' ||
            'onNativeAdImpression':
        _invokeOnAdImpression(ad, eventName);
        break;
      case 'adWillPresentFullScreenContent':
        _invokeOnAdWillShowFullScreenContent(ad, eventName);
        break;
      case 'adDidDismissFullScreenContent':
        _invokeOnAdDismissedFullScreenContent(ad, eventName);
        break;
      case 'adWillDismissFullScreenContent':
        if (ad is InterstitialAd) {
          ad.fullScreenContentCallback?.onAdWillDismissFullScreenContent
              ?.call(ad);
        } else {
          VponLogger.d('invalid ad : $ad, for event name: $eventName');
        }
        break;
      case 'didFailToPresentFullScreenContentWithError':
        _invokeOnAdFailedToShowFullScreenContent(ad, eventName, arguments);
        break;
      default:
        VponLogger.d('invalid ad event name: $eventName');
    }
  }

  void _onAdEventAndroid(
      Ad ad, String eventName, Map<dynamic, dynamic> arguments) {
    // switch (eventName) {
    //   case 'onAdLoaded':
    //     _invokeOnAdLoaded(ad, eventName, arguments);
    //     break;
    //   case 'onAdFailedToLoad':
    //     _invokeOnAdFailedToLoad(ad, eventName, arguments);
    //     break;
    //   case 'onAdOpened':
    //     _invokeOnAdOpened(ad, eventName);
    //     break;
    //   case 'onAdClosed':
    //     _invokeOnAdClosed(ad, eventName);
    //     break;
    //   case 'onAppEvent':
    //     _invokeOnAppEvent(ad, eventName, arguments);
    //     break;
    //   case 'onRewardedAdUserEarnedReward':
    //   case 'onRewardedInterstitialAdUserEarnedReward':
    //     _invokeOnUserEarnedReward(ad, eventName, arguments);
    //     break;
    //   case 'onAdImpression':
    //     _invokeOnAdImpression(ad, eventName);
    //     break;
    //   case 'onFailedToShowFullScreenContent':
    //     _invokeOnAdFailedToShowFullScreenContent(ad, eventName, arguments);
    //     break;
    //   case 'onAdShowedFullScreenContent':
    //     _invokeOnAdShowedFullScreenContent(ad, eventName);
    //     break;
    //   case 'onAdDismissedFullScreenContent':
    //     _invokeOnAdDismissedFullScreenContent(ad, eventName);
    //     break;
    //   case 'onPaidEvent':
    //     _invokePaidEvent(ad, eventName, arguments);
    //     break;
    //   case 'onFluidAdHeightChanged':
    //     _invokeFluidAdHeightChanged(ad, arguments);
    //     break;
    //   case 'onAdClicked':
    //     _invokeOnAdClicked(ad, eventName);
    //     break;
    //   default:
    //     debugPrint('invalid ad event name: $eventName');
    // }
  }

  void _invokeOnAdLoaded(
      Ad ad, String eventName, Map<dynamic, dynamic> arguments) {
    if (ad is AdWithView) {
      ad.listener.onAdLoaded?.call(ad);
    } else if (ad is InterstitialAd) {
      ad.adLoadCallback.onAdLoaded.call(ad);
    } else {
      VponLogger.d('invalid ad: $ad, for event name: $eventName');
    }
  }

  void _invokeOnAdFailedToLoad(
      Ad ad, String eventName, Map<dynamic, dynamic> arguments) {
    if (ad is AdWithView) {
      ad.listener.onAdFailedToLoad?.call(ad, arguments['loadAdError']);
    } else if (ad is InterstitialAd) {
      ad.dispose();
      ad.adLoadCallback.onAdFailedToLoad.call(arguments['loadAdError']);
    } else {
      VponLogger.d('invalid ad: $ad, for event name: $eventName');
    }
  }

  void _invokeOnAdWillShowFullScreenContent(Ad ad, String eventName) {
    if (ad is InterstitialAd) {
      ad.fullScreenContentCallback?.onAdWillShowFullScreenContent?.call(ad);
    } else {
      VponLogger.d('invalid ad: $ad, for event name: $eventName');
    }
  }

  void _invokeOnAdDismissedFullScreenContent(Ad ad, String eventName) {
    if (ad is InterstitialAd) {
      ad.fullScreenContentCallback?.onAdDismissedFullScreenContent?.call(ad);
    } else {
      VponLogger.d('invalid ad: $ad, for event name: $eventName');
    }
  }

  void _invokeOnAdFailedToShowFullScreenContent(
      Ad ad, String eventName, Map<dynamic, dynamic> arguments) {
    if (ad is InterstitialAd) {
      ad.fullScreenContentCallback?.onAdFailedToShowFullScreenContent
          ?.call(ad, arguments['error']);
    } else {
      VponLogger.d('invalid ad: $ad, for event name: $eventName');
    }
  }

  void _invokeOnAdImpression(Ad ad, String eventName) {
    if (ad is AdWithView) {
      ad.listener.onAdImpression?.call(ad);
    } else if (ad is InterstitialAd) {
      ad.fullScreenContentCallback?.onAdImpression?.call(ad);
    } else {
      VponLogger.d('invalid ad: $ad, for event name: $eventName');
    }
  }

  void _invokeOnAdClicked(Ad ad, String eventName) {
    if (ad is AdWithView) {
      ad.listener.onAdClicked?.call(ad);
    } else if (ad is InterstitialAd) {
      ad.fullScreenContentCallback?.onAdClicked?.call(ad);
    } else {
      VponLogger.d('invalid ad: $ad, for event name: $eventName');
    }
  }

  /* ----------------------------- Load & Show Ad ----------------------------- */

  /// Returns null if an invalid [adId] was passed in.
  Ad? adFor(int adId) => _loadedAds[adId];

  /// Returns null if an invalid [Ad] was passed in.
  int? adIdFor(Ad ad) => _loadedAds.inverse[ad];

  final Set<int> _mountedWidgetAdIds = <int>{};

  /// Returns true if the [adId] is already mounted in a [WidgetAd].
  bool isWidgetAdIdMounted(int adId) => _mountedWidgetAdIds.contains(adId);

  /// Indicates that [adId] is mounted in widget tree.
  void mountWidgetAdId(int adId) => _mountedWidgetAdIds.add(adId);

  /// Indicates that [adId] is unmounted from the widget tree.
  void unmountWidgetAdId(int adId) => _mountedWidgetAdIds.remove(adId);

  /// Starts loading the ad if not previously loaded.
  ///
  /// Does nothing if we have already tried to load the ad.
  Future<void> loadBannerAd(BannerAd ad) {
    if (adIdFor(ad) != null) {
      return Future<void>.value();
    }

    final int adId = _nextAdId++;
    _loadedAds[adId] = ad;
    return channel.invokeMethod<void>(
      'loadBannerAd',
      <String, dynamic>{
        'adId': adId,
        'licenseKey': ad.licenseKey,
        'request': ad.request,
        'size': ad.size,
      },
    );
  }

  Future<void> loadInterstitialAd(InterstitialAd ad) {
    if (adIdFor(ad) != null) {
      return Future<void>.value();
    }

    final int adId = _nextAdId++;
    _loadedAds[adId] = ad;
    VponLogger.d('channel.invokeMethod loadInterstitialAd, request: $ad');
    return channel.invokeMethod<void>(
      'loadInterstitialAd',
      <String, dynamic>{
        'adId': adId,
        'licenseKey': ad.licenseKey,
        'request': ad.request,
      },
    );
  }

  /// Starts loading the ad if not previously loaded.
  ///
  /// Loading also terminates if ad is already in the process of loading.
  Future<void> loadNativeAd(NativeAd ad) {
    if (adIdFor(ad) != null) {
      return Future<void>.value();
    }

    final int adId = _nextAdId++;
    _loadedAds[adId] = ad;
    return channel.invokeMethod<void>(
      'loadNativeAd',
      <String, dynamic>{
        'adId': adId,
        'licenseKey': ad.licenseKey,
        'request': ad.request,
        'factoryId': ad.factoryId,
      },
    );
  }

  /// Free the plugin resources associated with this ad.
  ///
  /// Disposing a banner ad that's been shown removes it from the screen.
  /// Interstitial ads can't be programmatically removed from view.
  Future<void> disposeAd(Ad ad) {
    final int? adId = adIdFor(ad);
    final Ad? disposedAd = _loadedAds.remove(adId);
    if (disposedAd == null) {
      return Future<void>.value();
    }
    return channel.invokeMethod<void>(
      'disposeAd',
      <dynamic, dynamic>{
        'adId': adId,
      },
    );
  }

  /// Display an [AdWithoutView] that is overlaid on top of the application.
  Future<void> showAdWithoutView(AdWithoutView ad) {
    VponLogger.d('instanceManager call showAdWithoutView');
    assert(
      adIdFor(ad) != null,
      '$Ad has not been loaded or has already been disposed.',
    );

    return channel.invokeMethod<void>(
      'showAdWithoutView',
      <dynamic, dynamic>{
        'adId': adIdFor(ad),
      },
    );
  }
}

@visibleForTesting
class AdMessageCodec extends StandardMessageCodec {
  // The type values below must be consistent for each platform.
  static const int _valueAdSize = 128;
  static const int _valueAdRequest = 129;
  static const int _valueRequestConfigurationParams = 148;

  @override
  void writeValue(WriteBuffer buffer, dynamic value) {
    if (value is BannerAdSize) {
      writeAdSize(buffer, value);
    } else if (value is VponAdRequest) {
      buffer.putUint8(_valueAdRequest);
      writeValue(buffer, value.contentUrl);
      writeValue(buffer, value.contentData);
      writeValue(buffer, value.keywords);
    } else if (value is VponRequestConfiguration) {
      buffer.putUint8(_valueRequestConfigurationParams);
      writeValue(buffer, value.maxAdContentRating);
      writeValue(buffer, value.tagForChildDirectedTreatment);
      writeValue(buffer, value.tagForUnderAgeOfConsent);
      writeValue(buffer, value.testDeviceIds);
    } else {
      super.writeValue(buffer, value);
    }
  }

  void writeAdSize(WriteBuffer buffer, BannerAdSize value) {
    buffer.putUint8(_valueAdSize);
    writeValue(buffer, value.width);
    writeValue(buffer, value.height);
  }

  @override
  dynamic readValueOfType(dynamic type, ReadBuffer buffer) {
    switch (type) {
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}

class _BiMap<K extends Object, V extends Object> extends MapBase<K, V> {
  _BiMap() {
    _inverse = _BiMap<V, K>._inverse(this);
  }

  _BiMap._inverse(this._inverse);

  final Map<K, V> _map = <K, V>{};
  late _BiMap<V, K> _inverse;

  _BiMap<V, K> get inverse => _inverse;

  @override
  V? operator [](Object? key) => _map[key];

  @override
  void operator []=(K key, V value) {
    assert(!_map.containsKey(key));
    assert(!inverse.containsKey(value));
    _map[key] = value;
    inverse._map[value] = key;
  }

  @override
  void clear() {
    _map.clear();
    inverse._map.clear();
  }

  @override
  Iterable<K> get keys => _map.keys;

  @override
  V? remove(Object? key) {
    if (key == null) return null;
    final V? value = _map[key];
    inverse._map.remove(value);
    return _map.remove(key);
  }
}
