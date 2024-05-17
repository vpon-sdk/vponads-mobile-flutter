import 'dart:io';

import 'package:flutter/material.dart';

import 'package:vpon_plugin_poc/vpon_ad_sdk.dart';
import 'context_extensions.dart';

import 'constants.dart';

class BannerExample extends StatefulWidget {
  const BannerExample({super.key});

  @override
  State<BannerExample> createState() {
    return _BannerExampleState();
  }
}

class _BannerExampleState extends State<BannerExample> {
  late BuildContext scaffoldContext;
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  Key adWidgetKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() async {
    await _bannerAd?.dispose();
    setState(() {
      _bannerAd = null;
      _isLoaded = false;
    });

    VponAdRequest request = VponAdRequest();
    request.contentUrl = 'https://www.vpon.com';
    request.contentData = {"testKey": "testValue"};
    request.addContentData(key: "testKey2", value: "testValue2");
    request.addKeyword('testKeyword');

    _bannerAd = BannerAd(
      licenseKey: Platform.isAndroid
          ? '8a80854b75ab2b0101761cfb398671c6'
          : '8a80854b6a90b5bc016ad81a5059652d',
      size: BannerAdSize.banner,
      request: request,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) async {
          BannerAd bannerAd = (ad as BannerAd);

          // setState() after onAdLoaded
          setState(() {
            _bannerAd = bannerAd;
            _isLoaded = true;
            adWidgetKey = UniqueKey();
          });
        },
        onAdFailedToLoad: (Ad ad, Map error) {
          String description = error['errorDescription'];
          int code = error['errorCode'];

          context.showToast(context, 'Error code: $code | $description');
          ad.dispose();
        },
        onAdImpression: (Ad ad) {
          debugPrint('onAdImpression');
        },
        onAdClicked: (Ad ad) {
          debugPrint('onAdClicked');
        },
      ),
    );

    debugPrint('await _bannerAd?.load()');
    await _bannerAd?.load();
  }

  @override
  void dispose() {
    super.dispose();
    debugPrint('bannerAd?.dispose() called');
    _bannerAd?.dispose();
  }

  /* --------------------------------- Widget --------------------------------- */

  Widget _getBannerAdWidget() {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (_bannerAd != null && _isLoaded) {
          return Align(
              child: SizedBox(
            width: BannerAdSize.banner.width.toDouble(),
            height: BannerAdSize.banner.height.toDouble(),
            child: AdWidget(
              key: adWidgetKey,
              ad: _bannerAd!,
            ),
          ));
        }
        return Container();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    scaffoldContext = context;
    return Scaffold(
        appBar: AppBar(
          title: const Text('Banner Demo'),
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
                if (index == 0) {
                  return const Text(
                    Constants.placeholderText,
                    style: TextStyle(fontSize: 14),
                  );
                }
                return _getBannerAdWidget();
              },
            ),
          ),
        ));
  }
}
