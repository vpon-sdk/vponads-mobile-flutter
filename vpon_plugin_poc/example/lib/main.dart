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
  late BuildContext scaffoldContext;

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
            _showToast(scaffoldContext,
                'InterstitialAd onAdLoaded');
            _interstitialAd = ad;
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('InterstitialAd failed to load: $error.');
            _showToast(scaffoldContext,
                'InterstitialAd failed to load: $error.');
            _interstitialAd = null;
          },
        ));
  }

  void _showToast(BuildContext context, String message) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _showInterstitial() {
    if (_interstitialAd == null) {
      _showToast(scaffoldContext,
          'Warning: attempt to show interstitial before loaded.');
      return;
    }
    debugPrint('main.dart _interstitialAd!.fullScreenContentCallback');
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (InterstitialAd ad) {
      debugPrint('main.dart onAdShowedFullScreenContent.');
      _showToast(scaffoldContext, 'onAdShowedFullScreenContent');
    }, onAdDismissedFullScreenContent: (InterstitialAd ad) {
      debugPrint('main.dart onAdDismissedFullScreenContent.');
      _showToast(scaffoldContext, 'onAdDismissedFullScreenContent');
      ad.dispose();
      _createInterstitialAd();
    }, onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
      debugPrint('main.dart onAdFailedToShowFullScreenContent: $error');
      _showToast(scaffoldContext, 'onAdFailedToShowFullScreenContent: $error');
      ad.dispose();
      _createInterstitialAd();
    }, onAdWillDismissFullScreenContent: (InterstitialAd ad) {
      debugPrint('main.dart onAdWillDismissFullScreenContent');
      _showToast(scaffoldContext, 'onAdWillDismissFullScreenContent');
    }, onAdImpression: (InterstitialAd ad) {
      debugPrint('main.dart onAdImpression');
      _showToast(scaffoldContext, 'onAdImpression');
    }, onAdClicked: (InterstitialAd ad) {
      debugPrint('main.dart onAdClicked');
      _showToast(scaffoldContext, 'onAdClicked');
    });
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
        scaffoldContext = context;
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
