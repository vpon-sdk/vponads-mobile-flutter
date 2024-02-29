import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'ad_instance_manager.dart';
import 'ad_listeners.dart';
import 'ad_request.dart';

/// The base class for all ads.
///
/// A valid [licenseKey] is required.
abstract class Ad {
  /// Default constructor, used by subclasses.
  Ad({required this.licenseKey});

  /// Identifies the source of [Ad]s for your application.
  final String licenseKey;

  /// Frees the plugin resources associated with this ad.
  Future<void> dispose() {
    return instanceManager.disposeAd(this);
  }
}

abstract class AdWithView extends Ad {
  /// Default constructor, used by subclasses.
  AdWithView({required String licenseKey, required this.listener})
      : super(licenseKey: licenseKey);

  /// The [AdWithViewListener] for the ad.
  final AdWithViewListener listener;

  /// Starts loading this ad.
  ///
  /// Loading callbacks are sent to this [Ad]'s [listener].
  Future<void> load();
}

/// An [Ad] that is overlaid on top of the UI.
abstract class AdWithoutView extends Ad {
  /// Default constructor used by subclasses.
  AdWithoutView({required String licenseKey}) : super(licenseKey: licenseKey);
}

/// Displays an [Ad] as a Flutter widget.
///
/// This widget takes ads inheriting from [AdWithView]
/// (e.g. [BannerAd] and [NativeAd]) and allows them to be added to the Flutter
/// widget tree.
///
/// Must call `load()` first before showing the widget. Otherwise, a
/// [PlatformException] will be thrown.
class AdWidget extends StatefulWidget {
  /// Default constructor for [AdWidget].
  ///
  /// [ad] must be loaded before this is added to the widget tree.
  const AdWidget({Key? key, required this.ad}) : super(key: key);

  /// Ad to be displayed as a widget.
  final AdWithView ad;

  @override
  _AdWidgetState createState() => _AdWidgetState();
}

class _AdWidgetState extends State<AdWidget> {
  bool _adIdAlreadyMounted = false;
  bool _adLoadNotCalled = false;

  @override
  void initState() {
    super.initState();
    final int? adId = instanceManager.adIdFor(widget.ad);
    if (adId != null) {
      if (instanceManager.isWidgetAdIdMounted(adId)) {
        _adIdAlreadyMounted = true;
      }
      instanceManager.mountWidgetAdId(adId);
    } else {
      _adLoadNotCalled = true;
    }
  }

  @override
  void dispose() {
    super.dispose();
    final int? adId = instanceManager.adIdFor(widget.ad);
    if (adId != null) {
      instanceManager.unmountWidgetAdId(adId);
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('_AdWidgetState build triggered');
    if (_adIdAlreadyMounted) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('This AdWidget is already in the Widget tree'),
        ErrorHint(
            'If you placed this AdWidget in a list, make sure you create a new instance '
            'in the builder function with a unique ad object.'),
        ErrorHint(
            'Make sure you are not using the same ad object in more than one AdWidget.'),
      ]);
    }
    if (_adLoadNotCalled) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary(
            'AdWidget requires Ad.load to be called before AdWidget is inserted into the tree'),
        ErrorHint(
            'Parameter ad is not loaded. Call Ad.load before AdWidget is inserted into the tree.'),
      ]);
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return PlatformViewLink(
        viewType: '${instanceManager.channel.name}/ad_widget',
        surfaceFactory:
            (BuildContext context, PlatformViewController controller) {
          return AndroidViewSurface(
            controller: controller as AndroidViewController,
            gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          );
        },
        onCreatePlatformView: (PlatformViewCreationParams params) {
          return PlatformViewsService.initSurfaceAndroidView(
            id: params.id,
            viewType: '${instanceManager.channel.name}/ad_widget',
            layoutDirection: TextDirection.ltr,
            creationParams: instanceManager.adIdFor(widget.ad),
            creationParamsCodec: const StandardMessageCodec(),
          )
            ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
            ..create();
        },
      );
    }
    debugPrint('_AdWidgetState build return UiKitView');
    return UiKitView(
      viewType: '${instanceManager.channel.name}/ad_widget',
      creationParams: instanceManager.adIdFor(widget.ad),
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}

/// A full-screen interstitial ad for the Vpon Plugin.
class InterstitialAd extends AdWithoutView {
  /// Creates an [InterstitialAd].
  InterstitialAd._({
    required String licenseKey,
    required this.request,
    required this.adLoadCallback,
  }) : super(licenseKey: licenseKey);

