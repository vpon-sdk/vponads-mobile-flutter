//
//  Utils.swift
//  vpon_mobile_ads
//
//  Created by vponinc on 2024/1/31.
//

import Foundation
import OSLog
import Flutter

struct Constant {
    /// "plugins.flutter.io/vpon"
    static let channelName = "plugins.flutter.io/vpon"
    static let adId = "adId"
    static let onAdEvent = "onAdEvent"
    static let eventName = "eventName"
    static let loadAdError = "loadAdError"
    static let errorDescription = "errorDescription"
    static let errorCode = "errorCode"
    static let nativeLog = "nativeLog"
}

/// For handle FlutterMethodCall
extension String {
    static let initializeSDK = "initializeSDK"
    static let _init = "_init"
    static let setLogLevel = "setLogLevel"
    static let getVponID = "getVponID"
    static let setLocationManagerEnable = "setLocationManagerEnable"
    static let setAudioApplicationManaged = "setAudioApplicationManaged"
    static let noticeApplicationAudioWillStart = "noticeApplicationAudioWillStart"
    static let noticeApplicationAudioDidEnd = "noticeApplicationAudioDidEnd"
    static let setConsentStatus = "setConsentStatus"
    static let updateRequestConfiguration = "updateRequestConfiguration"
    static let getVersionString = "getVersionString"
    
    static let loadInterstitialAd = "loadInterstitialAd"
    static let loadBannerAd = "loadBannerAd"
    static let loadNativeAd = "loadNativeAd"
    static let disposeAd = "disposeAd"
    static let showAdWithoutView = "showAdWithoutView"
}

enum LogType: String {
    case info = "info"
    case debug = "debug"
    case error = "error"
}

extension FlutterError {
    static var invalidArgument: FlutterError { return FlutterError(code: "InvalidArgument", message: "The argument passed by Dart is null. Please check the spelling and type of the argument.", details: nil)}
}
