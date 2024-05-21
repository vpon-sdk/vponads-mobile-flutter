//
//  VponAdRequestConfiguration.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/10/25.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

@objc public enum VponMaxAdContentRating: Int {
    case unspecified = -1
    case general
    case parentalGuidance
    case teen
    case matureAudience
}

@objc public enum VponTagForChildDirectedTreatment: Int {
    case unspecified = -1
    case notForChildDirectedTreatment
    case forChildDirectedTreatment
}

@objc public enum VponTagForUnderAgeOfConsent: Int {
    case unspecified = -1
    case notForUnderAgeOfConsent
    case forUnderAgeOfConsent
}

@objcMembers public final class VponAdRequestConfiguration: NSObject {
    
    public static let shared = VponAdRequestConfiguration()
    
    private override init() {}
    
    /// 最高可投放的年齡(分類)限制
    public var maxAdContentRating: VponMaxAdContentRating = .unspecified
    
    /// 是否專為特定年齡投放
    public var tagForUnderAgeOfConsent: VponTagForUnderAgeOfConsent = .unspecified
    
    /// 是否專為兒童投放
    public var tagForChildDirectedTreatment: VponTagForChildDirectedTreatment = .unspecified
    
    /// 測試用的裝置 IDFA，以取得 Vpon 測試廣告
    public var testDeviceIdentifiers: [String]?
    
    internal var isTestAd: String {
        return DeviceInfo.isTestDevice(testIDFA: testDeviceIdentifiers ?? []) ? "1" : "0"
    }
}
