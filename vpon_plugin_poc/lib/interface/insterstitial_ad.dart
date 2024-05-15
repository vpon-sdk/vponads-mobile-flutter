import 'package:flutter/foundation.dart';

import 'ad_containers.dart';
import 'ad_listeners.dart';
import 'ad_request.dart';
import 'ad_instance_manager.dart';

class InterstitialAd extends AdWithoutView {
  InterstitialAd._({
    required String licenseKey,
    required this.request,
    required this.adLoadCallback,
  }) : super(licenseKey: licenseKey);

  final VponAdRequest request;

  final InterstitialAdLoadCallback adLoadCallback;

  FullScreenContentCallback<InterstitialAd>? fullScreenContentCallback;

  static Future<void> load({
    required String licenseKey,
    required VponAdRequest request,
    required InterstitialAdLoadCallback adLoadCallback,
  }) async {
    InterstitialAd ad = InterstitialAd._(
        licenseKey: licenseKey,
        adLoadCallback: adLoadCallback,
        request: request);

    await instanceManager.loadInterstitialAd(ad);
  }
  
  Future<void> show() {
    return instanceManager.showAdWithoutView(this);
  }
}