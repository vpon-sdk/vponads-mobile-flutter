//
//  AdPicture.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/3/24.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import WebKit

struct AdPicture {
    
    public var url: URL?
    /// 是否可以存圖片
    public var canStore: Bool = false
    /// 是否可以外導打開
    public var canOpen: Bool = false
    
    init(message: WKScriptMessage) {
        if let body = message.body as? String,
           let tmpURL = URL(string: FormatVerifier.formatURL(body)) {
            canOpen = UIApplication.shared.canOpenURL(tmpURL)
            self.url = tmpURL
        }
        
        self.canStore = FormatVerifier.checkUsageDescription("NSPhotoLibraryUsageDescription")
    }
}
