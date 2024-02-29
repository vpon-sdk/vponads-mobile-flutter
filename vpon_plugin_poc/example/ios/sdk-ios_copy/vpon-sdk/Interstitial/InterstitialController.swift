//
//  InterstitialController.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/8/9.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

final class InterstitialController: AdRequestable, TrackingSender, TrackingManagerDelegate , ViewabilityDetectable, OMMeasurable {

    private var adViewController: InterstitialViewController?
    private var response: AdResponse?
    
    // MARK: - Notify VponInterstitialAd
    
    /// webView 載入完才通知 VponInterstitialAd
    static var requestCompletion: ((Error?) -> Void)?
    
    var willDismiss: (() -> Void)?
    var didDismiss: (() -> Void)?
    var didRecordImpression: (() -> Void)?
    var didRecordClick: (() -> Void)?
    
    // MARK: - AdLifeCycleObserver properties
    
    var adLifeCycleManager: AdLifeCycleManager?
    
    // MARK: - AdRequestable properties
    
    var requestHelper: AdRequestHelper?
    
    // MARK: - OMMeasurable properties
    
    var omManager: OMManager?
    
    // MARK: - WebViewHandlerDelegate properties
    
    var placementType: VponPlacementType? = .interstitial
    var isVideoAd: Bool? = false
    
    // MARK: - VponDisplayAd properties
    
    var webView: DisplayAdWebView
    var webViewHandler: DisplayAdWebViewHandler?
    var initialProperty = InitialProperty()
    var pendingInitialProperties = [WKScriptMessage]()
    var rootViewController: UIViewController? = nil // no need here
    
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
    
    var requestID: String? {
        get {
            return response?.requestID
        }
    }
    
    // MARK: - Init

