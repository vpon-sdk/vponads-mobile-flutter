import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'ad_containers.dart';
import 'ad_request.dart';

/// Loads and disposes [BannerAds] and [InterstitialAds].
AdInstanceManager instanceManager = AdInstanceManager(
  'plugins.flutter.io/vpon_plugin_poc',
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
    return (await instanceManager.channel.invokeMethod (
      'VponAdSDK#initialize',
    ))!;
  }

  void _onAdEvent(Ad ad, String eventName, Map<dynamic, dynamic> arguments) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      _onAdEventAndroid(ad, eventName, arguments);
    } else {
      _onAdEventIOS(ad, eventName, arguments);
    }
  }

  void _onAdEventIOS(Ad ad, String eventName, Map<dynamic, dynamic> arguments) {
    debugPrint('AdInstanceManager _onAdEventIOS called with $eventName and arg $arguments');
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
      case 'adDidRecordImpression': // Fall through
        debugPrint('adDidRecordImpression, fall through');
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
        } else {
          debugPrint('invalid ad: $ad, for event name: $eventName');
        }
        break;
      case 'didFailToPresentFullScreenContentWithError':
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
    if (ad is InterstitialAd) {
      ad.adLoadCallback.onAdLoaded.call(ad);
    } else {
      debugPrint('invalid ad: $ad, for event name: $eventName');
    }
  }

  void _invokeOnAdFailedToLoad(
      Ad ad, String eventName, Map<dynamic, dynamic> arguments) {
    debugPrint('instanceManager _invokeOnAdFailedToLoad');
    if (ad is InterstitialAd) {
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
    if (ad is InterstitialAd) {
      ad.fullScreenContentCallback?.onAdImpression?.call(ad);
    } else {
      debugPrint('invalid ad: $ad, for event name: $eventName');
    }
  }

  void _invokeOnAdClicked(Ad ad, String eventName) {
    debugPrint('instanceManager _invokeOnAdClicked');
    if (ad is InterstitialAd) {
      ad.fullScreenContentCallback?.onAdClicked?.call(ad);
    } else {
      debugPrint('invalid ad: $ad, for event name: $eventName');
    }
  }

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

  Future<void> loadInterstitialAd(InterstitialAd ad) {
    if (adIdFor(ad) != null) {
      return Future<void>.value();
    }

    final int adId = _nextAdId++;
    _loadedAds[adId] = ad;
    return channel.invokeMethod<void>(
      'loadInterstitialAd',
      <dynamic, dynamic>{
        'adId': adId,
        'licenseKey': ad.licenseKey,
        'request': ad.request,
      },
    );
  }

  /// Starts loading the ad if not previously loaded.
  ///
  /// Loading also terminates if ad is already in the process of loading.
  /*Future<void> loadNativeAd(NativeAd ad) {
    if (adIdFor(ad) != null) {
      return Future<void>.value();
    }

    final int adId = _nextAdId++;
    _loadedAds[adId] = ad;
    return channel.invokeMethod<void>(
      'loadNativeAd',
      <dynamic, dynamic>{
        'adId': adId,
        'adUnitId': ad.adUnitId,
        'request': ad.request,
        'adManagerRequest': ad.adManagerRequest,
        'factoryId': ad.factoryId,
        'nativeAdOptions': ad.nativeAdOptions,
        'customOptions': ad.customOptions,
        'nativeTemplateStyle': ad.nativeTemplateStyle,
      },
    );
  }*/

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

  /// Gets the global [RequestConfiguration].
  Future<RequestConfiguration> getRequestConfiguration() async {
    return (await instanceManager.channel.invokeMethod<RequestConfiguration>(
        'MobileAds#getRequestConfiguration'))!;
  }

  /// Set the [RequestConfiguration] to apply for future ad requests.
  Future<void> updateRequestConfiguration(
      RequestConfiguration requestConfiguration) {
    return channel.invokeMethod<void>(
      'VponAdSDK#updateRequestConfiguration',
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
        .invokeMethod<String>('VponAdSDK#getVersionString'))!;
  }
}

@visibleForTesting
class AdMessageCodec extends StandardMessageCodec {
  // The type values below must be consistent for each platform.
  static const int _valueAdSize = 128;
  static const int _valueAdRequest = 129;

  static const int _valueLoadAdError = 133;
  static const int _valueAdManagerAdRequest = 134;
  static const int _valueInitializationState = 135;
  static const int _valueAdapterStatus = 136;
  static const int _valueInitializationStatus = 137;

  static const int _valueAdError = 139;
  static const int _valueResponseInfo = 140;
  static const int _valueAdapterResponseInfo = 141;
  static const int _valueAnchoredAdaptiveBannerAdSize = 142;
  static const int _valueSmartBannerAdSize = 143;
  static const int _valueNativeAdOptions = 144;
  static const int _valueVideoOptions = 145;
  static const int _valueInlineAdaptiveBannerAdSize = 146;
  static const int _valueRequestConfigurationParams = 148;
  static const int _valueNativeTemplateStyle = 149;
  static const int _valueNativeTemplateTextStyle = 150;
  static const int _valueNativeTemplateFontStyle = 151;
  static const int _valueNativeTemplateType = 152;
  static const int _valueColor = 153;

