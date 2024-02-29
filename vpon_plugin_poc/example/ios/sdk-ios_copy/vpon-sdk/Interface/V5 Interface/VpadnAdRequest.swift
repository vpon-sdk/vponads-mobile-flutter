//
//  VPAdRequest.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/4/24.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import CoreLocation

@available(*, deprecated, message: "Use VponFriendlyObstructionType instead.")
@objc public enum VpadnFriendlyObstructionType: Int {
    case mediaControls = 0
    case closeAd
    case notVisible
    case other
}

@available(*, deprecated, message: "Use VponUserGender instead.")
@objc public enum VpadnUserGender: Int {
    case unspecified = -1
    case male
    case female
    case unknown
}

@available(*, deprecated, message: "Use VponMaxAdContentRating instead.")
@objc public enum VpadnMaxAdContentRating: Int {
    case unspecified = -1
    case general
    case parentalGuidance
    case teen
    case matureAudience
}

@available(*, deprecated, message: "Use VponTagForChildDirectedTreatment instead.")
@objc public enum VpadnTagForChildDirectedTreatment: Int {
    case unspecified = -1
    case notForChildDirectedTreatment
    case forChildDirectedTreatment
}

@available(*, deprecated, message: "Use VponTagForUnderAgeOfConsent instead.")
@objc public enum VpadnTagForUnderAgeOfConsent: Int {
    case unspecified = -1
    case notForUnderAgeOfConsent
    case forUnderAgeOfConsent
}

@available(*, deprecated, message: "Use VponAdRequest instead.")
@objcMembers public final class VpadnAdRequest: NSObject {
    
    // MARK: - Properties
    
    /// Publisher 傳入的位置（目前 SDK 沒在使用）
    internal var userLocation: CLLocation?
    /// 是否能夠自動播放
    @objc public var autoRefresh: Bool = false
    /// 是否取測試廣告
    internal var adTest: String = "0"
    /// 設置 ContentURL
    internal var contentURL: String?
    /// 設置 ContentData
    internal var contentDict: [String: Any] = [:]
    /// 是否有關鍵字群
    internal var haveKeyword: Bool = false
    /// 關鍵字群
    internal var keywords: [String] = []
    /// 是否有額外的資訊
    internal var haveExtraData: Bool = false
    /// 額外資訊
    internal var extraData: [String: Any] = [:]
    /// 最高可投放的年齡(分類)限制
    internal var maxAdContentRating: VpadnMaxAdContentRating = .unspecified
    /// 是否專為特定年齡投放
    internal var underAgeOfConsent: VpadnTagForUnderAgeOfConsent = .unspecified
    /// 是否專為兒童投放
    internal var childDirectedTreatment: VpadnTagForChildDirectedTreatment = .unspecified
    /// 排除遮蔽偵測的視圖們
    internal var friendlyObstructions: [VpadnAdObstruction] = []
    
    /// 取得當前版號
    public class func sdkVersion() -> String {
        return SDK_PLATFORM.appending(SDK_VERSION)
    }
    
    // MARK: - 使用者資訊
    
    /// 設定定位位置
    public func setUserInfoLocation(_ location: CLLocation) {
        self.userLocation = location
    }
    
    /// 設定使用者年齡
    public func setUserInfoAge(_ age: Int) {
        DeviceInfo.shared.age = age
    }
    
    /// 設定使用者生日
    public func setUserInfoBirthday(year: Int, month: Int, day: Int) {
        if day > 31 || day < 0 {
            VponConsole.log("UserInfo Birthday Wrong : day invaild ( 1 - 31 )", .warning)
            return
        }
        if month > 12 || month < 0 {
            VponConsole.log("UserInfo Birthday Wrong : month invaild ( 1 - 12 )", .warning)
            return
        }
        if year < 1900 {
            VponConsole.log("UserInfo Birthday Wrong : year invaild (Ex : 1980 )", .warning)
            return
        }
        DeviceInfo.shared.setBirthday(year: year, month: month, day: day)
    }
    
    /// 設定使用者性別
    public func setUserInfoGender(_ gender: VpadnUserGender) {
        DeviceInfo.shared.gender = VponUserGender(rawValue: gender.rawValue) ?? .unspecified
    }
    
    // MARK: - 廣告內容相關
    
    @available(*, deprecated, message: "Use VponAdRequestConfiguration.shared.testDeviceIdentifiers instead.")
    public func setTestDevices(_ testDevices: [String]) {
        if DeviceInfo.isTestDevice(testIDFA: testDevices) {
            adTest = "1"
        } else {
            adTest = "0"
        }
    }
    
