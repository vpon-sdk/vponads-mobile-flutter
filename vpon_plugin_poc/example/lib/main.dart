import 'package:flutter/material.dart';

import 'package:vpon_plugin_poc/ad_listeners.dart';
import 'package:vpon_plugin_poc/ad_request.dart';
import 'package:vpon_plugin_poc_example/banner_example.dart';
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

const String testDeviceiOS =
    '00000000-0000-0000-0000-000000000000'; // iOS simulator

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
      format: "mi");
  InterstitialAd? _interstitialAd;

  static const interstitialButtonText = 'Interstitial';
  static const bannerButtonText = 'Banner';

  @override
  void initState() {
    super.initState();
    VponAdSDK.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: [testDeviceiOS]));
    _createInterstitialAd();
  }

  void _createInterstitialAd() {
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
        ));
  }

  void _showInterstitial() {
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
        onAdWillDismissFullScreenContent: (InterstitialAd ad) {
          debugPrint('$ad onAdWillDismissFullScreenContent');
        },
        onAdImpression: (InterstitialAd ad) {
          debugPrint('$ad onAdImpression');
        },
        onAdClicked: (InterstitialAd ad) {
          debugPrint('$ad onAdClicked');
        });
    debugPrint('main.dart call _interstitialAd!.show()');
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  @override
  void dispose() {
    super.dispose();
    _interstitialAd?.dispose();
  }

  // ----- UI -----

  final List<String> menuItems = [interstitialButtonText, bannerButtonText];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(builder: (BuildContext context) {
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
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: menuItems.length,
              itemBuilder: (BuildContext context, int index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: ListTile(
                      title: Text(menuItems[index]),
                      trailing: const Icon(Icons.keyboard_arrow_right),
                      onTap: () {
                        _handleMenuItemSelected(menuItems[index]);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }),
    );
  }

  void _handleMenuItemSelected(String selectedItem) {
    switch (selectedItem) {
      case interstitialButtonText:
        _showInterstitial();
        break;

      case bannerButtonText:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BannerExample()),
        );
        break;

      default:
        throw AssertionError('unexpected button: $selectedItem');
    }
  }
}
