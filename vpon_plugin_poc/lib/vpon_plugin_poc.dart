
import 'vpon_plugin_poc_platform_interface.dart';

class VponPluginPoc {
  Future<String?> getPlatformVersion() {
    return VponPluginPocPlatform.instance.getPlatformVersion();
  }

  Future<void> loadInterstitialAd() {
    return VponPluginPocPlatform.instance.loadInterstitialAd();
  }
}
