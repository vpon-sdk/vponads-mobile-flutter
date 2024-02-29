//
//  DisplayAdWebViewHandler.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/10/27.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import WebKit

protocol DisplayAdWebViewHandlerDelegate: WebViewHandlerDelegate {
    var placementType: VponPlacementType? { get }
    var isVideoAd: Bool? { get }
    var adViewFrame: CGRect? { get }
    var requestID: String? { get }
    
    /// 是否已經顯示在畫面了
    var hasBeenShown: Bool? { get }
    
    func executeHandler<T: JavaScriptFunc>(_ jsHandler: T, message: WKScriptMessage)
}

final class DisplayAdWebViewHandler: WebViewHandler {

    private var events: [String]
    
    private let device = DeviceInfo.shared
    private let capability = CapabilityInfo.shared
    private let sdk = SDKHelper.shared
    
    override init(webView: VponWebView, adLifeCycleManager: AdLifeCycleManager) {
        self.events = DisplayAdJavaScriptFunc.allCases.map({ $0.rawValue })
        super.init(webView: webView, adLifeCycleManager: adLifeCycleManager)
        
        for event in events {
            webView.configuration.userContentController.add(self, name: event)
        }
        guard let displayWebView = webView as? DisplayAdWebView else { return }
        displayWebView.vponDelegate = self
    }
    
    // MARK: - Native calls JS function (active)
    
    override func sendOnShowToJS() {
        super.sendOnShowToJS()
        sendMaxSize()
    }
    
    func sendHideExposureChagne(completionHandler: ((Any?, Error?) -> Void)?) {
        sendOnHideToJS()
        guard let delegate,
              let onScreenRect = delegate.onScreenCoordinate,
              let adViewRect = delegate.adViewCoordinate else { return }
        
        let message = getExposureMessage(percent: 0, onScreenRect: onScreenRect, adViewRect: adViewRect)
        evaluateJSName(Constants.JSFunc.onExposureChange, message: message, completionHandler: completionHandler)
    }
    
    func sendOnDeviceReady() {
        sendToJavaScript(jsFunc: Constants.JSFunc.onDeviceReady)
    }
    
    private func sendPlacementType() {
        guard let delegate = delegate as? DisplayAdWebViewHandlerDelegate,
              let placementType = delegate.placementType else { return }
        
        let message = placementType == .inline ? "inline": "interstitial"
        sendMessageToJavaScript(message: message, jsFunc: Constants.JSFunc.setPlacementType)
    }
    
    private func sendLastViewablePercentage() {
        guard let delegate,
              let percent = delegate.lastViewablePercent,
              let onScreenRect = delegate.onScreenCoordinate,
              let adViewRect = delegate.adViewCoordinate else { return }
        
        let message = getExposureMessage(percent: percent, onScreenRect: onScreenRect, adViewRect: adViewRect)
        evaluateJSName(Constants.JSFunc.onExposureChange, message: message)
    }
    
    /// 傳送 MRAID 資訊和 reqId 給 JS
    private func sendNativeEnv() {
        // param 1
        var mraidInfo = [String: Any]()
        mraidInfo["sdkVersion"] = sdk.getSDKVersion()
        mraidInfo["addId"] = sdk.getAppID()
        mraidInfo["ifa"] = device.getAdvertisingIdentifier()
        mraidInfo["limitAdTracking"] = device.advertisingTrackingEnabled() ? "1" : "0"
      
        // param 2
        var vpadnInfo = [String: Any]()
        if let delegate = delegate as? DisplayAdWebViewHandlerDelegate,
           let reqId = delegate.requestID {
            vpadnInfo = ["reqId": reqId] // for ad choices
        } else {
            vpadnInfo = ["reqId": ""]
        }
        sendMultipleObjectsToJavaScript(args: mraidInfo, vpadnInfo, jsFunc: Constants.JSFunc.setEnvFromNative)
    }
    
    private func sendAllSupports() {
        var info = [String: Any]()
        info["sms"] = capability.supportSMS() ? "1" : "0"
        info["tel"] = capability.supportTel() ? "1" : "0"
        info["calendar"] = capability.supportCal() ? "1" : "0"
        info["storePicture"] = capability.supportPhotoUsage() ? "1" : "0"
        info["location"] = capability.supportLocation() ? "1" : "0"
        info["vpaid"] = "1"
        info["dispatch"] = "1"
        info["vpsdk"] = "0"
        info["inlineVideo"] = "0"
        sendObjectToJavaScript(args: info, jsFunc: Constants.JSFunc.setSupports)
    }
    
