//
//  WebViewHandler.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/9/25.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import WebKit

protocol WebViewHandlerDelegate: AnyObject {
    var lastViewablePercent: Float? { get }
    /// 目前 adView 之於 window 的座標
    var adViewCoordinate: CGRect? { get }
    
    var onScreenCoordinate: CGRect? { get }
    
    func webViewDidFinishLoading(_ webView: WKWebView)
    func webView(_ webView: WKWebView, didFailToLoadWithError error: Error)
}

class WebViewHandler: NSObject {
    
    var webView: VponWebView
    
    weak var delegate: WebViewHandlerDelegate?
   
    internal var adLifeCycleManager: AdLifeCycleManager?

    var lastExposureMessage = ""
    
    init(webView: VponWebView, adLifeCycleManager: AdLifeCycleManager) {
        self.webView = webView
        self.adLifeCycleManager = adLifeCycleManager
        super.init()
        
        webView.navigationDelegate = self
        webView.uiDelegate = self
       
        // Observe ad life cycle
        adLifeCycleManager.register(self, .onAdShow)
        adLifeCycleManager.register(self, .onAdImpression)
    }
    
    // MARK: - Native calls JS function (active)
    
    func sendOnShowToJS() {
        sendToJavaScript(jsFunc: Constants.JSFunc.onShow)
    }
    
    func sendOnHideToJS() {
        sendToJavaScript(jsFunc: Constants.JSFunc.onHide)
    }
    
    func sendOnImpressionToJS() {
        sendToJavaScript(jsFunc: Constants.JSFunc.onImpression)
    }
    
    func sendWillResignActiveToJS() {
        sendToJavaScript(jsFunc: Constants.JSFunc.willResignActive)
    }
    
    func sendDidBecomeActiveToJS() {
        sendToJavaScript(jsFunc: Constants.JSFunc.didBecomeActive)
    }
    
    // MARK: - Exposure
    
    func sendExposureChange(percent: Float) {
        guard let delegate,
              let onScreenRect = delegate.onScreenCoordinate,
              let adViewRect = delegate.adViewCoordinate else { return }
        let message = getExposureMessage(percent: percent, onScreenRect: onScreenRect, adViewRect: adViewRect)
        
        guard let message, lastExposureMessage != message else { return }
        lastExposureMessage = message
        if percent.isZero { sendOnHideToJS() }
        evaluateJSName(Constants.JSFunc.onExposureChange, message: message)
    }
    
    // MARK: - Make JSON message
    
    /// 把 view 露出比例轉成 JSON 格式 String 準備傳給 JavaScript
    func getExposureMessage(percent: Float, onScreenRect: CGRect, adViewRect: CGRect) -> String? {
        var onScreen = [String: Any]()
        onScreen["x"] = onScreenRect.origin.x
        onScreen["y"] = onScreenRect.origin.y
        onScreen["width"] = onScreenRect.size.width
        onScreen["height"] = onScreenRect.size.height
        
        var ad = [String: Any]()
        ad["x"] = adViewRect.origin.x
        ad["y"] = adViewRect.origin.y
        ad["width"] = adViewRect.size.width
        ad["height"] = adViewRect.size.height
        
        let percentString = String(format: "%.4f", percent)
        let onScreenString =  "'\(JsonParseHelper.dictionaryToJson(with: onScreen, prettyPrinted: false))'"
        let adString = "'\(JsonParseHelper.dictionaryToJson(with: ad, prettyPrinted: false))'"
        return "\(percentString), \(onScreenString), null, \(adString)"
    }
    
    // MARK: - Tool Methods
    
    func sendToJavaScript(jsFunc: String) {
        evaluateJSName(jsFunc, message: nil)
    }
    
    func sendMessageToJavaScript(message: String, jsFunc: String) {
        evaluateJSName(jsFunc, message: "'\(message)'")
    }
    
