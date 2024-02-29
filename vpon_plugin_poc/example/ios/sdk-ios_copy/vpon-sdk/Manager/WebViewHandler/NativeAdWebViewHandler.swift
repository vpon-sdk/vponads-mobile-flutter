//
//  NativeAdWebViewHandler.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/10/27.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

protocol NativeAdWebViewHandlerDelegate: WebViewHandlerDelegate {
    /// For presenting fullscreen cut2
    var rootViewController: UIViewController? { get }
    /// For presenting back to cut1
    func webViewDidChangePlayerStateToNormal(_ webView: WKWebView)
}

final class NativeAdWebViewHandler: WebViewHandler {
    
    internal var avoidPercentLessThan50 = false
    
    // OM events flags
    // onPause, onResume, onPlayStateChange are not used in current AD SDK version
    private var onVolumeChange = false
    private var onReplay = false
    private var onPlayStateChange = false
    private var onPause = false
    private var onResume = false
    private var onBufferStart = false
    private var onBufferFinished = false
    private var onStart = false
    private var onFirstQuartile = false
    private var onMidPoint = false
    private var onThirdQuartile = false
    private var onComplete = false
    
    private var events: [String]
    private var videoStateManager: VideoStateManager
    
    /// For native video cut2 使用，目前被呼叫
    private var fullScreenVC: AdPresentationViewController?
    
    init(webView: VponWebView, adLifeCycleManager: AdLifeCycleManager, videoStateManager: VideoStateManager) {
        self.events = NativeAdJavaScriptFunc.allCases.map({ $0.rawValue })
        self.videoStateManager = videoStateManager
        super.init(webView: webView, adLifeCycleManager: adLifeCycleManager)
        for event in events {
            webView.configuration.userContentController.add(self, name: event)
        }
    }
    
    // MARK: - Native call JS
    
    func sendNativeExposureChange(_ message: String) {
        evaluateJSName(Constants.JSFunc.nativeOnExposureChange, message: message)
    }
    
    // MARK: - JS Call native
    
    private func onVolumeChange(_ message: WKScriptMessage) {
        guard let body = message.body as? String else { return }
        VponConsole.log("\(#function) [Line \(#line)] args: \(body)")
        
        let data = JsonParseHelper.jsonToDictionary(with: body)
        if let volume = data["volume"] as? CGFloat {
            videoStateManager.notify(.onVideoVolumeChange, data: ["volume": volume])
            if onVolumeChange { return }
            onVolumeChange = true
        }
    }
    
    private func onPause(_ message: WKScriptMessage) {
        guard let body = message.body as? String else { return }
        VponConsole.log("\(#function) [Line \(#line)] args: \(body)")
        videoStateManager.notify(.onVideoPause)
        if onPlayStateChange { return }
        onPlayStateChange = true
    }
    
    private func onResume(_ message: WKScriptMessage) {
        guard let body = message.body as? String else { return }
        VponConsole.log("\(#function) [Line \(#line)] args: \(body)")
        videoStateManager.notify(.onVideoResume)
        if onPlayStateChange { return }
        onPlayStateChange = true
    }
    
    private func onBufferStart(_ message: WKScriptMessage) {
        if onBufferStart { return }
        onBufferStart = true
        guard let body = message.body as? String else { return }
        VponConsole.log("\(#function) [Line \(#line)] args: \(body)")
        videoStateManager.notify(.onVideoBufferStart)
    }
    
    private func onBufferFinish(_ message: WKScriptMessage) {
        if onBufferFinished { return }
        onBufferFinished = true
        guard let body = message.body as? String else { return }
        VponConsole.log("\(#function) [Line \(#line)] args: \(body)")
        videoStateManager.notify(.onVideoBufferFinish)
    }
    
    private func onStart(_ message: WKScriptMessage) {
        if onStart { return }
        onStart = true
        guard let body = message.body as? String else { return }
        VponConsole.log("\(#function) [Line \(#line)] args: \(body)")
        videoStateManager.notify(.onVideoResume)
        
        if let body = message.body as? String {
            let data = JsonParseHelper.jsonToDictionary(with: body)
            if let duration = data["duration"] as? CGFloat,
               let volume = data["volume"] as? CGFloat {
                videoStateManager.notify(.onVideoStart, data: ["duration": duration, "volume": volume])
            }
        }
    }
    
    private func onFirstQuartile(_ message: WKScriptMessage) {
        if onFirstQuartile { return }
        onFirstQuartile = true
        guard let body = message.body as? String else { return }
        VponConsole.log("\(#function) [Line \(#line)] args: \(body)")
        videoStateManager.notify(.onVideoFirstQuartile)
    }
    
    private func onMidPoint(_ message: WKScriptMessage) {
        if onMidPoint { return }
        onMidPoint = true
        guard let body = message.body as? String else { return }
        VponConsole.log("\(#function) [Line \(#line)] args: \(body)")
        videoStateManager.notify(.onVideoMidPoint)
    }
    
    private func onThirdQuartile(_ message: WKScriptMessage) {
        if onThirdQuartile { return }
        onThirdQuartile = true
        guard let body = message.body as? String else { return }
        VponConsole.log("\(#function) [Line \(#line)] args: \(body)")
        videoStateManager.notify(.onVideoThirdQuartile)
    }
    
    private func onComplete(_ message: WKScriptMessage) {
        if onComplete { return }
        onComplete = true
        guard let body = message.body as? String else { return }
        VponConsole.log("\(#function) [Line \(#line)] args: \(body)")
        videoStateManager.notify(.onVideoComplete)
    }
    
