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
  BannerAdSize? _adSize; // default size
  BannerAdSize? previousAdSize;

  set adSize(BannerAdSize newSize) {
    _adSize = newSize;
    _loadBannerAd();
  }

  void _loadBannerAd() async {
    await _bannerAd?.dispose();
    setState(() {
      _bannerAd = null;
      _isLoaded = false;
    });

    String key = '';
    switch (_adSize) {
      case BannerAdSize.banner:
        key = '8a80854b79a9f2ce0179c095a3394b75';
      case BannerAdSize.largeBanner:
        key = '8a80854b79a9f2ce0179c09661714b77';
      case BannerAdSize.mediumRectangle:
        key = '8a80854b79a9f2ce0179c09619fe4b76';
      case BannerAdSize.largeRectangle:
        key = '8a80854b79a9f2ce0179c096a4f94b78';
    }

    if (_adSize != null) {
      _bannerAd = BannerAd(
        licenseKey: key,
        size: _adSize!,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) async {
            BannerAd bannerAd = (ad as BannerAd);

            // setState() after onAdLoaded
            setState(() {
              _bannerAd = bannerAd;
              _isLoaded = true;
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

  Widget _getBannerAdWidget() {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (_bannerAd != null && _isLoaded) {
          return Align(
              child: SizedBox(
            width: _adSize?.width.toDouble(),
            height: _adSize?.height.toDouble(),
            child: AdWidget(
              ad: _bannerAd!,
            ),
          ));
        }
        return Container();
      },
    );
  }

  Widget _getAdSizeSegmentedButtonWidget() {
    return SegmentedButton<BannerAdSize?>(
      style: SegmentedButton.styleFrom(
        backgroundColor: Colors.black12,
        foregroundColor: Colors.black,
        selectedBackgroundColor: Colors.orange,
        selectedForegroundColor: Colors.white,
      ),
      segments: const <ButtonSegment<BannerAdSize>>[
        ButtonSegment<BannerAdSize>(
            value: BannerAdSize.banner,
            label: Text('320x50'),
            icon: Icon(Icons.ad_units)),
        ButtonSegment<BannerAdSize>(
            value: BannerAdSize.largeBanner,
            label: Text('320x100'),
            icon: Icon(Icons.ad_units)),
        ButtonSegment<BannerAdSize>(
            value: BannerAdSize.mediumRectangle,
            label: Text('300x250'),
            icon: Icon(Icons.ad_units)),
        ButtonSegment<BannerAdSize>(
            value: BannerAdSize.largeRectangle,
            label: Text('320x480'),
            icon: Icon(Icons.ad_units)),
      ],
      selected: <BannerAdSize?>{_adSize},
      onSelectionChanged: (Set<BannerAdSize?> newSize) {
        if (newSize.isNotEmpty) {
          setState(() {
            adSize = newSize.first!;
          });
        }
      },
      multiSelectionEnabled: false,
      emptySelectionAllowed: true,
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
              if (index == 0) {
                return _getAdSizeSegmentedButtonWidget();
              } else if (index == 1) {
                return _getBannerAdWidget();
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
