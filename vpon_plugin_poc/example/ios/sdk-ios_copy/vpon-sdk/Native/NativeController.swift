//
//  NativeController.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/10/27.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

final class NativeController: AdRequestable, TrackingSender, TrackingManagerDelegate, ViewabilityDetectable, OMMeasurable {
    
    // MARK: - WebViewHandlerDelegate properties
    
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
    
    // MARK: - NativeAdWebViewHandlerDelegate properties
    
    var webViewHandler: NativeAdWebViewHandler? {
        didSet {
            webViewHandler?.delegate = self
        }
    }
    
    /// Native ad webView（而非 adContainer）的露出比例
    var lastViewablePercent: Float? {
        get {
            guard let webView = nativeAd?.webView else { return nil }
            return viewabilityDetector?.exposedPercent(of: webView)
        }
    }
    
    /// 目前沒用到，如果使用 v5.5 舊介面會是 nil
    weak var rootViewController: UIViewController?
        
    // MARK: - AdLifeCycleObserver properties
    
    var adLifeCycleManager: AdLifeCycleManager?
    
    // MARK: - AdRequestable properties
    
    var requestHelper: AdRequestHelper?
    
    // MARK: - OMMeasurable
    
    var omManager: OMManager?
    
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
    
    // MARK: - Other properties
    
    /// 廣告 container（Publisher 的 VponNativeAdView）
    weak var adContainer: UIView? {
        didSet {
            guard let adContainer, let response else { return }
            setViewabilityDetector()
            setupOMManager(response, adContainer)
        }
    }
    
    private var request: VponAdRequest?
    private var response: AdResponse?
    private var thirdTrackingURLs = [String]()
    private var link: URL?
    private var coverURL: URL?
    
    weak var nativeAd: VponNativeAd?
    
    var videoStateManager: VideoStateManager?
    
    // 紀錄遮蔽偵測的值
    private var lastOnScreenRect = [String: Double]()
    private var lastAdViewRect = [String: Double]()
    
    // MARK: - Request ad
    
    func requestAd(licenseKey: String, request: VponAdRequest, completion: @escaping (Result<VponNativeAd, Error>) -> Void) {
        VponConsole.log("License Key: \(licenseKey)", .info)
        VponConsole.log("[AD LIFECYCLE] RequestAd invoked")
        
        self.request = request
        request.format = "na"
        requestHelper = AdRequestHelper()
        requestHelper?.requestAd(licenseKey: licenseKey, request: request, completion: { result in
            
            switch result {
            case .success(let response):
                
                self.setup(licenseKey, response)
                self.response = response
                
                if let adURL = response.locationURL {
                    
                    self.generateNativeAd(from: adURL, licenseKey) { [weak self] nativeAd in
                        guard let self, let nativeAd, let videoStateManager = self.videoStateManager else {
                            self?.adLifeCycleManager?.notify(.onAdFailedToLoad)
                            completion(.failure(ErrorGenerator.noAds()))
                            return
                        }
                        self.nativeAd = nativeAd
                        nativeAd.requestID = response.requestID
                        nativeAd.prepareMediaContent(with: self.coverURL, adLifeCycleManager!, videoStateManager)
                        
                        completion(.success(nativeAd))
                    }
                    
                } else {
                    // 上一層已檢查過 ad url，基本上不太可能進來這裡
                    self.adLifeCycleManager?.notify(.onAdFailedToLoad)
                    completion(.failure(ErrorGenerator.noAds()))
                }
                
            case .failure(let error):
                self.adLifeCycleManager?.notify(.onAdFailedToLoad)
                completion(.failure(error))
            }
        })
    }
    
    // MARK: - Handle click
    
    /// 執行點擊事件
    @objc func clickHandler(_ sender: Any?) {
        notifyAdClicked()
    }
    
    private func combineOutapp() -> [String: Any] {
        return [
            "btntrackingurls": [],
            "action": "out_url",
            "launch_type": "outapp",
            "data": [
                "u": link == nil ? "" : link!.absoluteString
            ]
        ]
    }
    
