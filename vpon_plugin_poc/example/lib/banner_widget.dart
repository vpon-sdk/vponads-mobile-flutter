import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';

class BannerWidget extends StatefulWidget {
  const BannerWidget({super.key});

  @override
  State<BannerWidget> createState() {
    return _BannerWidgetState();
  }
}

class _BannerWidgetState extends State<BannerWidget> {


  Future<void> loadBannerAd() async {

  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Banner demo'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 300,
              height: 250,
              color: Colors.blue,
              child: iosView(),
            ),
          ),
          const SizedBox(
            height: 100,
          ),
          ElevatedButton(
            onPressed: () => loadBannerAd(),
            style: const ButtonStyle(
                foregroundColor: MaterialStatePropertyAll(Colors.black),
                textStyle: MaterialStatePropertyAll(
                  TextStyle(fontSize: 20),
                )),
            child: const Text('Request'),
          ),
        ],
      ),
    );
  }

  Widget iosView() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return const UiKitView(
        viewType: 'plugins.flutter.io/vpon/ad_widget',
        creationParams: {'text': 'Flutter传给IOSTextView的参数'},
        creationParamsCodec: StandardMessageCodec(),
      );
    } else {
      return Container();
    }
  }
}
