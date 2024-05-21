//
//  BannerController.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/10/3.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import UIKit
import WebKit

final class BannerController: AdRequestable, TrackingSender, TrackingManagerDelegate , ViewabilityDetectable, OMMeasurable {
    
    private var response: AdResponse?
    
    /// 下次送曝光的 Timer
    private var exposureTimer: Timer?
    
    /// 是否通過的秒數
    private var passDetectDuration: Int = 0
    
    // MARK: - Auto refresh
    
    /// 是否自動刷新
    private var autoRefresh = false
    
    /// 下次抓廣告的 Timer
    private var nextGetAdTimer: Timer?
    
    /// 通知需重新發出 ad request
    var autoRefreshCallback: (() -> Void)?
    
    /// 通知 closeAd 被觸發
    var controllerDidCloseAd: (() -> Void)?
    
    // MARK: - AdLifeCycleObserver properties
    
    var adLifeCycleManager: AdLifeCycleManager?
    
    // MARK: - AdRequestable properties
    
    var requestHelper: AdRequestHelper?
    
    // MARK: - OMMeasurable
    
    var omManager: OMManager?
    
    // MARK: - WebViewHandlerDelegate properties
    
    var placementType: VponPlacementType? = .inline
    var isVideoAd: Bool? = false
    
    // MARK: - VponDisplayAd properties
    
    var webView: DisplayAdWebView
    var webViewHandler: DisplayAdWebViewHandler?
    var initialProperty: InitialProperty = InitialProperty()
    var pendingInitialProperties: [WKScriptMessage] = []
    var rootViewController: UIViewController?
    
    // MARK: - TrackingSender properties
    
    var trackingManager: TrackingManager?
    
    // MARK: - TrackingManagerDelegate
    
    var lastVisiblePercent: Float? {
        get {
            return viewabilityDetector?.lastVisiblePercent
        }
    }
    
    var maxVisiblePercent: Float? {
        get {
            return viewabilityDetector?.maxVisiblePercent
        }
    }
    
    // MARK: - ViewabilityDetectable properties
    
    var viewabilityDetector: ViewabilityDetector?
    
    // MARK: - WebViewHandlerDelegate properties
    
    var lastViewablePercent: Float? {
        get {
            return viewabilityDetector?.exposedPercent()
        }
    }
    
    var adViewCoordinate: CGRect? {
        get {
            guard let viewabilityDetector else { return nil }
            return viewabilityDetector.adViewRect(view: viewabilityDetector.adView)
        }
    }
    
    var onScreenCoordinate: CGRect? {
        get {
            guard let viewabilityDetector else { return nil }
            return viewabilityDetector.onScreenRect(view: viewabilityDetector.adView)
        }
    }
    
    var requestID: String? {
        get {
            return response?.requestID
        }
    }
    
    // MARK: - DisplayAdWebViewHandlerDelegate properties
    
    var adViewFrame: CGRect? {
        get {
            return viewabilityDetector?.adView.frame
        }
    }
    
    var hasBeenShown: Bool? {
        get {
            return viewabilityDetector?.hasBeenShown
        }
    }
    
    // MARK: - Init
    
    init() {
        adLifeCycleManager = AdLifeCycleManager()
        webView = DisplayAdWebView(frame: .zero)
        webViewHandler = DisplayAdWebViewHandler(webView: webView, adLifeCycleManager: adLifeCycleManager!)
        webViewHandler?.delegate = self
    }
    
