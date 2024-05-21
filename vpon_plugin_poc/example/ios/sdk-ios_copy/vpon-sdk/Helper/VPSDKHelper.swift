//
//  VPSDKHelper.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/4/19.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation
import OSLog

class VPSDKHelper {
    
    static let shared = VPSDKHelper()
    
    var showing = false
    var initSDK = false
    var logLevel: VpadnLogLevel = .defaultLevel
    
    private init() {}
    
    /// 取得 SDK 版本
    func getSDKVersion() -> String {
        return "\(SDK_PLATFORM)\(SDK_VERSION)"
    }
    
    /// 取得 SDK 版本出版日
    func getBuildNumber() -> String {
        return BUILD_NUMBER
    }
    
    /// 取得 App 名稱
    func getAppName() -> String {
        let infoDictionary = Bundle.main.infoDictionary
        let version = infoDictionary?["CFBundleVersion"] as? String ?? ""
        let identifier = infoDictionary?["CFBundleIdentifier"] as? String ?? ""
        return "\(version).iphone.\(identifier)"
    }
    
    /// 取得 Bundle ID
    func getAppID() -> String {
        return Bundle.main.bundleIdentifier ?? ""
    }
    
    /// 取得 SDK 支援程度
    /// ```
    /// 1, 表 VPAID 1.0
    /// 2, 表 VPAID 2.0
    /// 3, 表 MRAID-1
    /// 4, 表 ORMMA
    /// 5, 表 MRAID-2
    /// 6, 表 MRAID-3
    /// 7, 表 OMID-1
    /// 用 "," 隔開, ex: "6,7"
    /// ```
    func getApiFramework() -> String {
        return "7"
    }
    
    /// 取得 Key Window
    class func getKeyWindow() -> UIWindow? {
        if #available(iOS 13.0, *) {
            return UIWindow.keyWindow()
        } else {
            return UIApplication.shared.keyWindow
        }
    }
    
    /// SDK 資訊
    class func SDKNote() {
        VPSDKHelper.log("SDK Version: \(SDK_VERSION)", level: .info)
        VPSDKHelper.log("Build Date: \(BUILD_NUMBER)", level: .info)
        VPSDKHelper.log("IDFA: \(VPDeviceManager.shared.getAdvertisingIdentifier())", level: .info)
    }
    
    // MARK: - 初始化 SDK
    
    class func isInitSDK() -> Bool {
        if VPSDKHelper.shared.initSDK == false {
            NSLog("<VPON> [NOTE] [SDK-Initialization] Please initialize Vpon SDK before you made ad requests. http://wiki.vpon.com/ios/integration-guide/#initial-sdk")
            return false
        }
        return true
    }
    
    // MARK: - Logger
    
    class func log(_ message: String) {
        VPSDKHelper.log(message, level: .debug)
    }
    
    class func log(_ message: String, level levelTag: VPLogTag) {
        let thresholdLevel = VPSDKHelper.shared.logLevel
        if levelTag.rawValue >= thresholdLevel.rawValue {
            var tag = ""
            var osLogType: OSLogType
            switch levelTag {
            case .debug:
                tag = "[DEBUG]"
                osLogType = .default // .debug 實測在 console app 看不見
            case .info:
                tag = "[INFO]"
                osLogType = .info
            case .warning:
                tag = "[WARNING]"
                osLogType = .info
            case .error:
                tag = "[ERROR]"
                osLogType = .error
            case .note:
                tag = "[NOTE]"
                osLogType = .info
            }
            os_log("<VPON> %@ %@", log: .default, type: osLogType, tag, message)
        }
    }
}
