//
//  VPUCB.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/4/25.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

@objc public enum VponConsentStatus: Int {
    case unknown = -1
    case nonPersonalized = 0
    case personalized = 1
}

@objcMembers public final class VponUCB: NSObject {
    
    public static let shared = VponUCB()
    
    internal let VPONUCB_KEY_CONSENT = "vpon_ucb_key_consent"
    internal let userDefault = UserDefaults.standard
    
    private override init() {
        super.init()
        let dictionary = userDefault.dictionaryRepresentation()
        if !dictionary.keys.contains(VPONUCB_KEY_CONSENT) {
            setConsentStatus(.unknown)
        }
    }
    
    public func setConsentStatus(_ status: VponConsentStatus) {
        let rawValue = String(status.rawValue)
        let data = rawValue.data(using: .utf8)
        let encodedData = data?.base64EncodedData()
        userDefault.set(encodedData, forKey: VPONUCB_KEY_CONSENT)
    }
}
