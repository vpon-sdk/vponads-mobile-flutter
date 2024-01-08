import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'vpon_plugin_poc_method_channel.dart';

abstract class VponPluginPocPlatform extends PlatformInterface {
  /// Constructs a VponPluginPocPlatform.
  VponPluginPocPlatform() : super(token: _token);

  static final Object _token = Object();

  static VponPluginPocPlatform _instance = MethodChannelVponPluginPoc();

  /// The default instance of [VponPluginPocPlatform] to use.
  ///
  /// Defaults to [MethodChannelVponPluginPoc].
  static VponPluginPocPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [VponPluginPocPlatform] when
  /// they register themselves.
  static set instance(VponPluginPocPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<void> loadInterstitialAd() {
    throw UnimplementedError('loadInterstitialAd() has not been implemented.');
  }
}