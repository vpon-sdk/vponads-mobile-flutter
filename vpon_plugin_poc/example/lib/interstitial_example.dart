import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vpon_plugin_poc/vpon_ad_sdk.dart';
import 'package:vpon_plugin_poc_example/constants.dart';
import 'context_extensions.dart';

class InterstitialExample extends StatefulWidget {
  const InterstitialExample({super.key});

  @override
  State<InterstitialExample> createState() {
    return _InterstitialExampleState();
  }
}

class _InterstitialExampleState extends State<InterstitialExample> {
  late BuildContext scaffoldContext;

  InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();
    _loadInterstitialAd();
  }

  void _loadInterstitialAd() {
    VponAdRequest request = VponAdRequest();
    request.contentUrl = 'https://www.vpon.com';
    request.contentData = {"testKey": "testValue"};
    request.addContentData(key: "testKey2", value: "testValue2");
    request.addKeyword('testKeyword');

    InterstitialAd.load(
      licenseKey: Platform.isAndroid
          ? '8a80854b75ab2b0101761cfb968d71c7'
          : '8a80854b6a90b5bc016ad81a98cf652e',
      request: request,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          debugPrint('$ad loaded');
          context.showToast(scaffoldContext, 'InterstitialAd onAdLoaded');
          _interstitialAd = ad;
          _showInterstitial();
        },
        onAdFailedToLoad: (Map error) {
          String description = error['errorDescription'];
          int code = error['errorCode'];

          context.showToast(context, 'Error code: $code | $description');
          _interstitialAd = null;
        },
        onAdImpression: (InterstitialAd ad) {
          debugPrint('onAdImpression');
        },
        onAdClicked: (InterstitialAd ad) {
          debugPrint('onAdClicked');
        },
        onAdWillDismissFullScreenContent: (InterstitialAd ad) {
          debugPrint('onAdWillDismissFullScreenContent');
        },
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          debugPrint('onAdDismissedFullScreenContent');
        },
        onAdWillShowFullScreenContent: (InterstitialAd ad) {
          debugPrint('onAdWillShowFullScreenContent');
        },
      ),
    );
  }

  void _showInterstitial() {
    if (_interstitialAd == null) {
      context.showToast(scaffoldContext,
          'Warning: attempt to show interstitial before loaded.');
      return;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdWillShowFullScreenContent: (InterstitialAd ad) {
      debugPrint('onAdWillShowFullScreenContent.');
    }, onAdDismissedFullScreenContent: (InterstitialAd ad) {
      debugPrint('onAdDismissedFullScreenContent.');

      ad.dispose();
    }, onAdFailedToShowFullScreenContent: (InterstitialAd ad, Map error) {
      debugPrint('onAdFailedToShowFullScreenContent: $error');
      context.showToast(
          scaffoldContext, 'onAdFailedToShowFullScreenContent: $error');
      ad.dispose();
    }, onAdWillDismissFullScreenContent: (InterstitialAd ad) {
      debugPrint('onAdWillDismissFullScreenContent');
    }, onAdImpression: (InterstitialAd ad) {
      debugPrint('onAdImpression');
    }, onAdClicked: (InterstitialAd ad) {
      debugPrint('onAdClicked');
    });
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  @override
  void dispose() {
    super.dispose();
    _interstitialAd?.dispose();
  }

/* --------------------------------- Widget --------------------------------- */

  @override
  Widget build(BuildContext context) {
    scaffoldContext = context;
    return Scaffold(
        appBar: AppBar(
          title: const Text('Interstitial Demo'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ListView.separated(
              itemCount: 1,
              separatorBuilder: (BuildContext context, int index) {
                return Container(
                  height: 40,
                );
              },
              itemBuilder: (BuildContext context, int index) {
                return const Text(
                  Constants.placeholderText,
                  style: TextStyle(fontSize: 14),
                );
              },
            ),
          ),
        ));
  }
}
