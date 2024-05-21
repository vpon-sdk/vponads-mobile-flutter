//
//  VponConstants.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/10/2.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

// For build script to read
let BUILD_NUMBER = "normal"
let SDK_PLATFORM = "vpadn-sdk-i-"
let SDK_VERSION = "v5.6.0"

struct Constants {
    
    /// 120
    static let defaultRefreshAdTime = 120
    /// 20
    static let defaultRestartAdTime = 20
    /// 50
    static let defaultISCloseBtnDistance = 50
    
    struct Config {
        /// "config.nextUpdateTime"
        static let nextUpdateTime = "config.nextUpdateTime"
        /// "https://m.vpon.com/sdk/ios/config.json"
        static let url = "https://m.vpon.com/sdk/ios/config.json"
        
        /// "white_list"
        static let whiteList = "white_list"
        /// "bid"
        static let whiteListBid = "bid"
        /// "allowPercentage"
        static let whiteListAllowPercent = "allowPercentage"
        
        /// "ad_choices"
        static let adChoices = "ad_choices"
        /// "bid"
        static let adChoicesBid = "bid"
        /// "position"
        static let adChoicesPosition = "position"
        /// "url"
        static let adChoicesLink = "link"
    }
    
    struct AdChoicesPosition {
        /// "ur"
        static let upperRight = "ur"
        /// "ul"
        static let upperLeft = "ul"
        /// "lr"
        static let lowerRight = "lr"
        /// ll
        static let lowerLeft = "ll"
    }

    struct Domain {
        /// "https://tw-api.vpadn.com/api/webviewAdReq" 正式環境 request domain
        static let requestAdService =  "https://tw-api.vpadn.com/api/webviewAdReq"
        /// "https://tw-api-stg.vpon.com/api/webviewAdReq" 測試環境 request domain
        static let requestAdService_stg = "https://tw-api-stg.vpon.com/api/webviewAdReq"
        /// "https://m.vpon.com/sdk/vpon-i-mraid3.js"
        static let vpadnAdMraid3 = "https://m.vpon.com/sdk/vpon-i-mraid3.js"
        /// "https://b-dsp.vpadn.com/ad_choices"
        static let adChoices = "https://b-dsp.vpadn.com/ad_choices"
        /// "com.vpon.vpadnsdk"
        static let error = "com.vpon.vpadnsdk"
    }
    
    struct ADNResponse {
        /// "Location"
        static let location = "Location"
        /// "Vpadn-Clk"
        static let click = "Vpadn-Clk"
        /// "Vpadn-Imp"
        static let impression = "Vpadn-Imp"
        /// "Vpadn-OnShow"
        static let onShow = "Vpadn-OnShow"
        /// "Vpadn-Status-Code"
        static let statusCode = "Vpadn-Status-Code"
        /// "Vpadn-Status"
        static let status = "Vpadn-Status"
        /// "Vpadn-Status-Desc"
        static let statusDescription = "Vpadn-Status-Desc"
        /// "Vpadn-Refresh-Time"
        static let refreshTime = "Vpadn-Refresh-Time"
        /// "om"
        static let om = "om"
        /// req_id
        static let requestID = "req_id"
    }
    
    struct MediaSoucre {
        /// 86400
        static let interval = 86400
        /// "https://m.vpon.com/tpl/vpon-nativead-video-tpl-v2.html"
        static let nativeVideoTpl =  "https://m.vpon.com/tpl/vpon-nativead-video-tpl-v2.html"
        /// "vpon-nativead-video-tpl-v2"
        static let videoTplFileName = "vpon-nativead-video-tpl-v2"
        /// "REPLACE_MACRO_CONTENT"
        static let replaceMacro = "REPLACE_MACRO_CONTENT"
        /// "isIOS"
        static let isiOS = "isIOS"
        /// "mediaViewablePercentage"
        static let mediaViewablePercentage = "mediaViewablePercentage"
    }
    
    struct OM {
        
        struct ADNKey {
            /// "t"
            static let adType = "t"
            /// "k"
            static let vendorKey = "k"
            /// "p"
            static let vendorParams = "p"
            /// "u"
            static let verificationResources = "u"
            /// "v"
            static let verification = "v"
            