  /// Targeting information used to fetch an [Ad].
  final AdRequest request;

  /// Callback to be invoked when the ad finishes loading.
  final InterstitialAdLoadCallback adLoadCallback;

  /// Callbacks to be invoked when ads show and dismiss full screen content.
  FullScreenContentCallback<InterstitialAd>? fullScreenContentCallback;

  /// Loads an [InterstitialAd] with the given [licenseKey] and [request].
  static Future<void> load({
    required String licenseKey,
    required AdRequest request,
    required InterstitialAdLoadCallback adLoadCallback,
  }) async {
    InterstitialAd ad = InterstitialAd._(
        licenseKey: licenseKey,
        adLoadCallback: adLoadCallback,
        request: request);

    await instanceManager.loadInterstitialAd(ad);
  }

  /// Displays this on top of the application.
  ///
  /// Set [fullScreenContentCallback] before calling this method to be
  /// notified of events that occur when showing the ad.
  Future<void> show() {
    debugPrint('InterstitialAd call show()');
    return instanceManager.showAdWithoutView(this);
  }
}

class BannerAd extends AdWithView {
  /// Default constructor for [BannerAd].
  BannerAd({
    required this.size,
    required String licenseKey,
    required this.listener,
    required this.request,
  }) : super(licenseKey: licenseKey, listener: listener);

  /// Targeting information used to fetch an [Ad].
  final AdRequest request;

  /// A listener for receiving events in the ad lifecycle.
  @override
  final BannerAdListener listener;

  /// Ad sizes supported by this [BannerAd].
  ///
  /// In most cases, only one ad size will be specified. Multiple ad sizes can
  /// be specified if your application can appropriately handle multiple ad
  /// sizes. If multiple ad sizes are specified, the [BannerAd] will
  /// assume the size of the first ad size until an ad is loaded.
  final BannerAdSize size;

  @override
  Future<void> load() async {
    await instanceManager.loadBannerAd(this);
  }

  /// Returns the AdSize of the associated platform ad object.
  ///
  /// The future will resolve to null if [load] has not been called yet.
  /// The dimensions of the [BannerAdSize] returned here may differ from [sizes],
  /// depending on what type of [BannerAdSize] was used.
  Future<BannerAdSize?> getPlatformAdSize() async {
    return await instanceManager.getAdSize(this);
  }
}

/// [BannerAdSize] represents the size of a banner ad.
class BannerAdSize {
  /// Constructs an [BannerAdSize] with the given [width] and [height].
  const BannerAdSize({
    required this.width,
    required this.height,
  });

  /// The vertical span of an ad.
  final int height;

  /// The horizontal span of an ad.
  final int width;

  /// The standard banner (320x50) size.
  static const BannerAdSize banner = BannerAdSize(width: 320, height: 50);

  /// The large banner (320x100) size.
  static const BannerAdSize largeBanner = BannerAdSize(width: 320, height: 100);

  /// The large rectangle (320x480) size.
  static const BannerAdSize largeRectangle =
      BannerAdSize(width: 320, height: 480);

  /// The medium rectangle (300x250) size.
  static const BannerAdSize mediumRectangle =
      BannerAdSize(width: 300, height: 250);

  /// The full banner (468x60) size.
  static const BannerAdSize fullBanner = BannerAdSize(width: 468, height: 60);

  /// The leaderboard (728x90) size.
  static const BannerAdSize leaderboard = BannerAdSize(width: 728, height: 90);

  @override
  bool operator ==(Object other) {
    return other is BannerAdSize &&
        width == other.width &&
        height == other.height;
  }
}

/// Error information about why an ad operation failed.
class AdError {
  /// Creates an [AdError] with the given [code], [domain] and [message].
  @protected
  AdError(this.code, this.domain, this.message);

  final int code;

  /// The domain from which the error came.
  final String domain;
  final String message;

  @override
  String toString() {
    return '$runtimeType(code: $code, domain: $domain, message: $message)';
  }
}

class LoadAdError extends AdError {
  /// Default constructor for [LoadAdError].
  @protected
  LoadAdError(int code, String domain, String message)
      : super(code, domain, message);

  @override
  String toString() {
    return '$runtimeType(code: $code, domain: $domain, message: $message'
        ')';
  }
}