    /// 透過 info 來分辨執行哪一個 feature
    /// - Parameter info: 來自 combineOutapp() 的資料
    private func filterFeature(info: [String: Any]) {
        guard let trackings = info["btntrackingurls"] as? [String] else { return }
        let duration = info["duration"] as? Double ?? 0
        let current = info["current"] as? Double ?? 0
        trackingManager?.sendMultipleURLRequests(with: trackings, duration: duration, current: current)
        
        guard let data = info["data"] as? [String: Any] else { return }
        if let action = info["action"] as? String {
            switch action {
            case "send_sms":
                let sendMsg = AdSendMsg(data: data)
                sendSms(sendMsg)
            case "open_store":
                let store = AdStore(data: data)
                openStore(store)
            case "place_call":
                let scheme = AdScheme(data: data, urlKey: "tel")
                placeCall(scheme)
            case "app_u":
                let scheme = AdScheme(data: data, urlKey: "app_u")
                openNativeApp(scheme)
            case "cre_cal_event":
                break
            default:
                break
            }
        }
        
        // 打開 URL
        if data.keys.contains("u") {
            let scheme = AdScheme(data: data, urlKey: "u")
            openBrowser(scheme)
        }
    }
    
    /// 發送簡訊
    /// - Parameter sendMsg: 訊息 參數模型
    func sendSms(_ sendMsg: AdSendMsg) {
        guard sendMsg.canSend(), let vc = UIApplication.topViewController() else { return }
        AdFeatureMockViewController.present(with: sendMsg, rootViewCtrl: vc)
    }
    
    /// 開啟 AppStore
    /// - Parameter store: AppStore 參數模型
    func openStore(_ store: AdStore) {
        guard store.canOpen(), let vc = UIApplication.topViewController() else { return }
        AdFeatureMockViewController.present(with: store, rootViewCtrl: vc)
    }
    
    /// 撥打電話
    /// - Parameter scheme: url scheme 參數模型
    func placeCall(_ scheme: AdScheme) {
        openBrowser(scheme)
    }
    
    /// 外開其他 Application
    /// - Parameter scheme: url scheme 參數模型
    func openNativeApp(_ scheme: AdScheme) {
        openBrowser(scheme)
    }
    
