
import 'ad_containers.dart';
import 'ad_instance_manager.dart';
import 'ad_listeners.dart';
import 'ad_request.dart';

class BannerAd extends AdWithView {
  BannerAd({
    required this.size,
    required String licenseKey,
    required this.listener,
    required this.request,
    bool? autoRefresh,
  }) : autoRefresh = autoRefresh ?? false, super(licenseKey: licenseKey, listener: listener);

  final VponAdRequest request;

  @override
  final BannerAdListener listener;

  final BannerAdSize size;

  bool autoRefresh = false;

  @override
  Future<void> load() async {
    await instanceManager.loadBannerAd(this, autoRefresh: autoRefresh);
  }

  Future<BannerAdSize?> getPlatformAdSize() async {
    return await instanceManager.getAdSize(this);
  }
}

class BannerAdSize {
  const BannerAdSize({
    required this.width,
    required this.height,
  });

  final int height;

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