    func sendObjectToJavaScript(args: [String: Any], jsFunc: String) {
        guard !jsFunc.isEmpty, !args.isEmpty else { return }
        var message = "{}"
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: args, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                message = jsonString
            }
        } catch {
            VponConsole.log("Error serializing JSON when sendObjectToJavaScript: \(error.localizedDescription)")
        }
        evaluateJSName(jsFunc, message: String(format: "'%@'", message))
    }
    
    /// 傳送多個參數給 JS
    /// ```
    /// 傳給 JS 的 string 格式 = "{ "key1": value1, "key2": value2 }, { "keyA", valueA }"
    /// ```
    func sendMultipleObjectsToJavaScript(args: [String: Any]..., jsFunc: String) {
        guard !jsFunc.isEmpty, !args.isEmpty else { return }

        var message = ""
        for (index, arg) in args.enumerated() {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: arg, options: [])
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    message += jsonString
                    if index < args.count - 1 {
                        message += ", "
                    }
                }
            } catch {
                VponConsole.log("Error serializing JSON: \(error.localizedDescription)")
            }
        }

        evaluateJSName(jsFunc, message: message)
    }
    
    func sendBooleanToJavaScript(_ value: Bool, jsFunc: String) {
        let message = "\(value == true ? "1" : "0")"
        evaluateJSName(jsFunc, message: message)
    }
    
    func sendFloatToJavaScript(_ value: Float, jsFunc: String) {
        let message = String(format: "%.4f", value)
        evaluateJSName(jsFunc, message: message)
    }
    
    // MARK: - evaluateJavaScript
    
    func evaluateJSName(_ javascript: String, message: String?) {
        let js = javascript + "(\(message ?? ""))"
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.webView.evaluateJavaScript(js) { result, error in
                if let error {
                    VponConsole.log("Native->JS Failed, reason: \(error), Javascript: \(js)")
                } else {
                    VponConsole.log("Native->JS Success, Javascript: \(js)")
                }
            }
        }
    }
    
    func evaluateJSName(_ javascript: String, message: String?, completionHandler: ((Any?, Error?) -> Void)?) {
        let js = javascript + "(\(message ?? "''"))"
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.webView.evaluateJavaScript(js, completionHandler: completionHandler)
        }
    }
    
    // MARK: - Deinit
    
    func removeScriptMessageHandlers() { /* Subclass implement */ }
    
    func unregisterAllEvents() {
        adLifeCycleManager?.unregisterAllEvents(self)
        removeScriptMessageHandlers()
        webView.uiDelegate = nil
        webView.navigationDelegate = nil
        webView.removeFromSuperview()
    }
    
    deinit {
        unregisterAllEvents()
        VponConsole.log("[ARC] WebViewHandler deinit")
    }
}

// MARK: - AdLifeCycleObserver

extension WebViewHandler: AdLifeCycleObserver {
    func receive(_ event: AdLifeCycle, data: [String : Any]?) {
        switch event {
        case .onAdShow:
            sendOnShowToJS()
        case .onAdImpression:
            sendOnImpressionToJS()
        default:
            return
        }
    }
}

// MARK: - WKNavigationDelegate

extension WebViewHandler: WKNavigationDelegate {
    // 收到網頁重新導向的請求 webViewDidFailed
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {

    }

    // 決定網頁是否允許跳轉
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }

    // 收到網頁 Response 決定是否跳轉
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow)
    }

    // 網頁內容開始加載 = Android: onPageStarted
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        VponConsole.log("WebView start to load resource")
    }

    // 網頁內容加載完成後，返回內容至 webView
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {

    }

    // 網頁內容加載失敗 = Android: onPageLoadError
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        // 若 url 導向 app store 則嘗試 openURL
        if let failedURL = (error as NSError).userInfo[NSURLErrorFailingURLErrorKey] as? URL,
           UIApplication.shared.canOpenURL(failedURL) {
            UIApplication.shared.open(failedURL)
        } else {
            VponConsole.log("webView didFailProvisionalNavigation with error: \(error.localizedDescription)")
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        delegate?.webView(webView, didFailToLoadWithError: error)
    }
    
    // 處理網頁過程發生終止 - 例如 WKWebView 內存占用過大等原因導致系統調用此方法
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        
    }
}

// MARK: - WKUIDelegate

extension WebViewHandler: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        return nil
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "確認", style: .cancel, handler: { action in
            completionHandler()
        }))
        
        if let topVC = UIApplication.topViewController() {
            topVC.present(alertController, animated: true)
        } else {
            completionHandler()
        }
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { action in
            completionHandler(false)
        }))
        alertController.addAction(UIAlertAction(title: "確認", style: .default, handler: { action in
            completionHandler(true)
        }))
        UIApplication.topViewController()?.present(alertController, animated: true)
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alertController = UIAlertController(title: prompt, message: "", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.text = defaultText
        }
        alertController.addAction(UIAlertAction(title: "完成", style: .default, handler: { action in
            completionHandler(alertController.textFields?.first?.text)
        }))
        UIApplication.topViewController()?.present(alertController, animated: true)
    }
}
