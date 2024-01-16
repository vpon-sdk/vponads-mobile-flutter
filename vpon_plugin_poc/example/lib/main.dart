import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:vpon_plugin_poc/ad_request.dart';
import 'package:vpon_plugin_poc/vpon_plugin_poc.dart';
import 'package:vpon_plugin_poc_example/banner_widget.dart';
import 'package:vpon_plugin_poc/interstitial_ad.dart';

void main() {
  runApp(const MaterialApp(
    title: 'Vpon Plugin Demo',
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const nativeChannel = MethodChannel('vpon_plugin_poc');
  final _vponPluginPocPlugin = VponPluginPoc();

  bool _isInterstitialReady = false;
  bool get isInterstitialReady => _isInterstitialReady;

  set isInterstitialReady(bool newValue) {
    if (_isInterstitialReady != newValue) {
      _isInterstitialReady = newValue;
      showInterstitial(); // Call your desired function here
    }
  }

  void showInterstitial() {
    nativeChannel.invokeMethod('showInterstitial');
    debugPrint('isInterstitialReady changed to $_isInterstitialReady');
  }

  InterstitialAd? _interstitialAd;
  AdRequest adRequest = AdRequest();

  @override
  void initState() {
    super.initState();
    nativeChannel.setMethodCallHandler(flutterMethod);
    initPlatformState();

    adRequest.setContentUrl('https://google.com');
    adRequest.addContentData('test', 0);
  }

  Future<void> flutterMethod(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'onVpadnInterstitialLoaded':
        isInterstitialReady = true;

        debugPrint('methodChannel 原生 iOS 调用了 onVpadnInterstitialLoaded 方法 参数是：' +
            methodCall.arguments);

    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await _vponPluginPocPlugin.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {});
  }

  Future<void> tryLoadVponIS() async {
    try {
      await InterstitialAd.load(
          licenseKey: '8a80854b79a9f2ce0179c09793ab4b79',
          request: adRequest,
          adLoadCallback:
              InterstitialAdLoadCallback(onAdLoaded: (InterstitialAd ad) {
            // Keep a reference to the ad so you can show it later.
            // _interstitialAd = ad;
          }, onAdFailedToLoad: (LoadAdError error) {
            debugPrint('InterstitialAd failed to load: $error');
          }));
      // await _vponPluginPocPlugin.loadInterstitialAd(
      //     '8a80854b79a9f2ce0179c09793ab4b79');
    } on Exception {}
  }

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
                onPressed: () => tryLoadVponIS(),
                style: const ButtonStyle(
                    foregroundColor: MaterialStatePropertyAll(Colors.black),
                    textStyle: MaterialStatePropertyAll(
                      TextStyle(fontSize: 20),
                    )),
                child: const Text('Load Interstitial'),
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
