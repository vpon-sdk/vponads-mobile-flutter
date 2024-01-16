
import 'vpon_plugin_poc_platform_interface.dart';
import 'package:vpon_plugin_poc/ad_request.dart';
import 'package:vpon_plugin_poc/interstitial_ad.dart';

class VponPluginPoc {
  Future<String?> getPlatformVersion() {
    return VponPluginPocPlatform.instance.getPlatformVersion();
  }

  Future<void> loadInterstitialAd(String licenseKey, AdRequest request, InterstitialAdLoadCallback adLoadCallback) {
    return VponPluginPocPlatform.instance.loadInterstitialAd(licenseKey, request, adLoadCallback);
  }

  Future<void> loadBannerAd() {
    return VponPluginPocPlatform.instance.loadBannerAd();
  }
}
