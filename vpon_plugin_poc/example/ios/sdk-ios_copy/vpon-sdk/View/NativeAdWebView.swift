//
//  NativeAdWebView.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/11/1.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

final class NativeAdWebView: VponWebView {
    
    var contentHTML: String
    
    init(frame: CGRect, contentHTML: String) {
        self.contentHTML = contentHTML
        super.init(frame: frame)
    }
    
    // Will never get called
    required init?(coder: NSCoder) {
        self.contentHTML = ""
        super.init(coder: coder)
    }
    
    // MARK: - Load content
    
    func loadContentHTML() {
        self.loadHTMLString(contentHTML, baseURL: nil)
    }
    
    func loadURL(_ url: URL) {
        let request = URLRequest(url: url)
        self.load(request)
    }
    
    // MARK: - Deinit
    
    deinit {
        VponConsole.log("[ARC] NativeAdWebView deinit")
    }
}
