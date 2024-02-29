//
//  JavaScriptFunc.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/11/1.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

/// 被 JS 呼叫的 func name
protocol JavaScriptFunc { }

enum DisplayAdJavaScriptFunc: String, CaseIterable, JavaScriptFunc {
    case logger = "logger"
    case omEventOccur = "omEventOccur"
    case setInitialProperties = "setInitialProperties"
    case click = "click"
    
    // ----- MRAID Methods -----
    case mraid_open = "open"
    case mraid_close = "close"
    case mraid_unload = "unload"
    case mraid_expand = "expand"
    case mraid_resize = "resize"
    case mraid_playVideo = "playVideo"
    case mraid_storePicture = "storePicture"
    case mraid_createCalendarEvent = "createCalendarEvent"
    
    case doSupports = "doSupports"
    case sendSupportsToMraid = "sendSupportsToMraid"
    
    case doGetCurrentAppOrientation = "doGetCurrentAppOrientation"
    case sendCurrentAppOrientationToMraid = "sendCurrentAppOrientationToMraid"
    
    case doGetCurrentPosition = "doGetCurrentPosition"
    case sendCurrentPositionToMraid = "sendCurrentPositionToMraid"
    
    case doGetDefaultPosition = "doGetDefaultPosition"
    case sendDefaultPositionToMraid = "sendDefaultPositionToMraid"
    
    case doGetMaxSize = "doGetMaxSize"
    case sendMaxSizeToMraid = "sendMaxSizeToMraid"
    
    case doGetScreenSize = "doGetScreenSize"
    case sendScreenSizeToMraid = "sendScreenSizeToMraid"
    
    case doGetLocation = "doGetLocation"
    case sendLocationToMraid = "sendLocationToMraid"
    
    case sendNativeEnv = "sendNativeEnv"
    case sendAllSupportsToMraid = "sendAllSupportsToMraid"
    case sendPlacementTypeToMraid = "sendPlacementTypeToMraid"
    case sendLastViewablePercentage = "sendLastViewablePercentage"
}

enum NativeAdJavaScriptFunc: String, CaseIterable, JavaScriptFunc {
    case onVolumeChange = "onVolumeChange"
    case onComplete = "onComplete"
    case onPause = "onPause"
    case onResume = "onResume"
    case onReplay = "onReplay"
    case onFirstQuartile = "onFirstQuartile"
    case onMidPoint = "onMidPoint"
    case onThirdQuartile = "onThirdQuartile"
    case onStart = "onStart"
    case onBufferStart = "onBufferStart"
    case onBufferFinished = "onBufferFinished"
    case onPlayerStateChanged = "onPlayerStateChanged"
    case performCallToAction = "performCallToAction"
    case getLastViewablePercentage = "getLastViewablePercentage"
    case logger = "logger"
}
