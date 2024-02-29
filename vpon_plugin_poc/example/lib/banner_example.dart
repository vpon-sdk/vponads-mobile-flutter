import 'package:flutter/material.dart';

import 'package:vpon_plugin_poc/ad_containers.dart';
import 'package:vpon_plugin_poc/ad_listeners.dart';
import 'package:vpon_plugin_poc/ad_request.dart';

import 'Constants.dart';

class BannerExample extends StatefulWidget {
  const BannerExample({super.key});

  @override
  State<BannerExample> createState() {
    return _BannerExampleState();
  }
}

class _BannerExampleState extends State<BannerExample> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  BannerAdSize? _adSize;

  final double _adWidth = 320;

  void _loadBannerAd() async {
    if (_bannerAd == null) {
      await _bannerAd?.dispose();
      setState(() {
        _bannerAd = null;
        _isLoaded = false;
      });

      BannerAdSize size = BannerAdSize.banner;

      _bannerAd = BannerAd(
        licenseKey: '8a80854b79a9f2ce0179c095a3394b75',
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) async {
            // if (_bannerAd != null) {
            //   debugPrint('_bannerAd != null, return');
            //   return;
            // }
            BannerAd bannerAd = (ad as BannerAd);

// setState() after onAdLoaded
            setState(() {
              _bannerAd = bannerAd;
              _isLoaded = true;
              _adSize = size;
            });
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            debugPrint('banner_example onAdFailedToLoad');
            ad.dispose();
          },
        ),
      );

      debugPrint('await _bannerAd?.load()');
      await _bannerAd?.load();
    }
  }

  Widget _getAdWidget() {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (_bannerAd != null && _isLoaded && _adSize != null) {
          return Align(
              child: SizedBox(
            width: _adWidth,
            height: _adSize!.height.toDouble(),
            child: AdWidget(
              ad: _bannerAd!,
            ),
          ));
        } else {
          _loadBannerAd();
          return Container();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Banner demo'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ListView.separated(
            itemCount: 3,
            separatorBuilder: (BuildContext context, int index) {
              return Container(
                height: 40,
              );
            },
            itemBuilder: (BuildContext context, int index) {
              if (index == 1) {
                return _getAdWidget();
              }
              return const Text(
                Constants.placeholderText,
                style: TextStyle(fontSize: 14),
              );
            },
          ),
        ),
      ));

  @override
  void dispose() {
    super.dispose();
    debugPrint('bannerAd?.dispose() called');
    _bannerAd?.dispose();
  }
}