    init() {
        adLifeCycleManager = AdLifeCycleManager()
        webView = DisplayAdWebView(frame: .zero)
        webViewHandler = DisplayAdWebViewHandler(webView: webView, adLifeCycleManager: adLifeCycleManager!)
        webViewHandler?.delegate = self

        // Change to Never if need webView content to ignore safe area
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic
        
        adLifeCycleManager?.register(self, .onAdClicked)
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
    
    // MARK: - Request ad
    
    static func requestAd(licenseKey: String, request: VponAdRequest, completion: @escaping (_ interstitial: VponInterstitialAd?, _ error: Error?) -> Void) {
        
        let controller = InterstitialController()
        controller.requestHelper = AdRequestHelper()
        VponConsole.note()
        VponConsole.log("License Key: \(licenseKey)", .info)
        VponConsole.log("[AD LIFECYCLE] RequestAd invoked")
        controller.requestHelper?.requestAd(licenseKey: licenseKey, request: request) { result in
            
            switch result {
            
            case .success(let response):
                DispatchQueue.main.async {
                    
                    let interstitialAd = VponInterstitialAd()
                    interstitialAd.controller = controller
                    controller.setup(licenseKey, request, response)
                    controller.loadContent(html: response.targetHtml, baseURL: response.locationURL)
                    
                    requestCompletion = { error in
                        if let error {
                            controller.adLifeCycleManager?.notify(.onAdFailedToLoad)
                            completion(nil, error)
                        } else {
                            completion(interstitialAd, nil)
                        }
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    controller.adLifeCycleManager?.notify(.onAdFailedToLoad)
                    completion(nil, error)
                }
            }
        }
    }
    
    func setup(_ licenseKey: String, _ request: VponAdRequest, _ response: AdResponse) {
        guard let adLifeCycleManager else { return }
        self.response = response
        
        // init adViewController
        adViewController = InterstitialViewController(webView: webView, initialProperty: initialProperty)
        adViewController?.delegate = self
        
        // viewabilityDetector
        if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            viewabilityDetector = ViewabilityDetector(adView: webView,
                                                      in: window,
                                                      friendlyObstructions: request.friendlyObstructions,
                                                      adLifeCycleManager: adLifeCycleManager)
            viewabilityDetector?.licenseKey = licenseKey
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
        if let type = vponAdVerification?.adType,
           videoTypes.contains(type) {
            isVideoAd = true
        } else {
            isVideoAd = false
        }
        
        omManager = factory.createOMManager(adLifeCycleManager: adLifeCycleManager, vponAdVerification: vponAdVerification, adView: webView)
        omManager?.setFriendlyObstructions(request.friendlyObstructions)
    }
    
    // MARK: - 顯示 / 關閉 廣告
    
    func present(fromRootViewController rootViewController: UIViewController) {
        guard let adViewController else { return }
        
        adViewController.rootViewController = rootViewController
        if viewabilityDetector?.hasBeenShown ?? false { return }
     
        adViewController.recordOriginOrientation()
        rootViewController.present(adViewController, animated: true) { [weak self] in
            guard let self else { return }
            if let percent = self.viewabilityDetector?.exposedPercent() {
                self.sendExposureChange(percent: percent)
            }
            adLifeCycleManager?.notify(.onAdShow)
            updateInitialProperty()
            adLifeCycleManager?.notify(.onAdImpression)
            self.didRecordImpression?()
            adViewController.showCloseButton()
            self.webView.observer = true
        }
    }
    
    private func sendExposureChange(percent: Float) {
        webViewHandler?.sendExposureChange(percent: percent)
    }
    
    private func closeAd() {
        webViewHandler?.sendHideExposureChagne { result, error in
            if let error {
                VponConsole.log("Native->JS Failed, reason: \(error), Javascript: \(Constants.JSFunc.onExposureChange)")
            } else {
                VponConsole.log("Native->JS Success, Javascript: \(Constants.JSFunc.onExposureChange)")
            }
        }
        adViewController?.dismissVC()
    }
    
    private func expand(with url: URL, completion: @escaping (_ content: String) -> Void, failure: @escaping () -> Void) {
        AdRequestHelper.requestContent(with: url) { content in
            completion(content)
        }
    }
    
    // MARK: - Deinit
    
    func unregisterAllEvents() {
        removeAppLifeCycleObserver()
        adLifeCycleManager?.unregisterAllEvents(self)
        webViewHandler?.unregisterAllEvents()
        trackingManager?.unregisterAdLifeCycleEvents()
        omManager?.unregisterAllEvents()
    }
    
    deinit {
        webView.configuration.userContentController.removeAllUserScripts()
        webView.uiDelegate = nil
        webView.navigationDelegate = nil
        adLifeCycleManager?.unregisterAllEvents(self)
        VponConsole.log("[ARC] VponInterstitialController deinit")
    }
}

// MARK: - VponDisplayAd

extension InterstitialController: VponDisplayAd {
    
    func loadContent(html: String?, baseURL: URL?) {
        adViewController?.loadContent(html: html, baseURL: baseURL)
    }
    
    // MRAID open
    func openBrowser(_ scheme: AdScheme) {
        if let url = scheme.url {
            UIApplication.shared.open(url)
            adLifeCycleManager?.notify(.onAdOpened)
        }
    }
    
    // MRAID expand
    func expand(_ scheme: AdScheme) {
        updateInitialProperty()
        if let url = scheme.url, UIApplication.shared.canOpenURL(url) {
            self.expand(with: url) { content in
                self.loadContent(html: content, baseURL: url)
            } failure: {}
        }
    }
    
    // MRAID close
    func close(_ message: WKScriptMessage) {
        closeAd()
    }
    
    // MRAID unload
    func unload(_ message: WKScriptMessage) {
        closeAd()
    }
    
    func updateInitialProperty() {
        if let property = pendingInitialProperties.last {
            initialProperty.update(with: property)
            adViewController?.updateInitialProperty(with: initialProperty)
            VponConsole.log("Update property")
            pendingInitialProperties.removeAll()
        }
        
        adViewController?.expandForceOrientation()
        adViewController?.showCloseButton()
    }
}

// MARK: - AdLifeCycleObserver

extension InterstitialController: AdLifeCycleObserver {
    func receive(_ event: AdLifeCycle, data: [String : Any]?) {
        guard event == .onAdClicked else { return }
        didRecordClick?()
    }
}

// MARK: - DisplayAdWebViewHandlerDelegate

extension InterstitialController: DisplayAdWebViewHandlerDelegate {
    
    func webViewDidFinishLoading(_ webView: WKWebView) {
        adLifeCycleManager?.notify(.onAdLoaded)
        VponConsole.log("[AD LIFECYCLE] Received invoked", .info)
        
        InterstitialController.requestCompletion?(nil)
        InterstitialController.requestCompletion = nil
    }
    
    func webView(_ webView: WKWebView, didFailToLoadWithError error: Error) {
        adLifeCycleManager?.notify(.onAdFailedToLoad)
        if let response {
            VponConsole.log("[AD LIFECYCLE] ReceivedFailToLoad invoked, reason: \(response.statusCode) | \(response.status) | \(response.statusDescription)", .info)
        }
        
        InterstitialController.requestCompletion?(ErrorGenerator.noAds())
        InterstitialController.requestCompletion = nil
        adViewController?.showCloseButton()
    }
}

extension InterstitialController: InterstitialViewControllerDelegate {
    
    func viewControllerWillDismiss(_ viewController: InterstitialViewController) {
        self.willDismiss?()
    }
    
    func viewControllerDidDismiss(_ viewController: InterstitialViewController) {
        adLifeCycleManager?.notify(.onAdDestroyed)
        self.didDismiss?()
        unregisterAllEvents()
    }
}