    private func sendVideoAD() {
        let delegate = delegate as? DisplayAdWebViewHandlerDelegate
        sendBooleanToJavaScript(delegate?.isVideoAd ?? false, jsFunc: Constants.JSFunc.isVideoAd)
    }
    
    private func sendGetOrientationProperties() {
        sendToJavaScript(jsFunc: Constants.JSFunc.getOrientationProperties)
    }
    
    private func sendOnAudioVolumeChange(value: Float) {
        sendFloatToJavaScript(value, jsFunc: Constants.JSFunc.onAudioVolumeChange)
    }
    
    // MARK: - JS calls native function
    
    private func logger(_ string: String) {
        VponConsole.log("[CONSOLE] \(string)")
    }
    
    private func omEventOccur(_ event: AdEvent) {
        VponConsole.log("[OMSDK] Event fired by JS: \(event.eventType), Session ID: \(event.sessionID)")
    }
    
    /// 傳送是否支持 Feature 給 JS
    private func sendSupports(_ feature: String) {
        let feature = feature.lowercased()
        var result = false
        switch feature {
        case "sms":
            result = capability.supportSMS()
        case "tel":
            result = capability.supportTel()
        case "calendar":
            result = capability.supportCal()
        case "storepicture":
            result = capability.supportPhotoUsage()
        case "location":
            result = capability.supportLocation()
        default:
            break
        }
        sendBooleanToJavaScript(result, jsFunc: Constants.JSFunc.setSupports)
    }
    
    /// 傳送當前 App 方向給 JS
    private func sendCurrentAppOrientation() {
        guard let controller = delegate as? VponDisplayAd else { return }
        let orientation = device.getInterfaceOrientation()
        var forceOrientation = "none"
        if orientation == .landscapeLeft || orientation == .landscapeRight {
            forceOrientation = "landscape"
        }
        switch orientation {
        case .portrait, .portraitUpsideDown:
            forceOrientation = "portrait"
        case .landscapeLeft, .landscapeRight:
            forceOrientation = "landscape"
        default:
            break
        }
        var e = [String: Any]()
        e["allowOrientationChange"] = controller.initialProperty.orientationProperty.allowOrientationChange
        e["forceOrientation"] = forceOrientation
        sendObjectToJavaScript(args: e, jsFunc: Constants.JSFunc.setCurrentAppOrientation)
    }
    
    /// 傳送當前 Container 位置給 JS
    private func sendCurrentPosition() {
        guard let visibleRect = delegate?.adViewCoordinate else { return }
        var info = [String: Any]()
        info["x"] = visibleRect.origin.x
        info["y"] = visibleRect.origin.y
        info["width"] = visibleRect.size.width
        info["height"] = visibleRect.size.height
        sendObjectToJavaScript(args: info, jsFunc: Constants.JSFunc.setCurrentPosition)
    }
    
    /// 傳送預設 Container 位置給 JS
    private func sendDefaultPosition() {
        guard let position = delegate?.adViewCoordinate else { return }
        var info = [String: Any]()
        info["x"] = position.origin.x
        info["y"] = position.origin.y
        info["width"] = position.size.width
        info["height"] = position.size.height
        sendObjectToJavaScript(args: info, jsFunc: Constants.JSFunc.setGetDefaultPosition)
    }
    
    /// 傳送 Container 大小最大值給 JS
    private func sendMaxSize() {
        guard let delegate = delegate as? DisplayAdWebViewHandlerDelegate,
        let adContainerFrame = delegate.adViewFrame else { return }
        var info = [String: Any]()
        info["width"] = adContainerFrame.size.width
        info["height"] = adContainerFrame.size.height
        sendObjectToJavaScript(args: info, jsFunc: Constants.JSFunc.setMaxSize)
    }
    
    /// 傳送 Device 大小給 JS
    private func sendScreenSize() {
        var info = [String: Any]()
        info["width"] = device.getNativeWidth()
        info["height"] = device.getNativeHeight()
        sendObjectToJavaScript(args: info, jsFunc: Constants.JSFunc.setScreenSize)
    }
    