            // For InRead
            /// "vendor"
            static let vendor = "vendor"
            /// "verificationParameters"
            static let verificationParams = "verificationParameters"
            /// "javaScriptResources"
            static let javaScriptResources = "javaScriptResources"
        }
        
        struct ADNAdType {
            /// "d"
            static let display = "d"
            /// "dv"
            static let displayVideo = "dv"
            /// "n"
            static let native = "n"
            /// "nv"
            static let nativeAdVideo = "nv"
            /// "v"
            static let nativeVideo = "v"
        }
        
        /// "Vpon"
        static let partnerName = "Vpon"
        /// "https://m.vpadn.com/om/omsdk-vpon-latest.js"
        static let jsService = "https://m.vpadn.com/om/omsdk-vpon-latest.js"
        /// 86400
        static let serviceUpdateInterval = 86400
    }
    
    /// 呼叫 JS 的 func name
    struct JSFunc {
        // Native(Active)
        static let nativeOnExposureChange = "_internal_video.onExposureChange"
        static let nativeEnterFullscreen = "_internal_video.enterFullscreen"

        static let onDeviceReady = "_internal_ios.onDeviceReady"
        static let onShow = "_internal_ios.onShow"
        static let onHide = "_internal_ios.onHide"
        static let onExposureChange = "_internal_ios.onExposureChange"
        static let onImpression = "_internal_ios.onImpression"
        static let onAudioVolumeChange = "_internal_ios.onAudioVolumeChange"
        static let setPlacementType = "_internal_ios.setPlacementType"
        static let getOrientationProperties = "_internal_ios.getOrientationProperties"
        static let setEnvFromNative = "_internal_ios.setEnvFromNative"
        static let isVideoAd = "_internal_ios.isVideoAd"

        static let willResignActive = "_internal_ios.willResignActive"
        static let didBecomeActive = "_internal_ios.didBecomeActive"

        // Native(Passive)
        static let setSupports = "_internal_ios.setSupports"
        static let setCurrentAppOrientation = "_internal_ios.setCurrentAppOrientation"
        static let setCurrentPosition = "_internal_ios.setCurrentPosition"
        static let setGetDefaultPosition = "_internal_ios.setGetDefaultPosition"
        static let setMaxSize = "_internal_ios.setMaxSize"
        static let setScreenSize = "_internal_ios.setScreenSize"
        static let setLocation  = "_internal_ios.setLocation"
    }
    
    struct ViewableDetection {
        static let detectionRestart = 500
        static let viewableDuration = 1000
        static let viewableRate = 0.5
    }
    
    struct NativeAdKey {
        /// "action_name"
        static let actionName = "action_name"
        /// "ad_label"
        static let adLabel = "ad_label"
        /// "body"
        static let body = "body"
        /// "cover_h"
        static let coverHeight = "cover_h"
        /// "cover_w"
        static let coverWidth = "cover_w"
        /// "cover_url"
        static let coverURL = "cover_url"
        /// "icon_h"
        static let iconHeight = "icon_h"
        /// "icon_w"
        static let iconWidth = "icon_w"
        /// "icon_url"
        static let iconURL = "icon_url"
        /// "lnk"
        static let link = "lnk"
        /// "r_s"
        static let r_s = "r_s"
        /// "r_v"
        static let r_v = "r_v"
        /// "social_c"
        static let socialContext = "social_c"
        /// "title"
        static let title = "title"
        /// "thr_track_array"
        static let thirdTrackingsArray = "thr_track_array"
        /// "thr_track"
        static let thirdTracking = "thr_track"

        static let defaultCoverImageWidth = 1200
        static let defaultCoverImageHeight = 627
        static let defaultIconImageWidth = 128
        static let defaultIconImageHeight = 128
    }
    
    struct UserDefaults {
        static let config = "config"
        /// "com.vpon.vponsdk.user.agent"
        static let userAgent = "com.vpon.vponsdk.user.agent"
        static let ctid = "vpadn-ctid"
        static let ctidVersion = "v1"
        static let consent = "vpon_ucb_key_consent"
        static let mediaSource = "vpadn.media.source.time.key"
        static let omService = "vpadn.om.service"
        static let omServiceJS = "vpadn.om.service.js"
        static let omServiceTime = "vpadn.om.service.time"
    }
    
}
