import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vpon_plugin_poc/ad_containers.dart';
import 'package:vpon_plugin_poc/ad_listeners.dart';
import 'package:vpon_plugin_poc/ad_request.dart';
import 'package:vpon_plugin_poc/native_ad.dart';
import 'package:vpon_plugin_poc/vpon_ad_sdk.dart';
import 'package:vpon_plugin_poc_example/context_extensions.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  VponAdSDK.instance.initialize();
  runApp(const MaterialApp(
    home: NativeExample(),
  ));
}

/// A simple app that loads a native ad.
class NativeExample extends StatefulWidget {
  const NativeExample({super.key});

  @override
  NativeExampleState createState() => NativeExampleState();
}

class NativeExampleState extends State<NativeExample> {
  late BuildContext scaffoldContext;
  NativeAd? _nativeAd;
  bool _nativeAdIsLoaded = false;
  String? _versionString;

  final String _licenseKey = '8a80854b79a9f2ce0179c098ae104b7d';

  @override
  void initState() {
    super.initState();

    _loadAd();
  }

  /// Loads a native ad.
  void _loadAd() {
    setState(() {
      _nativeAdIsLoaded = false;
    });

    _nativeAd = NativeAd(
      licenseKey: _licenseKey,
      factoryId: 'adFactoryExample',
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          context.showToast(context, 'onAdLoaded invoked');
          setState(() {
            _nativeAdIsLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          String description = error['errorDescription'];
          int code = error['errorCode'];

          context.showToast(context, 'Error code: $code | $description');
          ad.dispose();
        },
        onAdClicked: (ad) {},
        onAdImpression: (ad) {},
      ),
      request: const AdRequest(),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }


/* --------------------------------- Widget --------------------------------- */
  @override
  Widget build(BuildContext context) {
    scaffoldContext = context;
    return Scaffold(
        appBar: AppBar(
          title: const Text('Native Demo'),
        ),
        body: Center(
          child: Column(
            children: [
              Stack(children: [
                SizedBox(height: 300, width: MediaQuery.of(context).size.width),
                if (_nativeAdIsLoaded && _nativeAd != null)
                  SizedBox(
                      height: 400,
                      width: MediaQuery.of(context).size.width,
                      child: AdWidget(ad: _nativeAd!))
              ]),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black38,
                  ),
                  onPressed: _loadAd,
                  child: const Text("Refresh Ad")),
              if (_versionString != null) Text(_versionString!)
            ],
          ),
        ));
  }
}