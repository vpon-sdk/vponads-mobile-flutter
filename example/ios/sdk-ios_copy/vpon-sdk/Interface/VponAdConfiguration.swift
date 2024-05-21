//
//  VponAdConfiguration.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/10/25.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

@objc public enum VponLogLevel: Int {
    case debug = 0
    case `default`
    case dontShow
}

/// SDK 基本通用設定
@objcMembers public final class VponAdConfiguration: NSObject {
    
    /// SDK 是否初始化完成
    private var initSDK = false
    
    public var logLevel: VponLogLevel = .default {
        didSet {
            #if RELEASE
            if logLevel == .debug {
                logLevel = .default
                VponConsole.log("Current is [RELEASE] verison, can't use VponLogLevelDebug tag.", .note)
            }
            #endif
        }
    }
    public var audioManager = VponAdAudioManager.shared
    public var locationManager = VponAdLocationManager.shared
    public static let shared = VponAdConfiguration()
    
    private let sdk = SDKHelper.shared
  
    /// 初始化 SDK
    public func initializeSdk() {
        if initSDK { return }
        initSDK = true
        
        if !audioManager.isAudioApplicationManaged {
            audioManager.isAudioApplicationManaged = false
            audioManager.setCategoryAndMixOthers()
            audioManager.setActive(true)
        }
        RemoteConfigManager.shared.checkConfig()
        VponAdLocationManager.shared.startFirstTimer()
        DeviceInfo.setUserAgent()
        VponConsole.log("[SDK-Initialization] Initialization has already completed.", .note)
    }
    
    /// 取得 Vpon ID
    public func getVponID() -> String {
        return DeviceInfo.shared.getCTID()
    }
    
    internal func isInitSDK() -> Bool {
        if initSDK == false {
            VponConsole.log("[SDK-Initialization] Please initialize Vpon SDK before you made ad requests. http://wiki.vpon.com/ios/integration-guide/#initial-sdk", .note)
            return false
        }
        return true
    }
    
    /// 取得當前版號
    public class func sdkVersion() -> String {
        return SDK_PLATFORM.appending(SDK_VERSION)
    }
}
