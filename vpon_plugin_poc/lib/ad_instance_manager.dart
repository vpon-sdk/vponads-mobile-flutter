import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
      debugPrint('channel.setMethodCallHandler $call');
      assert(call.method == 'onAdEvent');

      final int adId = call.arguments['adId'];
      final String eventName = call.arguments['eventName'];

      final Ad? ad = adFor(adId);
      if (ad != null) {
        _onAdEvent(ad, eventName, call.arguments);
      } else {
        debugPrint('$Ad with id `$adId` is not available for $eventName.');
      }
    });
  }

  int _nextAdId = 0;
  final _BiMap<int, Ad> _loadedAds = _BiMap<int, Ad>();

  /// Invokes load and dispose calls.
  final MethodChannel channel;

  Future initialize() async {
    return (await instanceManager.channel.invokeMethod(
      'initializeSDK',
    ))!;
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
      debugPrint("Failed to get id: '${e.message}'.");
    }
    return id;
  }

  Future<void> setConsentStatus(int value) async {
    try {
      await instanceManager.channel
          .invokeMethod('setConsentStatus', <String, int>{'status': value});
    } on PlatformException catch (e) {
      debugPrint("invokeMethod('setConsentStatus') failed: '${e.message}'.");
    }
  }

  /* ------------------------ Location Manager Service ------------------------ */

  Future<void> setLocationManagerEnable(bool isEnable) async {
    debugPrint('setLocationManagerEnable $isEnable');
    await instanceManager.channel.invokeMethod(
        'setLocationManagerEnable', <String, bool>{'isEnable': isEnable});
  }

  /* -------------------------- Audio Manager Service ------------------------- */

  Future<void> setAudioApplicationManaged(bool isManaged) async {
    try {
      await instanceManager.channel.invokeMethod(
          'setAudioApplicationManaged', <String, bool>{'isManaged': isManaged});
    } on PlatformException catch (e) {
      debugPrint(
          "invokeMethod('setAudioApplicationManaged') failed: '${e.message}'.");
    }
  }

  Future<void> noticeApplicationAudioWillStart() async {
    try {
      await instanceManager.channel
          .invokeMethod('noticeApplicationAudioWillStart');
    } on PlatformException catch (e) {
      debugPrint(
          "invokeMethod('noticeApplicationAudioWillStart') failed: '${e.message}'.");
    }
  }

  Future<void> noticeApplicationAudioDidEnd() async {
    try {
      await instanceManager.channel
          .invokeMethod('noticeApplicationAudioDidEnd');
    } on PlatformException catch (e) {
      debugPrint(
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
    debugPrint(
        'AdInstanceManager _onAdEventIOS called with $eventName and arg $arguments');
    switch (eventName) {
      case 'onAdLoaded':
        _invokeOnAdLoaded(ad, eventName, arguments);
        break;
      case 'onAdFailedToLoad':
        debugPrint('onAdFailedToLoad triggered');
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
        _invokeOnAdShowedFullScreenContent(ad, eventName);
        break;
      case 'adDidDismissFullScreenContent':
        _invokeOnAdDismissedFullScreenContent(ad, eventName);
        break;
      case 'adWillDismissFullScreenContent':
        if (ad is InterstitialAd) {
          ad.fullScreenContentCallback?.onAdWillDismissFullScreenContent
              ?.call(ad);
          debugPrint('adWillDismissFullScreenContent');
        } else {
          debugPrint('invalid ad : $ad, for event name: $eventName');
        }
        break;
      case 'didFailToPresentFullScreenContentWithError':
        debugPrint('ad didFailToPresentFullScreenContentWithError');
        _invokeOnAdFailedToShowFullScreenContent(ad, eventName, arguments);
        break;
      default:
        debugPrint('invalid ad event name: $eventName');
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
    debugPrint('instanceManager _invokeOnAdLoaded');
    if (ad is AdWithView) {
      ad.listener.onAdLoaded?.call(ad);
    } else if (ad is InterstitialAd) {
      ad.adLoadCallback.onAdLoaded.call(ad);
    } else {
      debugPrint('invalid ad: $ad, for event name: $eventName');
    }
  }

  void _invokeOnAdFailedToLoad(
      Ad ad, String eventName, Map<dynamic, dynamic> arguments) {
    debugPrint('instanceManager _invokeOnAdFailedToLoad');
    if (ad is AdWithView) {
      ad.listener.onAdFailedToLoad?.call(ad, arguments['loadAdError']);
    } else if (ad is InterstitialAd) {
      ad.dispose();
      ad.adLoadCallback.onAdFailedToLoad.call(arguments['loadAdError']);
    } else {
      debugPrint('invalid ad: $ad, for event name: $eventName');
    }
  }

  void _invokeOnAdShowedFullScreenContent(Ad ad, String eventName) {
    debugPrint('instanceManager _invokeOnAdShowedFullScreenContent');
    if (ad is InterstitialAd) {
      ad.fullScreenContentCallback?.onAdShowedFullScreenContent?.call(ad);
    } else {
      debugPrint('invalid ad: $ad, for event name: $eventName');
    }
  }

  void _invokeOnAdDismissedFullScreenContent(Ad ad, String eventName) {
    debugPrint('instanceManager _invokeOnAdDismissedFullScreenContent');
    if (ad is InterstitialAd) {
      ad.fullScreenContentCallback?.onAdDismissedFullScreenContent?.call(ad);
    } else {
      debugPrint('invalid ad: $ad, for event name: $eventName');
    }
  }

  void _invokeOnAdFailedToShowFullScreenContent(
      Ad ad, String eventName, Map<dynamic, dynamic> arguments) {
    debugPrint('instanceManager _invokeOnAdFailedToShowFullScreenContent');
    if (ad is InterstitialAd) {
      ad.fullScreenContentCallback?.onAdFailedToShowFullScreenContent
          ?.call(ad, arguments['error']);
    } else {
      debugPrint('invalid ad: $ad, for event name: $eventName');
    }
  }

  void _invokeOnAdImpression(Ad ad, String eventName) {
    if (ad is AdWithView) {
      ad.listener.onAdImpression?.call(ad);
    } else if (ad is InterstitialAd) {
      ad.fullScreenContentCallback?.onAdImpression?.call(ad);
    } else {
      debugPrint('invalid ad: $ad, for event name: $eventName');
    }
  }

  void _invokeOnAdClicked(Ad ad, String eventName) {
    debugPrint('instanceManager _invokeOnAdClicked');
    if (ad is AdWithView) {
      ad.listener.onAdClicked?.call(ad);
    } else if (ad is InterstitialAd) {
      ad.fullScreenContentCallback?.onAdClicked?.call(ad);
    } else {
      debugPrint('invalid ad: $ad, for event name: $eventName');
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
    debugPrint('channel.invokeMethod loadInterstitialAd, request: $ad');
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
    debugPrint('instanceManager call showAdWithoutView');
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
    // debugPrint('writeValue $value');
    if (value is BannerAdSize) {
      writeAdSize(buffer, value);
    } else if (value is VponAdRequest) {
      debugPrint('writeValue AdRequest $value');
      buffer.putUint8(_valueAdRequest);
      writeValue(buffer, value.contentUrl);
      writeValue(buffer, value.contentData);
      writeValue(buffer, value.keywords);
      writeValue(buffer, value.userInfoAge);
      writeValue(buffer, value.userInfoGender);
      writeValue(buffer, value.userInfoBirthday);
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
    // debugPrint('writeAdSize, value = $value');
    buffer.putUint8(_valueAdSize);
    writeValue(buffer, value.width);
    writeValue(buffer, value.height);
  }

  @override
  dynamic readValueOfType(dynamic type, ReadBuffer buffer) {
    // debugPrint('readValueOfType $type');
    switch (type) {
      default:
        // debugPrint('super.readValueOfType $type');
        return super.readValueOfType(type, buffer);
    }
  }

  /// Reads the next value as a non-nullable string.
  ///
  /// Returns '' if the next value is null.
  String _safeReadString(ReadBuffer buffer) {
    return readValueOfType(buffer.getUint8(), buffer) ?? '';
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