    func requestAd(licenseKey: String, request: VponAdRequest, autoRefresh: Bool, completion: @escaping (Result<DisplayAdWebView, Error>) -> Void) {
        VponConsole.log("License Key: \(licenseKey)", .info)
        VponConsole.log("[AD LIFECYCLE] RequestAd invoked")
        
        self.autoRefresh = autoRefresh
        requestHelper = AdRequestHelper()
        requestHelper?.requestAd(licenseKey: licenseKey, request: request, completion: { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let response):
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.setup(licenseKey, request, response)
                    self.loadContent(html: response.targetHtml, baseURL: response.locationURL)
                    completion(.success(webView))
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self.adLifeCycleManager?.notify(.onAdFailedToLoad)
                    completion(.failure(error))
                }
            }
        })
    }
    
    private func setup(_ licenseKey: String, _ request: VponAdRequest, _ response: AdResponse) {
        guard let adLifeCycleManager else { return }
        self.response = response
        
        // init viewabilityDetector
        if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            viewabilityDetector = ViewabilityDetector(adView: webView,
                                                      in: window,
                                                      friendlyObstructions: request.friendlyObstructions,
                                                      adLifeCycleManager: adLifeCycleManager)
            viewabilityDetector?.licenseKey = licenseKey
            viewabilityDetector?.bannerFlags = true
            viewabilityDetector?.delegate = self
        }
        // init trackingManager
        trackingManager = TrackingManager(response: response, adLifeCycleManager: adLifeCycleManager)
        trackingManager?.delegate = self
        
        // init OMManager
        let factory = OMSimpleFactory()
        let vponAdVerification = response.vponAdVerification
        
        let videoTypes = [Constants.OM.ADNAdType.displayVideo,
                          Constants.OM.ADNAdType.nativeAdVideo,
                          Constants.OM.ADNAdType.nativeVideo]
        if let type = vponAdVerification?.adType, videoTypes.contains(type) {
            isVideoAd = true
        } else {
            isVideoAd = false
        }
        
        omManager = factory.createOMManager(adLifeCycleManager: adLifeCycleManager, vponAdVerification: vponAdVerification, adView: webView)
        omManager?.setFriendlyObstructions(request.friendlyObstructions)
    }
    
    func startViewabilityDetection() {
        guard let viewabilityDetector else { return }
        viewabilityDetector.startDetection()
        startExposureTimer()
    }
    
    // MARK: - Send exposure to JavaScript
    
    func sendExposureChange() {
        guard let viewabilityDetector else { return }
        let percent = viewabilityDetector.exposedPercent()
        webViewHandler?.sendExposureChange(percent: percent)
    }
    
    private func startExposureTimer() {
        viewabilityDetector?.startExposureTimer()
    }
    
    /// 關閉送曝光防呆
    private func stopExposureTimer() {
        viewabilityDetector?.stopExposureTimer()
    }
    
    // MARK: - Refresh ad
    
    func startNextAdTimer(interval: TimeInterval) {
        if !autoRefresh { return }
        
        if let nextGetAdTimer, nextGetAdTimer.isValid {
            return
        }
        VponConsole.log("Get next ad after \(interval)s")
        
        nextGetAdTimer = Timer(timeInterval: interval, target: self, selector: #selector(nextAd), userInfo: nil, repeats: false)
        RunLoop.main.add(nextGetAdTimer!, forMode: .common)
    }
    
    @objc func nextAd() {
        closeAd()
        autoRefreshCallback?()
    }
    
    func stopNextAd() {
        if let nextGetAdTimer, nextGetAdTimer.isValid {
            nextGetAdTimer.invalidate()
            self.nextGetAdTimer = nil
            VponConsole.log("Stop next ad.")
        }
    }
    
    private func closeAd() {
        controllerDidCloseAd?()
        guard let adLifeCycleManager else { return }
        adLifeCycleManager.notify(.onAdDestroyed)
        webViewHandler?.removeScriptMessageHandlers()
        webView.removeFromSuperview()
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
    }
    
    // MARK: - VponBannerView callback
    
    func bannerViewDidMoveToWindow() {
        addAppLifeCycleObserver()
        startNextAdTimer(interval: TimeInterval(Constants.defaultRefreshAdTime))
        startViewabilityDetection()
        startExposureTimer()
    }
    
    func bannerViewDidMoveToNilWindow() {
        guard let adLifeCycleManager else { return }
        
        adLifeCycleManager.notify(.onAdDestroyed)
      
        webViewHandler?.sendHideExposureChagne { [weak self] _, error in
            guard let self else { return }
            if let error {
                VponConsole.log("Native->JS Failed, reason: \(error), Javascript: \(Constants.JSFunc.onExposureChange)")
            } else {
                VponConsole.log("Native->JS Success, Javascript: \(Constants.JSFunc.onExposureChange)")
            }
            // Stop detection
            self.stopExposureTimer()
            self.viewabilityDetector?.stopViewabilityDetection()
            self.stopNextAd()
            self.removeAppLifeCycleObserver()
        }
    }
    
    // MARK: - Deinit
    
    /// Crucial to avoid memory leak!
    func unregisterAllEvents() {
        stopExposureTimer()
        viewabilityDetector?.stopViewabilityDetection()
        removeAppLifeCycleObserver()
        adLifeCycleManager?.unregisterAllEvents(self)
        webViewHandler?.unregisterAllEvents()
        self.webView.removeFromSuperview()
        trackingManager?.unregisterAdLifeCycleEvents()
        omManager?.unregisterAllEvents()
    }
    
    deinit {
        unregisterAllEvents()
        VponConsole.log("[ARC] BannerController deinit")
    }
}

