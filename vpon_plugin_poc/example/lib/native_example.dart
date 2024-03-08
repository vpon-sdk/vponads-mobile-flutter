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
  int? _format;

  set format(int newFormat) {
    _format = newFormat;
    _loadNativeAd();
  }

  bool _nativeAdIsLoaded = false;
  String? _versionString;

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
    if (_format != null) {
      _nativeAd = NativeAd(
        licenseKey: _format == 0
            ? '8a80854b806fa8710180ff4abd7d1b56'
            : '8a80854b79a9f2ce0179c098ae104b7d',
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
        request: AdRequest(),
      )..load();
    } else {
      debugPrint('Format is null!');
    }
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
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
          title: const Text('Native Demo'),
        ),
        body: Center(
          child: Column(
            children: [
              _getFormatSegmentedButtonWidget(),
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
                  onPressed: _loadNativeAd,
                  child: const Text("Refresh Ad")),
              if (_versionString != null) Text(_versionString!)
            ],
          ),
        ));
  }
}
