//
//  SDKHelper.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/10/2.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

struct SDKHelper {
    
    static let shared = SDKHelper()

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
    static func getKeyWindow() -> UIWindow? {
        if #available(iOS 13.0, *) {
            return UIWindow.keyWindow()
        } else {
            return UIApplication.shared.keyWindow
        }
    }
}