    private func onReplay(_ message: WKScriptMessage) {
        if onReplay { return }
        onReplay = true
        guard let body = message.body as? String else { return }
        VponConsole.log("\(#function) [Line \(#line)] args: \(body)")
    }
    
    private func performCallToAction(_ message: WKScriptMessage) {
        guard let body = message.body as? String else { return }
        VponConsole.log("\(#function) [Line \(#line)] args: \(body)")
        adLifeCycleManager?.notify(.onAdClicked)
    }
    
    private func getLastViewablePercentage(_ message: WKScriptMessage) {
        guard let body = message.body as? String else { return }
        VponConsole.log("\(#function) [Line \(#line)] args: \(body)")
        
        // 回傳 mediaView 上的 webView 露出比例
        if let percent = delegate?.lastViewablePercent {
            let percentString = String(percent)
            evaluateJSName(Constants.JSFunc.nativeOnExposureChange, message: percentString)
        }
    }
    
    // Unused in current SDK version
    private func onPlayerStateChanged(_ message: WKScriptMessage) {
        guard let body = message.body as? String else { return }
        VponConsole.log("\(#function) [Line \(#line)] args: \(body)")
        if let body = message.body as? String {
            let data = JsonParseHelper.jsonToDictionary(with: body)
            if let type = data["type"] as? String {
                switch type {
                case "fullscreen":
                    changeToFullscreen()
                case "normal":
                    changeToNormal()
                default:
                    VponConsole.log("onPlayerStateChanged: undefined")
                }
            }
        }
    }
    
    private func changeToFullscreen() {
        if fullScreenVC != nil { return }
        avoidPercentLessThan50 = true
        fullScreenVC = AdPresentationViewController()
        fullScreenVC?.modalPresentationStyle = .overFullScreen
        fullScreenVC?.view.backgroundColor = .clear
     
        webView.removeFromSuperview()
        fullScreenVC?.view.addSubview(webView)
        NSLayoutConstraint.vpc_bounds(with: webView, to: webView.superview!)
        
        let delegate = delegate as? NativeAdWebViewHandlerDelegate
        delegate?.rootViewController?.present(fullScreenVC!, animated: true) { [weak self] in
            self?.avoidPercentLessThan50 = false
            self?.evaluateJSName(Constants.JSFunc.nativeEnterFullscreen, message: "")
            self?.videoStateManager.notify(.onChangeToFullScreen)
        }
    }
    
    private func changeToNormal() {
        guard let fullScreenVC else { return }
        avoidPercentLessThan50 = true
        webView.removeFromSuperview()
        
        let delegate = delegate as? NativeAdWebViewHandlerDelegate
        delegate?.webViewDidChangePlayerStateToNormal(webView)

        fullScreenVC.dismiss(animated: false) { [weak self] in
            self?.avoidPercentLessThan50 = false
            self?.fullScreenVC = nil
            self?.videoStateManager.notify(.onChangeToNormal)
        }
    }
    
    private func logger(_ message: WKScriptMessage) {
        guard let body = message.body as? String else { return }
        VponConsole.log("[CONSOLE] \(body)")
    }
    
    // MARK: - WKUIDelegate
    
    public override func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url {
            UIApplication.shared.open(url)
        }
        return nil
    }
    
    // MARK: - WKNavigationDelegate
    
    public override func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated {
            if let url = navigationAction.request.url {
                UIApplication.shared.open(url)
            }
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
    
    // 網頁加載完成 android: onPageFinished
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        delegate?.webViewDidFinishLoading(webView)
    }
    
    // 網頁內容加載失敗 android: onPageLoadError
    public override func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        // 若 url 導向 app store 則嘗試 openURL
        if let failedURL = (error as NSError).userInfo[NSURLErrorFailingURLErrorKey] as? URL,
           UIApplication.shared.canOpenURL(failedURL) {
            UIApplication.shared.open(failedURL)
        } else {
            delegate?.webView(webView, didFailToLoadWithError: error)
            VponConsole.log("webView didFailProvisionalNavigation with error: \(error.localizedDescription)")
        }
    }
    
    override func removeScriptMessageHandlers() {
        for event in events {
            webView.configuration.userContentController.removeScriptMessageHandler(forName: event)
        }
    }
    
    deinit {
        VponConsole.log("[ARC] NativeAdWebViewHandler deinit")
    }
}

// MARK: - WKScriptMessageHandler(JS -> Native)

extension NativeAdWebViewHandler: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        let funcName = message.name
        guard let jsHandler = NativeAdJavaScriptFunc(rawValue: funcName) else {
            VponConsole.log("NativeAdWebViewHandler is not responding to \(funcName)")
            return
        }
        
        switch jsHandler {
            
        case .onVolumeChange:
            onVolumeChange(message)
            
        case .onComplete:
            onComplete(message)
            
        case .onPause:
            onPause(message)
            
        case .onResume:
            onResume(message)
            
        case .onReplay:
            onReplay(message)
            
        case .onFirstQuartile:
            onFirstQuartile(message)
            
        case .onMidPoint:
            onMidPoint(message)
            
        case .onThirdQuartile:
            onThirdQuartile(message)
            
        case .onStart:
            onStart(message)
            
        case .onBufferStart:
            onBufferStart(message)
            
        case .onBufferFinished:
            onBufferFinish(message)
            
        case .onPlayerStateChanged:
            onPlayerStateChanged(message)
            
        case .performCallToAction:
            performCallToAction(message)
            
        case .getLastViewablePercentage:
            getLastViewablePercentage(message)
            
        case .logger:
            logger(message)
        }
    }
}
