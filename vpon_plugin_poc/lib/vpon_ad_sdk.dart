import 'ad_instance_manager.dart';
import 'ad_request.dart';

class VponAdSDK {
  VponAdSDK._();

  static final VponAdSDK _instance = VponAdSDK._().._init();

  static VponAdSDK get instance => _instance;

  void _init() {
    instanceManager.channel.invokeMethod('_init');
  }

  Future<void> initialize() {
    return instanceManager.initialize();
  }

  Future<void> updateRequestConfiguration(
      RequestConfiguration requestConfiguration) {
    return instanceManager.updateRequestConfiguration(requestConfiguration);
  }
}