// MARK: - VponDisplayAd methods

extension BannerController: VponDisplayAd {
    
    func loadContent(html: String?, baseURL: URL?) {
        webView.loadContent(html: html, baseURL: baseURL)
    }
    
    func updateInitialProperty() {
        if let property = pendingInitialProperties.last {
            initialProperty.update(with: property)
            VponConsole.log("Update property")
            pendingInitialProperties.removeAll()
        }
    }
    
    // MRAID open
    func openBrowser(_ scheme: AdScheme) {
        if let url = scheme.url {
            UIApplication.shared.open(url)
            adLifeCycleManager?.notify(.onAdOpened)
        }
    }
    
    // MRAID close
    func close(_ message: WKScriptMessage) {
        closeAd()
    }
    
    // MRAID unload
    func unload(_ message: WKScriptMessage) {
        autoRefresh ? nextAd() : closeAd()
    }
    
    // MRAID expand
    func expand(_ scheme: AdScheme) {
        updateInitialProperty()
        if let url = scheme.url, UIApplication.shared.canOpenURL(url) {
            AdRequestHelper.requestContent(with: url) { [weak self] content in
                guard let self else { return }
                self.webView.loadContent(html: content, baseURL: url)
            }
        }
    }
    
    // MARK: - App life cycle notification
    
    func addAppLifeCycleObserver() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(applicationWillResignActive(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        center.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    func removeAppLifeCycleObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func applicationWillResignActive(_ notification: Notification) {
        webViewHandler?.sendWillResignActiveToJS()
    }
    
    @objc func applicationDidBecomeActive(_ notification: Notification) {
        webViewHandler?.sendDidBecomeActiveToJS()
    }
}

// MARK: - DisplayAdWebViewHandlerDelegate

extension BannerController: DisplayAdWebViewHandlerDelegate {
    
    func webViewDidFinishLoading(_ webView: WKWebView) {
        guard let adLifeCycleManager else { return }
        adLifeCycleManager.notify(.onAdLoaded)
        VponConsole.log("[AD LIFECYCLE] Received invoked", .info)
    }
    
    func webView(_ webView: WKWebView, didFailToLoadWithError error: Error) {
        guard let adLifeCycleManager else { return }
        adLifeCycleManager.notify(.onAdFailedToLoad)
        closeAd()
        startNextAdTimer(interval: TimeInterval(Constants.defaultRestartAdTime))
    }
}

// MARK: - ViewabilityDetectorDelegate

extension BannerController: ViewabilityDetectorDelegate {
    func viewabilityDetector(_ detector: ViewabilityDetector, didExecuteDetectionWithResult result: Bool) {
        guard let adLifeCycleManager else { return }
        
        if result {
            passDetectDuration += 100
            if passDetectDuration >= Constants.ViewableDetection.viewableDuration {
                VponConsole.log("[AD VIEWABILITY] Detection finished")
                detector.didFinishDetection = true
                adLifeCycleManager.notify(.onAdImpression)
            } else {
                VponConsole.log("[AD VIEWABILITY] Detection invoked: \(passDetectDuration)/\(Constants.ViewableDetection.viewableDuration)")
                detector.startDetectionTimer(interval: 0.2)
            }
        } else {
            // 等 0.5s 後，重啟遮蔽偵測
            VponConsole.log("[AD VIEWABILITY] Fail to pass the detection, will restart after 0.5s")
            detector.startDetectionTimer(interval: 0.5)
        }
    }
    
    func viewabilityDetectorShouldSendExposureChange(_ detector: ViewabilityDetector) {
        sendExposureChange()
    }
}

// MARK: - AdLifeCycleObserver

extension BannerController: AdLifeCycleObserver {
    func receive(_ event: AdLifeCycle, data: [String : Any]?) {
        
    }
}
