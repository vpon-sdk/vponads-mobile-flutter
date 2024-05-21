//
//  DisplayAdWebView.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/11/1.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import UIKit
import WebKit

protocol DisplayAdWebViewDelegate: AnyObject {
    func webViewShouldSendExposureChange(_ webView: DisplayAdWebView)
}

final class DisplayAdWebView: VponWebView {
    
    weak var vponDelegate: DisplayAdWebViewDelegate?
    
    var observer = false
    private var boundObserver = false
    private var offsetObserver = false
    private var needExposureChange = false
    private var observedViews = [UIView]()
    
    // MARK: - WKWebView func
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if needExposureChange {
            vponDelegate?.webViewShouldSendExposureChange(self)
        }
    }
    
    override func removeFromSuperview() {
        NSLayoutConstraint.vpc_removeAllConstraints(from: self)
        super.removeFromSuperview()
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        let visible = self.superview != nil && self.window != nil
        if visible {
            addContentOffsetObserverToSuperviews()
        } else {
            removeAllContentOffsetObserver()
        }
    }
    
    // MARK: - Load content
    
    func loadContent(html: String?, baseURL: URL?) {
        guard let html else {
            VponConsole.log("VponWebView load html failed because html is nil!")
            return
        }
        loadHTMLString(html: html, baseURL: baseURL)
    }
    
    /// 讀取替換好 mraid.js 的 html string
    private func loadHTMLString(html: String, baseURL: URL?) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let today = Date.dateString(Date(), format: "yyyyMMdd")
            let replace = Constants.Domain.vpadnAdMraid3.appending("?\(today)")
            if let newHtml = html.replace(tag: "mraid.js", with: replace) {
                self.loadHTMLString(newHtml, baseURL: baseURL)
            }
        }
    }
    
    // MARK: - KVO observer
    
    private func addContentOffsetObserverToSuperviews() {
        if !boundObserver {
            boundObserver = true
            self.layer.addObserver(self, forKeyPath: "bounds", context: nil)
        }
        if !offsetObserver {
            offsetObserver = true
            observedViews = []
            guard let superviews = self.superviews() else { return }
            for superview in superviews {
                if observedViews.contains(superview) { continue }
                if superview.responds(to: #selector(getter: UIScrollView.contentOffset)) {
                    superview.addObserver(self, forKeyPath: "contentOffset", context: nil)
                    observedViews.append(superview)
                }
            }
        }
    }
    
    private func removeAllContentOffsetObserver() {
        if boundObserver {
            boundObserver = false
            self.layer.removeObserver(self, forKeyPath: "bounds")
        }
        if offsetObserver {
            offsetObserver = false
            for superview in observedViews {
                if !superview.responds(to: #selector(getter: UIScrollView.contentOffset)) { continue }
                superview.removeObserver(self, forKeyPath: "contentOffset")
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "bounds" && observer {
            needExposureChange = true
        }
        if keyPath == "contentOffset" && observer {
            vponDelegate?.webViewShouldSendExposureChange(self)
        }
    }
    
    // MARK: - Deinit
    
    deinit {
        VponConsole.log("[ARC] DisplayAdWebView deinit")
    }
}
