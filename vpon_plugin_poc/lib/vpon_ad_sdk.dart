import 'ad_instance_manager.dart';
import 'ad_request.dart';

class VponAdSDK {
  VponAdSDK._privateConstructor();

  static final VponAdSDK instance = VponAdSDK._privateConstructor();

  void _init() {
    instanceManager.channel.invokeMethod('_init');
  }

  Future<void> initialize() {
    return instanceManager.initialize();
  }

  Future<String?> getVponID() async {
    return instanceManager.getVponID();
  }

  Future<void> updateRequestConfiguration(
      RequestConfiguration requestConfiguration) {
    return instanceManager.updateRequestConfiguration(requestConfiguration);
  }
}

class VponAdLocationManager {
  VponAdLocationManager._privateConstructor();

  static final VponAdLocationManager instance =
      VponAdLocationManager._privateConstructor();

  bool _isEnable = true;
  bool get isEnable => _isEnable; 

  set isEnable(bool isEnable) {
    instanceManager.setLocationManagerEnable(isEnable);
  }
}
