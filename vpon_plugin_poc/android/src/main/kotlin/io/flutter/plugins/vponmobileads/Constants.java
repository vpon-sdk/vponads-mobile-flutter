package io.flutter.plugins.vponmobileads;

class Constants {

    final static String CHANNEL_NAME_TO_FLUTTER = "plugins.flutter.io/vpon";

    final static String METHOD_GET_VERSION_STRING = "getVersionString";
    final static String METHOD_GET_VPON_ID = "getVponID";
    final static String _init = "_init";
    final static String METHOD_INITIALIZE_SDK = "initializeSDK";
    final static String METHOD_SET_LOG_LEVEL = "setLogLevel";
    final static String METHOD_ENABLE_LOCATION_MANAGER = "setLocationManagerEnable";
    final static String METHOD_SET_AUDIO_MANAGER = "setAudioApplicationManaged";
    final static String METHOD_NOTICE_APPLICATION_AUDIO_DID_END = "noticeApplicationAudioDidEnd";
    final static String METHOD_SET_CONSENT_STATUS = "setConsentStatus";
    final static String METHOD_UPDATE_REQUEST_CONFIGURATION = "updateRequestConfiguration";
    final static String METHOD_LOAD_INTERSTITIAL_AD = "loadInterstitialAd";

    final static String CHANNEL_ARGUMENT_ADID = "adId";
    final static String CHANNEL_ARGUMENT_EVENT_NAME = "eventName";
    final static String CHANNEL_ARGUMENT_ON_AD_EVENT = "onAdEvent";
    final static String CHANNEL_ARGUMENT_LOAD_AD_ERROR = "loadAdError";
    final static String CHANNEL_ARGUMENT_ERROR_DESCRIPTION = "errorDescription";
    final static String CHANNEL_ARGUMENT_ERROR_CODE = "errorCode";
}
