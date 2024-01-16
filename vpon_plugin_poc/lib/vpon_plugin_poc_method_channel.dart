import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'vpon_plugin_poc_platform_interface.dart';
import 'package:vpon_plugin_poc/ad_request.dart';
import 'package:vpon_plugin_poc/interstitial_ad.dart';

/// An implementation of [VponPluginPocPlatform] that uses method channels.
class MethodChannelVponPluginPoc extends VponPluginPocPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('vpon_plugin_poc');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<void> loadInterstitialAd(String licenseKey, AdRequest request,
      InterstitialAdLoadCallback adLoadCallback) {
    return methodChannel.invokeMethod<void>('loadInterstitialAd', {
      'licenseKey': licenseKey,
      'adRequest': {
        'autoRefresh': request.autoRefresh,
        'contentUrl': request.contentUrl,
        'contentData': request.contentData
      }
    });
  }

  @override
  Future<void> loadBannerAd() {
    return methodChannel.invokeMethod<void>('loadBannerAd',
        {'licenseKey': '8a80854b79a9f2ce0179c09619fe4b76', 'adSize': 'banner'});
  }
}