    /// 最高可投放的年齡(分類)限制
    public func setTagFor(maxAdContentRating: VpadnMaxAdContentRating) {
        self.maxAdContentRating = maxAdContentRating
    }
    
    /// 是否專為特定年齡投放
    public func setTagFor(underAgeOfConsent: VpadnTagForUnderAgeOfConsent) {
        self.underAgeOfConsent = underAgeOfConsent
    }
    
    /// 是否專為兒童投放
    public func setTagFor(childDirectedTreatment: VpadnTagForChildDirectedTreatment) {
        self.childDirectedTreatment = childDirectedTreatment
    }
    
    /// 設置 ContentURL
    /// - Parameter contentURL: 內容網址
    public func setContentUrl(_ contentURL: String) {
        let url = contentURL.addingPercentEncoding(withAllowedCharacters: .urlUserAllowed)
        if self.contentURL != url {
            self.contentURL = url
        }
    }
    
    /// 設置 ContentData
    /// - Parameter contentData: 內容
    public func setContentData(_ contentData: [String: Any]) {
        self.contentDict = contentData
    }
    
    /// 新增 ContentData
    /// - Parameters:
    ///   - key: 鍵
    ///   - value: 值
    public func addContentData(key: String, value: String) {
        self.contentDict[key] = value
    }
    
    // MARK: - Friendly Obstruction
    
    /// 排除遮蔽偵測的視圖
    public func addFriendlyObstruction(_ obstructView: UIView, purpose: VpadnFriendlyObstructionType, description: String) {
        let obstruction = VpadnAdObstruction()
        obstruction.view = obstructView
        obstruction.purpose = purpose
        let regex = "^[A-Za-z0-9 ]+$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        let matches = predicate.evaluate(with: description)
        if matches {
            obstruction.desc = description
        }
        self.friendlyObstructions.append(obstruction)
    }
    
    // MARK: - 關鍵字
    
    /// 設定關鍵字
    /// ```
    /// 可以使用 Key:Value 的方式 addKeyword(@"Keyword1: Value1"), 同時也可以直接關鍵字直接加入 addKeyword(@"Keyword")
    /// ```
    /// - Parameter keyword: 關鍵字 / 鍵值
    public func addKeyword(_ keyword: String) {
        let arrExtraData = keyword.components(separatedBy: ":")
        if arrExtraData.count >= 2 {
            
            var strValue = arrExtraData[1]
            if arrExtraData.count > 2 {
                for i in 2..<arrExtraData.count {
                    strValue = strValue.appendingFormat(":%@", arrExtraData[i])
                }
            }
            haveExtraData = true
            addPublisherExtraData(key: arrExtraData[0], value: strValue)
            
        } else {
            haveKeyword = true
            keywords.append(keyword)
        }
    }
    
    // MARK: - Private Method
    
    private func addPublisherExtraData(key: String, value: String) {
        self.extraData[key] = value
    }
}

// MARK: - v5.6 integration

extension VpadnAdRequest {
    
    /// 轉型成 v5.6 VponAdRequest 介面
    func toNewInterface() -> VponAdRequest {
        let newRequest = VponAdRequest()
        newRequest.keywords = self.keywords
        newRequest.contentDict = self.contentDict
        newRequest.contentURL = self.contentURL
        newRequest.extraData = self.extraData
        
        let newObs = self.friendlyObstructions.map { (obstruction) -> VponAdObstruction in
            
            let result = VponAdObstruction()
            result.purpose = VponFriendlyObstructionType(rawValue: obstruction.purpose.rawValue) ?? .other
            result.desc = obstruction.desc
            result.view = obstruction.view
            
            return result
        }
        newRequest.friendlyObstructions = newObs
        
        VponAdRequestConfiguration.shared.maxAdContentRating = VponMaxAdContentRating(rawValue: self.maxAdContentRating.rawValue) ?? .unspecified
        VponAdRequestConfiguration.shared.tagForChildDirectedTreatment = VponTagForChildDirectedTreatment(rawValue: self.childDirectedTreatment.rawValue) ?? .unspecified
        VponAdRequestConfiguration.shared.tagForUnderAgeOfConsent = VponTagForUnderAgeOfConsent(rawValue: self.underAgeOfConsent.rawValue) ?? .unspecified
        
        return newRequest
    }
}
