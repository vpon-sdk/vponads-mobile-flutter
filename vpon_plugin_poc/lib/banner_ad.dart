
import 'ad_containers.dart';
import 'ad_instance_manager.dart';
import 'ad_listeners.dart';
import 'ad_request.dart';

class BannerAd extends AdWithView {
  /// Default constructor for [BannerAd].
  BannerAd({
    required this.size,
    required String licenseKey,
    required this.listener,
    required this.request,
  }) : super(licenseKey: licenseKey, listener: listener);

  /// Targeting information used to fetch an [Ad].
  final VponAdRequest request;

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