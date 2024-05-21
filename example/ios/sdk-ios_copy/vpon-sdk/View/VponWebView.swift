//
//  VponWebView.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/10/2.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import UIKit
import WebKit

class VponWebView: WKWebView {
    
    init(frame: CGRect) {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.preferences.javaScriptEnabled = true
        config.mediaTypesRequiringUserActionForPlayback = []
        super.init(frame: frame, configuration: config)
        
        self.accessibilityIdentifier = "com.vpon.ad.webview"
        self.translatesAutoresizingMaskIntoConstraints = false
        self.isOpaque = false
        self.scrollView.isScrollEnabled = false
        self.scrollView.bounces = false

#if DEBUG
        if #available(iOS 16.4, *) {
            self.isInspectable = true
        }
#endif
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
