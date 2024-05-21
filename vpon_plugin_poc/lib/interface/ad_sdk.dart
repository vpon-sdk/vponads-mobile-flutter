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

  Future<void> setLogLevel(VponLogLevel level) {
    return instanceManager.setLogLevel(level.value);
  }

  /// 取得 Vpon Ad SDK 版本號
  Future<String?> getVersionString() async {
    return await instanceManager.getVersionString();
  }

  Future<String?> getVponID() async {
    return await instanceManager.getVponID();
  }

  Future<void> updateRequestConfiguration(
      VponRequestConfiguration requestConfiguration) {
    return instanceManager.updateRequestConfiguration(requestConfiguration);
  }
}

enum VponLogLevel {
  debug(0),
  defaultLevel(1),
  dontShow(2);

  const VponLogLevel(this.value);
  final int value;
}

class VponAdLocationManager {
  VponAdLocationManager._privateConstructor();

  static final VponAdLocationManager instance =
      VponAdLocationManager._privateConstructor();

  Future<void> setIsEnable(bool isEnable) async {
    await instanceManager.setLocationManagerEnable(isEnable);
  }
}

class VponAdAudioManager {
  VponAdAudioManager._privateConstructor();

  static final VponAdAudioManager instance =
      VponAdAudioManager._privateConstructor();

  Future<void> setIsAudioApplicationManaged(bool isManaged) async {
    await instanceManager.setAudioApplicationManaged(isManaged);
  }

  /// Application 通知 SDK 即將播放影音或聲音
  Future<void> noticeApplicationAudioWillStart() async {
    await instanceManager.noticeApplicationAudioWillStart();
  }

  /// Application 通知 SDK 已結束播放影音或聲音
  Future<void> noticeApplicationAudioDidEnd() async {
    await instanceManager.noticeApplicationAudioDidEnd();
  }
}

class VponUCB {
  VponUCB._privateConstructor();

  static final VponUCB instance = VponUCB._privateConstructor();

  Future<void> setConsentStatus(VponConsentStatus status) async {
    await instanceManager.setConsentStatus(status.value);
  }
}

enum VponConsentStatus {
  unknown(-1),
  nonPersonalized(0),
  personalized(1);

  const VponConsentStatus(this.value);
  final int value;
}
