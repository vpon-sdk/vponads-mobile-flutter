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
  BannerAdSize? _adSize;
  Key adWidgetKey = UniqueKey();

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

    VponAdRequest request = VponAdRequest();
    request.contentUrl = 'https://www.vpon.com';
    request.contentData = {"testKey": "testValue"};
    request.addContentData(key: "testKey2", value: "testValue2");
    request.addKeyword('testKeyword');

    if (_adSize != null) {
      _bannerAd = BannerAd(
        licenseKey: key,
        size: _adSize!,
        request: request,
        autoRefresh: false,
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
            width: _adSize?.width.toDouble(),
            height: _adSize?.height.toDouble(),
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
