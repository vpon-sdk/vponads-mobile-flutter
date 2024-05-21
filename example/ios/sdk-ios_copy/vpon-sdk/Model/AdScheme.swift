//
//  AdScheme.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/3/22.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import WebKit

struct AdScheme {
    
    var url: URL?
    
    init(message: WKScriptMessage) {
        if let body = message.body as? String {
            let validURLString = FormatVerifier.formatURL(body)
            self.url = URL(string: validURLString)
        }
    }
    
    init(data: [String: Any], urlKey: String) {
        self.url = URL(string: data[urlKey] as? String ?? "")
    }
}
