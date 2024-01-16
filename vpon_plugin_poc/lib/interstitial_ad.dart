import 'package:vpon_plugin_poc/vpon_plugin_poc.dart';
import 'package:vpon_plugin_poc/ad_request.dart';

class InterstitialAd {
  static var _vponPluginPocPlugin = VponPluginPoc();


  static Future<void> load({
    required String licenseKey,
    required AdRequest request,
    required InterstitialAdLoadCallback adLoadCallback,
  }) async {
    // 實作 InterstitialAd 的載入邏輯，並呼叫 adLoadCallback
    _vponPluginPocPlugin.loadInterstitialAd(licenseKey, request, adLoadCallback);
  }
}

class InterstitialAdLoadCallback {
  final void Function(InterstitialAd) onAdLoaded;
  final void Function(LoadAdError) onAdFailedToLoad;

  InterstitialAdLoadCallback({
    required this.onAdLoaded,
    required this.onAdFailedToLoad,
  });
}

class LoadAdError {
  // 定義錯誤相關的屬性和方法
}
