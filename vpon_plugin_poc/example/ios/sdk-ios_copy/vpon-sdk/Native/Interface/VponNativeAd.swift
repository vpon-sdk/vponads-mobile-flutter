//
//  VponNativeAd.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/10/27.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

@objc public protocol VponNativeAdDelegate: AnyObject {
    /// 通知廣告已送出點擊事件
    @objc optional func nativeAdDidRecordClick(_ nativeAd: VponNativeAd)
    /// 通知廣告已送出曝光事件
    @objc optional func nativeAdDidRecordImpression(_ nativeAd: VponNativeAd)
}

@objcMembers public final class VponNativeAd: NSObject {
    
    public weak var delegate: VponNativeAdDelegate?
    /// 主標題
    public var headline: String?
    /// 點擊鈕文案
    public var callToAction: String?
    /// Branding 圖片
    public var icon: VponNativeAdImage?
    /// 內文
    public var body: String?
    /// Campaign 圖片
    public var coverImage: VponNativeAdImage?
    /// 星數得分
    public var ratingValue: Double = 0.0
    /// 星數範圍
    public var ratingScale: Int = 0
    /// 副標題
    public var socialContext: String?
    /// media 內容
    public var mediaContent: VponMediaContent?
    
    internal var adChoiceInfo: (position: String, link: URL)?
    internal var requestID: String?
    
    // MARK: - Internal properties
    
    private var clickableViews: [UIView] = []
    
    private var videoStateManager: VideoStateManager?
    
    internal var controller: NativeController?
    
    /// For video html to load
    internal var properties: [String: Any] = [:]
    
    /// For native video ad
    internal var webView: NativeAdWebView?
    
    /// To be embed in video tpl html
    private var mediaViewablePercentage: Float?
    
    // MARK: - Video template source
    
    private let fileManager = FileManager.default
    
    /// vpadn/mediaview folder path
    private var documentPath: String {
        let caches = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first ?? ""
        let path = caches.appending("/vpadn/mediaview")
        return path
    }
    
    /// source.html path
    private var filePath: String {
        return documentPath.appending("/source.html")
    }
    
    // MARK: - Setup
    
    /// Public for mediation use
    public func loadMediaView(_ mediaView: VponMediaView?) {
        mediaView?.setupVideoStateManager(videoStateManager)
        if let mediaView {
            mediaViewablePercentage = controller?.getMediaViewExposurePercent(mediaView)
        }
        webView?.contentHTML = getNativeVideoTplHTML() // update html for mediaViewablePercentage
        mediaView?.load()
    }
    
    /// Create mediaContent based on cover_url and set up webview if needed.
    /// - Parameters:
    ///   - url: cover_url from ad url
    ///   - adLifeCycleManager: passed by controller
    ///   - videoStateManager: passed by controller
    internal func prepareMediaContent(with url: URL?, _ adLifeCycleManager: AdLifeCycleManager, _ videoStateManager: VideoStateManager) {
        // cover image url
        VponConsole.log("[VponNativeAd] Prepare content.", .info)
        guard let url else { return }
        
        let pathExtension = url.pathExtension
        let imgExtensions = ["png", "jpg", "jpeg"]
        let gifExtensions = ["gif"]
        let mp4Extensions = ["mp4"]
        
        if imgExtensions.contains(pathExtension) {
            // Native display
            mediaContent = VponMediaContent(hasVideoContent: false, contentURL: url, webView: nil, isMp4Video: false)
            return
        }
        
        self.videoStateManager = videoStateManager
        setupWebView(adLifeCycleManager: adLifeCycleManager, videoStateManager: videoStateManager)
        
        guard let webView else { return }
        
        if mp4Extensions.contains(pathExtension) {
            mediaContent = VponMediaContent(hasVideoContent: true, contentURL: url, webView: webView, isMp4Video: true)
            
        } else if gifExtensions.contains(pathExtension) {
            mediaContent = VponMediaContent(hasVideoContent: true, contentURL: url, webView: webView, isMp4Video: false)
            
        } else {
            mediaContent = VponMediaContent(hasVideoContent: true, contentURL: url, webView: webView, isMp4Video: false)
        }
    }
    
    /// Create webview and webViewHandler for native video ad.
    /// - Parameters:
    ///   - adLifeCycleManager: passed by controller
    ///   - videoStateManager: passed by controller
    private func setupWebView(adLifeCycleManager: AdLifeCycleManager, videoStateManager: VideoStateManager) {
        let html = getNativeVideoTplHTML()
        webView = NativeAdWebView(frame: .init(), contentHTML: html)
        
        guard let webView else { return }
        let webViewHandler = NativeAdWebViewHandler(webView: webView, adLifeCycleManager: adLifeCycleManager, videoStateManager: videoStateManager)
        controller?.webViewHandler = webViewHandler
    }
    
