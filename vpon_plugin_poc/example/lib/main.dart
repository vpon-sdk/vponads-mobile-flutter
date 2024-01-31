import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:vpon_plugin_poc/ad_listeners.dart';
import 'package:vpon_plugin_poc/ad_request.dart';
import 'package:vpon_plugin_poc_example/banner_widget.dart';
import 'package:vpon_plugin_poc/ad_containers.dart';
import 'package:vpon_plugin_poc/vpon_ad_sdk.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  VponAdSDK.instance.initialize();
  runApp(const MaterialApp(
    title: 'Vpon Plugin Demo',
    home: MyApp(),
  ));
}

const String testDevice = '00000000-0000-0000-0000-000000000000'; // iOS simulator

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static final AdRequest request = AdRequest(
      keywords: <String>['test1', 'test2'],
      contentUrl: 'https://google.com',
      contentData: {'test': '123'},
      format: "mi"
  );
  InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();
    VponAdSDK.instance.updateRequestConfiguration(RequestConfiguration(testDeviceIds: [testDevice]));
    _createInterstitialAd();
  }

  void _createInterstitialAd() {
    debugPrint('_createInterstitialAd');
    InterstitialAd.load(
        licenseKey: '8a80854b79a9f2ce0179c09793ab4b79',
        request: request,
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            debugPrint('$ad loaded');
            _interstitialAd = ad;
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('InterstitialAd failed to load: $error.');
            _interstitialAd = null;
          },
        )
    );
  }

  void showInterstitial() {
    debugPrint('main.dart showInterstitial called');
    if (_interstitialAd == null) {
      debugPrint('Warning: attempt to show interstitial before loaded.');
      return;
    }
    debugPrint('main.dart _interstitialAd!.fullScreenContentCallback');
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) =>
          debugPrint('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        debugPrint('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _createInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        debugPrint('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _createInterstitialAd();
      },
    );
    debugPrint('main.dart call _interstitialAd!.show()');
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  @override
  void dispose() {
    super.dispose();
    _interstitialAd?.dispose();
  }

  // Future<void> tryLoadVponIS() async {
  //   try {
  //     await InterstitialAd.load(
  //         licenseKey: '8a80854b79a9f2ce0179c09793ab4b79',
  //         request: request,
  //         adLoadCallback:
  //             InterstitialAdLoadCallback(onAdLoaded: (InterstitialAd ad) {
  //           // Keep a reference to the ad so you can show it later.
  //           // _interstitialAd = ad;
  //         }, onAdFailedToLoad: (LoadAdError error) {
  //           debugPrint('InterstitialAd failed to load: $error');
  //         }));
  //     // await _vponPluginPocPlugin.loadInterstitialAd(
  //     //     '8a80854b79a9f2ce0179c09793ab4b79');
  //   } on Exception {}
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vpon Plugin example app'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange,
              Colors.deepOrange,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () => showInterstitial(),
                style: const ButtonStyle(
                    foregroundColor: MaterialStatePropertyAll(Colors.black),
                    textStyle: MaterialStatePropertyAll(
                      TextStyle(fontSize: 20),
                    )),
                child: const Text('Show Interstitial'),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const BannerWidget()),
                  );
                },
                style: const ButtonStyle(
                    foregroundColor: MaterialStatePropertyAll(Colors.black),
                    textStyle: MaterialStatePropertyAll(
                      TextStyle(fontSize: 20),
                    )),
                child: const Text('Load Banner'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
