//
//  VponAdRequest.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/8/9.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

@objc public enum VponUserGender: Int {
    case unspecified = -1
    case male
    case female
    case unknown
}

@objcMembers public final class VponAdRequest: NSObject {
    
    /// URL string for a webpage whose content matches the app’s primary content. This webpage content is used for targeting and brand safety purposes.
    internal var contentURL: String?
    
    /// 關鍵字群
    internal var keywords: [String] = []
    
    /// 額外資訊
    internal var extraData: [String: Any] = [:]
    
    // ------ Vpon Parameters ------
    
    /// 設置 ContentData
    internal var contentDict: [String: Any] = [:]
    internal var format: String?
    private var sessionID: Float = Float(Date().timeIntervalSince1970)
    private var seqNo: Int = 0
    
    /// 排除遮蔽偵測的 view
    internal var friendlyObstructions: [VponAdObstruction] = []

    // MARK: - 使用者資訊
    
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
    public func setUserInfoGender(_ gender: VponUserGender) {
        DeviceInfo.shared.gender = gender
    }
    
    // MARK: - 廣告內容相關
    
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
    public func addFriendlyObstruction(_ obstructView: UIView, purpose: VponFriendlyObstructionType, description: String) {
        let obstruction = VponAdObstruction()
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
    /// 可以使用 Key:Value 的方式 addKeyword("Keyword1: Value1"), 同時也可以直接關鍵字直接加入 addKeyword("Keyword")
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
    
            addPublisherExtraData(key: arrExtraData[0], value: strValue)
            
        } else {
            keywords.append(keyword)
        }
    }
    
    // MARK: - Interal method
    
    /// Session Id
    internal func getSessionID() -> Int {
        return Int(sessionID)
    }
    
    /// Sequence NO
    internal func getSequenceNumber() -> Int {
        let result = seqNo
        seqNo += 1
        return result
    }
    
    // MARK: - Private method
    
    private func addPublisherExtraData(key: String, value: String) {
        self.extraData[key] = value
    }
    
    // MARK: - Deinit
    
    deinit {
        VponConsole.log("[ARC] VponAdRequest deinit")
    }
}