    // MARK: - Register view
    
    /// Public for mediation
    public func registerAdView(_ view: UIView) {
        // 向 SDK 註冊 View 為廣告 Container，且 View 的所有物件均可被點擊觸發事件。
        registerViewForInteration(view)
        
        if let adChoiceInfo, let requestID {
            addAdChoicesView(on: view, info: adChoiceInfo, requestID: requestID)
        }
    }
    
    private func addAdChoicesView(on adView: UIView, info: (position: String, link: URL), requestID: String) {
        for subview in adView.subviews {
            // remove last adChoicesView if exists
            // 若走 mediation 會重創新的 adView 因此不用擔心此處
            if subview is AdChoicesView {
                subview.removeFromSuperview()
            }
        }
        
        let adChoicesView = AdChoicesView(position: info.position, link: info.link, requestID: requestID, frame: .init())
        
        adView.addSubview(adChoicesView)
        adChoicesView.translatesAutoresizingMaskIntoConstraints = false
        
        switch adChoicesView.position {
        case Constants.AdChoicesPosition.upperRight:
            NSLayoutConstraint.activate([
                adChoicesView.topAnchor.constraint(equalTo: adView.topAnchor),
                adChoicesView.rightAnchor.constraint(equalTo: adView.rightAnchor)
            ])
        case Constants.AdChoicesPosition.upperLeft:
            NSLayoutConstraint.activate([
                adChoicesView.topAnchor.constraint(equalTo: adView.topAnchor),
                adChoicesView.leftAnchor.constraint(equalTo: adView.leftAnchor)
            ])
        case Constants.AdChoicesPosition.lowerRight:
            NSLayoutConstraint.activate([
                adChoicesView.bottomAnchor.constraint(equalTo: adView.bottomAnchor),
                adChoicesView.rightAnchor.constraint(equalTo: adView.rightAnchor)
            ])
        case Constants.AdChoicesPosition.lowerLeft:
            NSLayoutConstraint.activate([
                adChoicesView.bottomAnchor.constraint(equalTo: adView.bottomAnchor),
                adChoicesView.leftAnchor.constraint(equalTo: adView.leftAnchor)
            ])
        default:
            // upperRight
            NSLayoutConstraint.activate([
                adChoicesView.topAnchor.constraint(equalTo: adView.topAnchor),
                adChoicesView.rightAnchor.constraint(equalTo: adView.rightAnchor)
            ])
        }
        
        adChoicesView.onTap = { [weak self] in
            self?.reportAdChoices()
        }
    }
    
    private func registerViewForInteration(_ view: UIView) {
        unregisterView()
        addNativeGestureRecognizer(with: [view])
        setupAdContainer(view)
    }
    
    /// 向 SDK 取消註冊的 Container 及所有能被點擊的元件。
    internal func unregisterView() {
        if let adContainer = controller?.adContainer {
            removeNativeGestureRecognizer(with: [adContainer])
        }
        clickableViews = []
        unregisterAdContainer()
    }
    