    /// 外開 Safari
    /// - Parameter scheme: url scheme 參數模型
    func openBrowser(_ scheme: AdScheme) {
        if let url = scheme.url {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Handle Ad Choices click
    
    func reportAdChoices(reqID: String) {
        var urlComponents = URLComponents(string: Constants.Domain.adChoices)!
        urlComponents.queryItems = [
            URLQueryItem(name: "req_id", value: reqID),
            URLQueryItem(name: "reason", value: "99")
        ]
        
        guard let url = urlComponents.url else {
            VponConsole.log("[Ad Choices] Failed to generate reporting url!")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error {
                VponConsole.log("[Ad Choices] Failed to send report to \(url) with error: \(error.localizedDescription)")
            } else if let httpResponse = response as? HTTPURLResponse {
                VponConsole.log("[Ad Choices] Send report successfully. Status code: \(httpResponse.statusCode)")
            }
        }.resume()
    }
    
    // MARK: - Viewability detection
    
    func setViewabilityDetector() {
        guard let adContainer else { return }
        if let window = UIWindow.keyWindow() {
            viewabilityDetector = ViewabilityDetector(adView: adContainer,
                                                      in: window,
                                                      friendlyObstructions: request?.friendlyObstructions,
                                                      adLifeCycleManager: adLifeCycleManager!)
            viewabilityDetector?.delegate = self
            viewabilityDetector?.nativeAdWebView = nativeAd?.webView
            trackingManager?.delegate = self
        }
    }
    
    func startExposureTimer() {
        viewabilityDetector?.startExposureTimer()
    }
    
    /// 關閉送曝光防呆
    func stopExposureTimer() {
        viewabilityDetector?.stopExposureTimer()
    }
    
    func startViewabilityDetection() {
        guard let viewabilityDetector else { return }
        viewabilityDetector.startDetection()
    }
    
    func stopViewabilityDetection() {
        guard let viewabilityDetector else { return }
        viewabilityDetector.stopViewabilityDetection()
    }
    
    func getMediaViewExposurePercent(_ mediaView: UIView) -> Float? {
        if let window = UIWindow.keyWindow(), let adLifeCycleManager {
            let tmpDetector = ViewabilityDetector(adView: mediaView,
                                                  in: window,
                                                  friendlyObstructions: request?.friendlyObstructions,
                                                  adLifeCycleManager: adLifeCycleManager)
            return tmpDetector.exposedPercent() // 用完就會 release
        } else {
            return 0
        }
    }
    
    // MARK: - Setup
    
    private func setup(_ licenseKey: String, _ response: AdResponse) {
        unregisterAllEvents()
        
        adLifeCycleManager = AdLifeCycleManager()
        videoStateManager = VideoStateManager()
        adLifeCycleManager?.register(self, .onAdImpression)
        adLifeCycleManager?.register(self, .onAdClicked)
        adLifeCycleManager?.register(self, .onAdDestroyed)
        
        guard let adLifeCycleManager else { return }
        
        // init trackingManager
        trackingManager = TrackingManager(response: response, adLifeCycleManager: adLifeCycleManager)
    }
    
    private func setupOMManager(_ response: AdResponse, _ adContainer: UIView) {
        guard let adLifeCycleManager else { return }
        
        // init OMManager
        let factory = OMSimpleFactory()
        guard let vponAdVerification = response.vponAdVerification else { return }
        
        let type = vponAdVerification.adType
        
        // t = "n"
        if type == Constants.OM.ADNAdType.native {
            // 額外判斷 cover_url 若是 .mp4 結尾則把 t 改成 "nv"
            if let adURL = response.locationURL,
                   isVideoCoverURL(adURL: adURL) {
                let verification = AdVerification(adType: Constants.OM.ADNAdType.nativeAdVideo, verifications: vponAdVerification.verifications)
                omManager = factory.createOMManager(adLifeCycleManager: adLifeCycleManager,
                                                    vponAdVerification: verification,
                                                    adView: adContainer,
                                                    videoStateManager: videoStateManager)
            } else {
                // 維持 t = "n"
                omManager = factory.createOMManager(adLifeCycleManager: adLifeCycleManager,
                                                    vponAdVerification: vponAdVerification,
                                                    adView: adContainer)
            }
        } else {
            // t = "nv", t = "v"
            omManager = factory.createOMManager(adLifeCycleManager: adLifeCycleManager,
                                                vponAdVerification: vponAdVerification,
                                                adView: adContainer,
                                                videoStateManager: videoStateManager)
        }
        if let obstructions = request?.friendlyObstructions {
            omManager?.setFriendlyObstructions(obstructions)
        }
    }
    
    // MARK: - Tool functions
    
    /// 檢查 cover_url 是否為 mp4 結尾
    private func isVideoCoverURL(adURL url: URL) -> Bool {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = urlComponents.queryItems  else { return false }
        let predicate = NSPredicate(format: "name=%@", "cover_url")
        let items = queryItems.filter { predicate.evaluate(with: $0)}
        if !items.isEmpty, let queryItem = items.first {
            if let value = queryItem.value {
                let url = URL(string: FormatVerifier.formatURL(value))
                let pathExtension = url?.pathExtension
                return pathExtension == "mp4"
            }
        }
        return false
    }
    
    /// Create VponNativeAd based on ad url.
    private func generateNativeAd(from url: URL, _ licenseKey: String,completion: @escaping (VponNativeAd?) -> Void) {
        let data = URL.queryParameters(from: url)
        guard verifyNativeData(data: data) else {
            completion(nil)
            return
        }
        
        let native = VponNativeAd()
        native.controller = self
        
        // Ad Choices config
        let info = RemoteConfigManager.shared.getAdChoiceInfo(of: licenseKey)
        if let url = URL(string: info.urlString) {
            native.adChoiceInfo = (info.position, url)
        }
        
        VponConsole.log("[NativeController] nativeAd data: \(data as AnyObject)")
        
        var tempData = data
        let keysToRemove = [
            Constants.NativeAdKey.title,
            Constants.NativeAdKey.body,
            Constants.NativeAdKey.socialContext,
            Constants.NativeAdKey.r_v,
            Constants.NativeAdKey.r_s,
            Constants.NativeAdKey.coverWidth,
            Constants.NativeAdKey.coverHeight,
            Constants.NativeAdKey.iconWidth,
            Constants.NativeAdKey.iconHeight,
            Constants.NativeAdKey.iconURL,
            Constants.NativeAdKey.adLabel,
            Constants.ADNResponse.om
        ]
        for key in keysToRemove {
            tempData.removeValue(forKey: key)
        }
        native.properties = tempData
      
        native.headline = data[Constants.NativeAdKey.title]
        native.body = data[Constants.NativeAdKey.body]
        native.socialContext = data[Constants.NativeAdKey.socialContext]
        native.callToAction = data[Constants.NativeAdKey.actionName]
        native.ratingValue = Double(data[Constants.NativeAdKey.r_v] ?? "0") ?? 0
        native.ratingScale = Int(data[Constants.NativeAdKey.r_s] ?? "0") ?? 0
        
        let c_w = Int(data[Constants.NativeAdKey.coverWidth] ?? "") ?? Int(Constants.NativeAdKey.defaultCoverImageWidth)
        let c_h = Int(data[Constants.NativeAdKey.coverHeight] ?? "") ?? Int(Constants.NativeAdKey.defaultCoverImageHeight)
        if let c_u = URL(string: data[Constants.NativeAdKey.coverURL] ?? "") {
            native.coverImage = VponNativeAdImage(url: c_u, width: c_w, height: c_h)
            self.coverURL = c_u
        }
        
        let i_w = Int(data[Constants.NativeAdKey.iconWidth] ?? "") ?? Int(Constants.NativeAdKey.defaultIconImageWidth)
        let i_h = Int(data[Constants.NativeAdKey.iconHeight] ?? "") ?? Int(Constants.NativeAdKey.defaultIconImageHeight)
        
        if let i_u = URL(string: data[Constants.NativeAdKey.iconURL] ?? "") {
            native.icon = VponNativeAdImage(url: i_u, width: i_w, height: i_h)
            native.icon?.loadImage(completion: { success in
                if success {
                    completion(native)
                } else {
                    completion(nil)
                }
            })
        } else  {
            VponConsole.log("[NativeController] Failed to generate native ad: Can't read icon_url.")
            completion(nil)
        }
    }
    
    /// 驗證 Native 資料正確性
    private func verifyNativeData(data: [String: String]) -> Bool {
        let title = data[Constants.NativeAdKey.title] ?? ""
        let actionName = data[Constants.NativeAdKey.actionName] ?? ""
        guard title.count > 0 && actionName.count > 0 else { return false }
        
        let jsonString = data[Constants.NativeAdKey.thirdTrackingsArray] ?? ""
        let oneData = JsonParseHelper.jsonToDictionary(with: jsonString)
        if let urls = oneData["urls"] as? [String] {
            self.thirdTrackingURLs = urls
        }
        let match = "^tr\\d"
        let predicate = NSPredicate(format: "SELF matches %@", match)
        let results = data.keys.filter{ predicate.evaluate(with: $0) }
        
        for key in results {
            if let url = data[key] {
                self.thirdTrackingURLs.append(url)
            }
        }
        
        let track = FormatVerifier.args(data, regrexStringByKey: Constants.NativeAdKey.thirdTracking)
        if track.count > 0 && !thirdTrackingURLs.contains(track){
            thirdTrackingURLs.append(track)
        }
        self.link = FormatVerifier.args(data, regrexURLByKey: Constants.NativeAdKey.link)
        
        return true
    }
    
    // MARK: - Ad life cycle notification
    
    func notifyAdLoaded() {
        adLifeCycleManager?.notify(.onAdLoaded)
        VponConsole.log("[AD LIFECYCLE] Received invoked", .info)
    }
    
    func notifyAdClicked() {
        adLifeCycleManager?.notify(.onAdClicked)
    }
    
    // MARK: - Deinit
    
    /// Crucial to avoid memory leak!
    func unregisterAllEvents() {
        nativeAd?.unregisterView()
        webViewHandler?.unregisterAllEvents()
        trackingManager?.unregisterAdLifeCycleEvents()
        viewabilityDetector?.stopViewabilityDetection()
        adLifeCycleManager?.unregisterAllEvents(self)
        omManager?.unregisterAllEvents()
    }
    
    deinit {
        unregisterAllEvents()
        VponConsole.log("[ARC] NativeController deinit")
    }
}

// MARK: - NativeAdWebViewHandlerDelegate

extension NativeController: NativeAdWebViewHandlerDelegate {
    func webViewDidFinishLoading(_ webView: WKWebView) {
        nativeAd?.notifyWebViewDidLoadFinished(webView)
    }
    
    func webView(_ webView: WKWebView, didFailToLoadWithError error: Error) {
        adLifeCycleManager?.notify(.onAdFailedToLoad)
        if let response {
            VponConsole.log("[AD LIFECYCLE] ReceivedFailToLoad invoked, reason: \(response.statusCode) | \(response.status) | \(response.statusDescription)", .info)
        }
    }
    
    func webViewDidChangePlayerStateToNormal(_ webView: WKWebView) {
        nativeAd?.notifyWebViewDidChangeToNormal(webView)
    }
}

// MARK: - AdLifeCycleObserver

extension NativeController: AdLifeCycleObserver {
    func receive(_ event: AdLifeCycle, data: [String : Any]?) {
        switch event {
            
        case .onAdImpression:
            nativeAd?.notifyDidRecordImpression()
            
        case .onAdClicked:
            filterFeature(info: combineOutapp())
            nativeAd?.notifyDidRecordClick()
            
        default:
            break
        }
    }
}

// MARK: - ViewabilityDetectorDelegate

extension NativeController: ViewabilityDetectorDelegate {
    func viewabilityDetector(_ detector: ViewabilityDetector, didExecuteDetectionWithResult result: Bool) {
        guard let adLifeCycleManager else { return }
        if result {
            VponConsole.log("[AD VIEWABILITY] Detection finished")
            adLifeCycleManager.notify(.onAdImpression)
        } else {
            VponConsole.log("[AD VIEWABILITY] Fail to pass the detection, will restart after 0.5s")
            detector.startDetectionTimer(interval: 0.5)
        }
    }
    
    func viewabilityDetectorShouldSendExposureChange(_ detector: ViewabilityDetector) {
        if detector.adView.window == nil {
            // AdView 已離開 window -> 視為 Ad destroyed
            adLifeCycleManager?.notify(.onAdDestroyed)
            unregisterAllEvents()
            return
        }
        
        guard let webViewHandler else { return }
        
        let percent = detector.exposedPercent()
        if webViewHandler.avoidPercentLessThan50 && percent < 50 { return }
        
        let exposure = detector.getExposureWithPercent(percent)
        
        if lastOnScreenRect == exposure.onScreenRect &&
            lastAdViewRect == exposure.adViewRect {
            return
        } else {
            lastOnScreenRect = exposure.onScreenRect
            lastAdViewRect = exposure.adViewRect
            webViewHandler.sendNativeExposureChange(exposure.message)
        }
    }
}
