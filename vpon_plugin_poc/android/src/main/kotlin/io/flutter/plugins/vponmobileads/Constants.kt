package io.flutter.plugins.vponmobileads

internal object Constants {
    const val CHANNEL_NAME_TO_FLUTTER: String = "plugins.flutter.io/vpon"

    const val METHOD_GET_VERSION_STRING: String = "getVersionString"
    const val METHOD_GET_VPON_ID: String = "getVponID"
    const val _init: String = "_init"
    const val METHOD_INITIALIZE_SDK: String = "initializeSDK"
    const val METHOD_SET_LOG_LEVEL: String = "setLogLevel"
    const val METHOD_ENABLE_LOCATION_MANAGER: String = "setLocationManagerEnable"
    const val METHOD_SET_AUDIO_MANAGER: String = "setAudioApplicationManaged"
    const val METHOD_NOTICE_APPLICATION_AUDIO_DID_END: String = "noticeApplicationAudioDidEnd"
    const val METHOD_SET_CONSENT_STATUS: String = "setConsentStatus"
    const val METHOD_UPDATE_REQUEST_CONFIGURATION: String = "updateRequestConfiguration"
    const val METHOD_LOAD_INTERSTITIAL_AD: String = "loadInterstitialAd"
    const val METHOD_LOAD_BANNER_AD: String = "loadBannerAd"
    const val METHOD_LOAD_NATIVE_AD: String = "loadNativeAd"
    const val METHOD_DISPOSE_AD: String = "disposeAd"
    const val METHOD_SHOW_AD_WITHOUT_VIEW: String = "showAdWithoutView"

    const val CHANNEL_ARGUMENT_ADID: String = "adId"
    const val CHANNEL_ARGUMENT_LICENSE_KEY: String = "licenseKey"
    const val CHANNEL_ARGUMENT_AD_REQUEST: String = "request"
    const val CHANNEL_ARGUMENT_FACTORY_ID: String = "factoryId"
    const val CHANNEL_ARGUMENT_AD_SIZE: String = "size"
    const val CHANNEL_ARGUMENT_EVENT_NAME: String = "eventName"
    const val CHANNEL_ARGUMENT_ON_AD_EVENT: String = "onAdEvent"
    const val CHANNEL_ARGUMENT_LOAD_AD_ERROR: String = "loadAdError"
    const val CHANNEL_ARGUMENT_ERROR: String = "error"
    const val CHANNEL_ARGUMENT_ERROR_DESCRIPTION: String = "errorDescription"
    const val CHANNEL_ARGUMENT_ERROR_CODE: String = "errorCode"
}