    private func addNativeGestureRecognizer(with clickableViews: [UIView]) {
        for viewNeedClickable in clickableViews {
            if viewNeedClickable.subviews.count > 1 {
                addNativeGestureRecognizer(with: viewNeedClickable.subviews)
            }
            if !viewNeedClickable.isUserInteractionEnabled {
                viewNeedClickable.isUserInteractionEnabled = true
            }
            let singleFingerTap = NativeGestureRecognizer(target: self, action: #selector(clickHandler(_:)))
            
            viewNeedClickable.addGestureRecognizer(singleFingerTap)
            singleFingerTap.delegate = self
            self.clickableViews.append(viewNeedClickable)
        }
    }
    
    private func removeNativeGestureRecognizer(with views: [UIView]) {
        for (_, clickableView) in views.enumerated() {
            if clickableView.subviews.count > 1 {
                removeNativeGestureRecognizer(with: clickableView.subviews)
            }
            
            guard let gestureRecognizers = clickableView.gestureRecognizers else { continue }
            
            for (_, obj) in gestureRecognizers.enumerated() {
                if obj.isKind(of: NativeGestureRecognizer.self) {
                    clickableView.removeGestureRecognizer(obj)
                }
            }
        }
    }
    
    internal func setupAdContainer(_ view: UIView) {
        guard let controller else { return }
        controller.adContainer = view
        controller.startViewabilityDetection()
        controller.startExposureTimer()
        controller.notifyAdLoaded() // start OM session
    }
    
    internal func unregisterAdContainer() {
        guard let controller else { return }
        controller.stopExposureTimer()
        controller.stopViewabilityDetection()
        controller.adContainer = nil
    }
    
    internal func stopExposureTimer() {
        controller?.stopExposureTimer()
    }
    
    /// Public for mediation
    @objc public func clickHandler(_ sender: Any) {
        // 執行點擊事件
        controller?.clickHandler(sender)
    }
    
    // MARK: - Trigger mediaContent callback
    
    internal func notifyWebViewDidLoadFinished(_ webView: WKWebView) {
        mediaContent?.webViewDidLoadFinished?(webView)
    }
    
    internal func notifyWebViewDidChangeToNormal(_ webView: WKWebView) {
        mediaContent?.webViewDidChangeToNormal?(webView)
    }
    
    // MARK: - Report Ad Choices
    
    /// Public for mediation
    public func reportAdChoices() {
        guard let requestID else { return }
        controller?.reportAdChoices(reqID: requestID)
    }
    
    // MARK: - VponNativeAdDelegate notification
    
    internal func notifyDidRecordClick() {
        delegate?.nativeAdDidRecordClick?(self)
    }
    
    internal func notifyDidRecordImpression() {
        delegate?.nativeAdDidRecordImpression?(self)
    }
    
    // MARK: - Fetch video template html
    
    /// 讀取 native video template "vpon-nativead-video-tpl-v2.html" 並替換 macro 產出新的 html
    /// - Returns: html string with macros replaced
    private func getNativeVideoTplHTML() -> String {
        var string = getSourceFromDirectory()
        properties[Constants.MediaSoucre.isiOS] = true
        properties[Constants.MediaSoucre.mediaViewablePercentage] = mediaViewablePercentage ?? 0
        var json = JsonParseHelper.dictionaryToJson(with: properties, prettyPrinted: false)
        json = json.replacingOccurrences(of: "\\/", with: "/")
        string = string.replacingOccurrences(of: Constants.MediaSoucre.replaceMacro, with: json)
        VponConsole.log(string)
        return string
    }
    
    /// 從 local 讀取 native template
    private func getSourceFromDirectory() -> String {
        if !fileManager.fileExists(atPath: filePath) {
            let bundle = Bundle(for: type(of: self))
            guard let filePath = bundle.path(forResource: Constants.MediaSoucre.videoTplFileName, ofType: "html") else {
                return ""
            }
            
            do {
                let resource = try String(contentsOfFile: filePath, encoding: .utf8)
                return resource
            } catch {
                VponConsole.log("[VponNativeAd] Video Template not found.", .error)
                return ""
            }
        } else {
            let resource = try? String(contentsOfFile: filePath, encoding: .utf8)
            return resource ?? ""
        }
    }
    
    /// 如果上次更新超過一天（86400 秒）則更新 native video tpl
    func updateMediaSourceIfNeeded() {
        let keys = UserDefaults.standard.dictionaryRepresentation().keys
        if !keys.contains(Constants.MediaSoucre.nativeVideoTpl) {
            updateSource()
            return
        }
        let last = UserDefaults.standard.integer(forKey: Constants.MediaSoucre.nativeVideoTpl)
        let now = Int(Date().timeIntervalSince1970)
        if (now - last) > Constants.MediaSoucre.interval {
            updateSource()
            return
        }
    }
    
    /// 抓取 remote 最新的 native video tpl 並存到 local
    private func updateSource() {
        if let url = URL(string: Constants.MediaSoucre.nativeVideoTpl) {
            let reuqest = URLRequest(url: url)
            URLSession.shared.dataTask(with: reuqest) { [weak self] data, response, error in
                guard let self = self else { return }
                
                if let data,
                   let source = String(data: data, encoding: .utf8) {
                    
                    self.saveSourceToDirectory(content: source)
                }
                
            }.resume()
        }
    }
    
    private func saveSourceToDirectory(content: String) {
        if !fileManager.fileExists(atPath: documentPath) {
            try? fileManager.createDirectory(atPath: documentPath, withIntermediateDirectories: true, attributes: nil)
        }
        
        do {
            try content.write(toFile: filePath, atomically: true, encoding: .utf8)
            let now = Date().timeIntervalSince1970
            UserDefaults.standard.set(now, forKey: Constants.UserDefaults.mediaSource)
        } catch {
            
        }
    }
    
    // MARK: - Deinit
    
    deinit {
        controller?.unregisterAllEvents()
        VponConsole.log("[ARC] VponNativeAd deinit")
    }
}

// MARK: - UIGestureRecognizerDelegate

extension VponNativeAd: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let touchPoint = touch.location(in: touch.view)
        if let touchedView = touch.view?.hitTest(touchPoint, with: nil) {
            if touchedView.isKind(of: AdChoicesView.self) {
                // 如果點擊的是 adChoiceView，則返回 false -> 只觸發 ad choice click 事件，不要觸發 click tracking
                return false
            }
        }
        return true
    }
}
