import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vpon_mobile_ads/vpon_ad_sdk.dart';
import 'package:vpon_mobile_ads_example/context_extensions.dart';

import 'constants.dart';

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

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  /// Loads a native ad.
  void _loadNativeAd() {
    setState(() {
      _nativeAdIsLoaded = false;
    });
    VponAdRequest request = VponAdRequest();
    request.contentUrl = 'https://www.vpon.com';
    request.contentData = {"testKey": "testValue"};
    request.addContentData(key: "testKey2", value: "testValue2");
    request.addKeyword('testKeyword');

    _nativeAd = NativeAd(
      licenseKey: Platform.isAndroid
          ? '8a80854b6a90b5bc016ad81ca1336534'
          : '8a80854b6a90b5bc016ad81ac68c6530',
      factoryId: 'VponNativeAdFactory',
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
      request: request,
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ListView.separated(
              itemCount: 2,
              separatorBuilder: (BuildContext context, int index) {
                return Container(
                  height: 40,
                );
              },
              itemBuilder: (BuildContext context, int index) {
                switch (index) {
                  case 0:
                    return const Text(
                      Constants.placeholderText,
                      style: TextStyle(fontSize: 14),
                    );
                  case 1:
                    return (_nativeAdIsLoaded && _nativeAd != null)
                        ? Column(
                            children: [
                              SizedBox(
                                  height: 400,
                                  width: MediaQuery.of(context).size.width,
                                  child: AdWidget(ad: _nativeAd!)),
                              ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.black38,
                                  ),
                                  onPressed: _loadNativeAd,
                                  child: const Text("Refresh Ad"))
                            ],
                          )
                        : Container();
                }
              },
            ),
          ),
        ));
  }
}
