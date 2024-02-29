//
//  AdClick.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/10/12.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

struct AdClick {
    
    var position: CGPoint?
    var positionArray: [String]?
    
    init(message: WKScriptMessage) {
        if let body = message.body as? String {
            let data = JsonParseHelper.jsonToDictionary(with: body)
            if let position = data["position"] as? [String: Any],
               let x = position["x"] as? CGFloat,
               let y = position["y"] as? CGFloat {
                self.position = CGPoint(x: x, y: y)
            }
        }
    }
}
