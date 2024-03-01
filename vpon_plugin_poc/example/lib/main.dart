import 'package:flutter/material.dart';

import 'package:vpon_plugin_poc/ad_request.dart';
import 'package:vpon_plugin_poc_example/banner_example.dart';
import 'package:vpon_plugin_poc/vpon_ad_sdk.dart';
import 'package:vpon_plugin_poc_example/interstitial_example.dart';

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
  static const interstitialButtonText = 'Interstitial';
  static const bannerButtonText = 'Banner';

  final List<String> menuItems = [interstitialButtonText, bannerButtonText];

  @override
  void initState() {
    super.initState();
    VponAdSDK.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: [testDeviceiOS]));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(builder: (BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Vpon Plugin Example'),
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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const InterstitialExample()),
        );
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
