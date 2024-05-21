//
//  AdSendMsg.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/11/7.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

struct AdSendMsg {
    
    /// 目標電話群
    var recipients: [String]?
    /// 訊息內容
    var body: String?
    
    /// 是否合法使用
    private var isValid = false
    
    init(data: [String: Any]) {
        if let recipient = data["tel"] as? String {
            // one recipient
            self.recipients =  [FormatVerifier.formatPhoneNumber(recipient)]
            isValid = true
        } else if let recipients = data["tel"] as? [String] {
            // multiple recipients
            var validRecipients = [String]()
            for recipient in recipients {
                validRecipients.append(FormatVerifier.formatPhoneNumber(recipient))
            }
            self.recipients = validRecipients
            isValid = true
        }
        
        if let body = data["b"] as? String {
            self.body = body
        }
    }
    
    /// 是否可以發送
    func canSend() -> Bool {
        return isValid
    }
}
