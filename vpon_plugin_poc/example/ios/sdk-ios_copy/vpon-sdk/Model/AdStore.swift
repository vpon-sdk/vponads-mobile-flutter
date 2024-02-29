//
//  AdStore.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/11/7.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

struct AdStore {
    
    /// iTunes (AppStore) Id
    var storeID: Int?
    /// 宣傳活動 Token
    var campaignToken: String?
    /// 開發商 Token
    var providerToken: String?
    /// 合作開發商 Token
    var partnerToken: String?
    
    private let STORE_ID = "store_id"
    private let CAMPAIGN_TOKEN = "campaign_id"
    private let PROVIDER_TOKEN = "provider_id"
    private let PARTNER_TOKEN = "adprovider_id"
    /// 是否合法使用
    private var isValid = false
    
    init(data: [String: Any]) {
        if data[STORE_ID] != nil {
            isValid = true
        }
        if let id = data[STORE_ID] as? Int {
            self.storeID = id
        }
        if let campaignToken = data[CAMPAIGN_TOKEN] as? String {
            self.campaignToken = campaignToken
        }
        if let providerToken = data[PROVIDER_TOKEN] as? String {
            self.providerToken = providerToken
        }
        if let partnerToken = data[PARTNER_TOKEN] as? String {
            self.partnerToken = partnerToken
        }
    }
    
    /// 是否可以開啟
    func canOpen() -> Bool {
        return isValid
    }
}
