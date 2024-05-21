//
//  AdEvent.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/3/23.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import WebKit

struct AdEvent {
    
    var eventType: String = ""
    var sessionID: String = ""
    
    init(message: WKScriptMessage) {
        if let body = message.body as? String,
           let data = JsonParseHelper.jsonToDictionary(with: body) as? [String: String] {
            eventType = data["eventType"] ?? ""
            sessionID = data["sessionId"] ?? ""
        }
    }
}
