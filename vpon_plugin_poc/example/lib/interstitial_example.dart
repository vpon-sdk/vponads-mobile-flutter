import 'package:flutter/material.dart';
import 'package:vpon_plugin_poc/ad_containers.dart';
import 'package:vpon_plugin_poc/ad_listeners.dart';
import 'package:vpon_plugin_poc/ad_request.dart';
import 'package:vpon_plugin_poc_example/constants.dart';

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
  int? _format;

  set format(int newFormat) {
    _format = newFormat;
    _loadInterstitialAd();
  }

  @override
  void initState() {
    super.initState();
  }

  void _loadInterstitialAd() {
    AdRequest request = const AdRequest(
        keywords: <String>['test1', 'test2'],
        contentUrl: 'https://google.com',
        contentData: {'test': '123'},
        format: "mi");

    if (_format != null) {
      InterstitialAd.load(
          licenseKey: _format == 0
              ? '8a80854b79a9f2ce0179c09793ab4b79'
              : '8a80854b79a9f2ce0179c097d26e4b7a',
          request: request,
          adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: (InterstitialAd ad) {
              debugPrint('$ad loaded');
              _showToast(scaffoldContext, 'InterstitialAd onAdLoaded');
              _interstitialAd = ad;
              _showInterstitial();
            },
            onAdFailedToLoad: (LoadAdError error) {
              debugPrint('InterstitialAd failed to load: $error.');
              _showToast(
                  scaffoldContext, 'InterstitialAd failed to load: $error.');
              _interstitialAd = null;
            },
          ));
    } else {
      _showToast(scaffoldContext, 'Format is null!');
    }
  }

  void _showInterstitial() {
    if (_interstitialAd == null) {
      _showToast(scaffoldContext,
          'Warning: attempt to show interstitial before loaded.');
      return;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (InterstitialAd ad) {
      debugPrint('onAdShowedFullScreenContent.');
      _showToast(scaffoldContext, 'onAdShowedFullScreenContent');
    }, onAdDismissedFullScreenContent: (InterstitialAd ad) {
      debugPrint('onAdDismissedFullScreenContent.');
      _showToast(scaffoldContext, 'onAdDismissedFullScreenContent');
      ad.dispose();
    }, onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
      debugPrint('onAdFailedToShowFullScreenContent: $error');
      _showToast(scaffoldContext, 'onAdFailedToShowFullScreenContent: $error');
      ad.dispose();
    }, onAdWillDismissFullScreenContent: (InterstitialAd ad) {
      debugPrint('onAdWillDismissFullScreenContent');
      _showToast(scaffoldContext, 'onAdWillDismissFullScreenContent');
    }, onAdImpression: (InterstitialAd ad) {
      debugPrint('onAdImpression');
      _showToast(scaffoldContext, 'onAdImpression');
    }, onAdClicked: (InterstitialAd ad) {
      debugPrint('onAdClicked');
      _showToast(scaffoldContext, 'onAdClicked');
    });
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  void _showToast(BuildContext context, String message) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _interstitialAd?.dispose();
  }

/* --------------------------------- Widget --------------------------------- */

  Widget _getFormatSegmentedButtonWidget() {
    return SegmentedButton<int?>(
      style: SegmentedButton.styleFrom(
        backgroundColor: Colors.black12,
        foregroundColor: Colors.black,
        selectedBackgroundColor: Colors.orange,
        selectedForegroundColor: Colors.white,
      ),
      segments: const <ButtonSegment<int>>[
        ButtonSegment<int>(
            value: 0, label: Text('Display'), icon: Icon(Icons.ad_units)),
        ButtonSegment<int>(
            value: 1, label: Text('Video'), icon: Icon(Icons.ad_units)),
      ],
      selected: <int?>{_format},
      onSelectionChanged: (Set<int?> newFormat) {
        if (newFormat.isNotEmpty) {
          setState(() {
            format = newFormat.first!;
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
          title: const Text('Interstitial Demo'),
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
                  return _getFormatSegmentedButtonWidget();
                }
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