  @override
  void writeValue(WriteBuffer buffer, dynamic value) {
    if (value is AdRequest) {
      buffer.putUint8(_valueAdRequest);
      writeValue(buffer, value.keywords);
      writeValue(buffer, value.contentUrl);
    } else if (value is RequestConfiguration) {
      buffer.putUint8(_valueRequestConfigurationParams);
      writeValue(buffer, value.maxAdContentRating);
      writeValue(buffer, value.tagForChildDirectedTreatment);
      writeValue(buffer, value.tagForUnderAgeOfConsent);
      writeValue(buffer, value.testDeviceIds);
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  dynamic readValueOfType(dynamic type, ReadBuffer buffer) {
    switch (type) {
      case _valueAdRequest:
        return AdRequest(
            keywords:
                readValueOfType(buffer.getUint8(), buffer)?.cast<String>(),
            contentUrl: readValueOfType(buffer.getUint8(), buffer));

      case _valueRequestConfigurationParams:
        return RequestConfiguration(
          maxAdContentRating: readValueOfType(buffer.getUint8(), buffer),
          tagForChildDirectedTreatment:
              readValueOfType(buffer.getUint8(), buffer),
          tagForUnderAgeOfConsent: readValueOfType(buffer.getUint8(), buffer),
          testDeviceIds:
              readValueOfType(buffer.getUint8(), buffer).cast<String>(),
        );
      default:
        return super.readValueOfType(type, buffer);
    }
  }

  Map<String, List<T>>? _tryDeepMapCast<T>(Map<dynamic, dynamic>? map) {
    if (map == null) return null;
    return map.map<String, List<T>>(
      (dynamic key, dynamic value) => MapEntry<String, List<T>>(
        key,
        value?.cast<T>(),
      ),
    );
  }

  Map<String, String> _deepCastStringMap(Map<dynamic, dynamic>? map) {
    if (map == null) return {};
    return map.map<String, String>(
      (dynamic key, dynamic value) => MapEntry<String, String>(
        key,
        value,
      ),
    );
  }

  Map<String, dynamic> _deepCastStringKeyDynamicValueMap(
      Map<dynamic, dynamic>? map) {
    if (map == null) return {};
    return map.map<String, dynamic>(
      (dynamic key, dynamic value) => MapEntry<String, dynamic>(
        key,
        value,
      ),
    );
  }

  /// Reads the next value as a non-nullable string.
  ///
  /// Returns '' if the next value is null.
  String _safeReadString(ReadBuffer buffer) {
    return readValueOfType(buffer.getUint8(), buffer) ?? '';
  }

/*void writeAdSize(WriteBuffer buffer, AdSize value) {
    if (value is InlineAdaptiveSize) {
      buffer.putUint8(_valueInlineAdaptiveBannerAdSize);
      writeValue(buffer, value.width);
      writeValue(buffer, value.maxHeight);
      writeValue(buffer, value.orientationValue);
    } else if (value is AnchoredAdaptiveBannerAdSize) {
      buffer.putUint8(_valueAnchoredAdaptiveBannerAdSize);
      var orientationValue;
      if (value.orientation != null) {
        orientationValue = (value.orientation as Orientation).name;
      }
      writeValue(buffer, orientationValue);
      writeValue(buffer, value.width);
    } else if (value is SmartBannerAdSize) {
      buffer.putUint8(_valueSmartBannerAdSize);
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        writeValue(buffer, value.orientation.name);
      }
    } else {
      buffer.putUint8(_valueAdSize);
      writeValue(buffer, value.width);
      writeValue(buffer, value.height);
    }
  }*/
}

/*/// An extension that maps each [MediaAspectRatio] to an int.
extension MediaAspectRatioExtension on MediaAspectRatio {
  /// Gets the int mapping to pass to platform channel.
  int get intValue {
    switch (this) {
      case MediaAspectRatio.unknown:
        return 0;
      case MediaAspectRatio.any:
        return 1;
      case MediaAspectRatio.landscape:
        return 2;
      case MediaAspectRatio.portrait:
        return 3;
      case MediaAspectRatio.square:
        return 4;
    }
  }

  /// Maps an int back to [MediaAspectRatio].
  static MediaAspectRatio? fromInt(int? intValue) {
    switch (intValue) {
      case 0:
        return MediaAspectRatio.unknown;
      case 1:
        return MediaAspectRatio.any;
      case 2:
        return MediaAspectRatio.landscape;
      case 3:
        return MediaAspectRatio.portrait;
      case 4:
        return MediaAspectRatio.square;
      default:
        return null;
    }
  }
}*/

/*/// An extension that maps each [AdChoicesPlacement] to an int.
extension AdChoicesPlacementExtension on AdChoicesPlacement {
  /// Gets the int mapping to pass to platform channel.
  int get intValue {
    switch (this) {
      case AdChoicesPlacement.topRightCorner:
        return Platform.isAndroid ? 1 : 0;
      case AdChoicesPlacement.topLeftCorner:
        return Platform.isAndroid ? 0 : 1;
      case AdChoicesPlacement.bottomRightCorner:
        return 2;
      case AdChoicesPlacement.bottomLeftCorner:
        return 3;
    }
  }

  /// Maps an int back to [AdChoicesPlacement].
  static AdChoicesPlacement? fromInt(int? intValue) {
    switch (intValue) {
      case 0:
        return Platform.isAndroid
            ? AdChoicesPlacement.topLeftCorner
            : AdChoicesPlacement.topRightCorner;
      case 1:
        return Platform.isAndroid
            ? AdChoicesPlacement.topRightCorner
            : AdChoicesPlacement.topLeftCorner;
      case 2:
        return AdChoicesPlacement.bottomRightCorner;
      case 3:
        return AdChoicesPlacement.bottomLeftCorner;
      default:
        return null;
    }
  }
}*/

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