    /// 傳送 Device 地理位置給 JS
    private func sendLocation() {
        VponAdLocationManager.shared.updateLocation { [weak self] manager, locAge in
            guard let self else { return }
            let location = manager.location
            var info = [String: Any]()
            if let location, location.coordinate.latitude != 0.0, location.coordinate.longitude != 0.0 {
                info["lat"] = location.coordinate.latitude
                info["lon"] = location.coordinate.longitude
                info["type"] = 1
                info["accuracy"] = location.horizontalAccuracy
                info["lastfix"] = locAge
            } else {
                info["lat"] = 0.0
                info["lon"] = 0.0
                info["type"] = 1
                info["accuracy"] = 0
                info["lastfix"] = 0
            }
            self.sendObjectToJavaScript(args: info, jsFunc: Constants.JSFunc.setLocation)
        } failure: { error in
            var info = [String: Any]()
            info["lat"] = 0.0
            info["lon"] = 0.0
            info["type"] = 1
            info["accuracy"] = 0
            info["lastfix"] = 0
            self.sendObjectToJavaScript(args: info, jsFunc: Constants.JSFunc.setLocation)
        }
    }
    
    // MARK: - WKNavigationDelegate
    
    // 網頁加載完成 = Android: onPageFinished
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        VponConsole.log("WebView finish loading resource")
        sendNativeEnv()
        sendAllSupports()
        sendScreenSize()
        sendCurrentAppOrientation()
        sendPlacementType()
        if capability.supportLocation() {
            sendLocation()
        }
        sendVideoAD()
        sendOnDeviceReady()
        delegate?.webViewDidFinishLoading(webView)
        if (delegate as? DisplayAdWebViewHandlerDelegate)?.hasBeenShown ?? false {
            sendOnShowToJS()
        }
    }
    
    // MARK: - Remove
    
    override func removeScriptMessageHandlers() {
        for event in events {
            webView.configuration.userContentController.removeScriptMessageHandler(forName: event)
        }
        (webView as? DisplayAdWebView)?.vponDelegate = nil
    }
}

// MARK: - WKScriptMessageHandler(JS -> Native)

extension DisplayAdWebViewHandler: WKScriptMessageHandler {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        let funcName = message.name
        guard let jsHandler = DisplayAdJavaScriptFunc(rawValue: funcName) else {
            VponConsole.log("DisplayAdWebViewHandler is not responding to \(funcName)")
            return
        }
        
        switch jsHandler {
            
        case .logger:
            if let body = message.body as? String {
                logger(body)
            }
            
        case .omEventOccur:
            let event = AdEvent(message: message)
            omEventOccur(event)
            
        case .doSupports, .sendSupportsToMraid:
            guard let body = message.body as? String else { return }
            sendSupports(body)
            
        case .doGetCurrentAppOrientation, .sendCurrentAppOrientationToMraid:
            sendCurrentAppOrientation()
            
        case .doGetCurrentPosition, .sendCurrentPositionToMraid:
            sendCurrentPosition()
            
        case .doGetDefaultPosition, .sendDefaultPositionToMraid:
            sendDefaultPosition()
            
        case .doGetMaxSize, .sendMaxSizeToMraid:
            sendMaxSize()
            
        case .doGetScreenSize, .sendScreenSizeToMraid:
            sendScreenSize()
            
        case .doGetLocation, .sendLocationToMraid:
            sendLocation()
            
        case .sendNativeEnv:
            sendNativeEnv()
            
        case .sendAllSupportsToMraid:
            sendAllSupports()
            
        case .sendPlacementTypeToMraid:
            sendPlacementType()
            
        case .sendLastViewablePercentage:
            sendLastViewablePercentage()
            
        case .click:
            adLifeCycleManager?.notify(.onAdClicked, data: ["message": message])
            
        default:
            // Can't be handled here -> pass them out
            (delegate as? DisplayAdWebViewHandlerDelegate)?.executeHandler(jsHandler, message: message)
        }
    }
}

// MARK: - DisplayAdWebViewDelegate

extension DisplayAdWebViewHandler: DisplayAdWebViewDelegate {
    func webViewShouldSendExposureChange(_ webView: DisplayAdWebView) {
        guard let delegate = (delegate as? DisplayAdWebViewHandlerDelegate),
              let percent = delegate.lastViewablePercent else { return }
        sendExposureChange(percent: percent)
    }
}
