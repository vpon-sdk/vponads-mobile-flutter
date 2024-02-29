//
//  VponBannerView.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/10/24.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

// MARK: - VponBannerViewDelegate

@objc public protocol VponBannerViewDelegate: AnyObject {
    /// 通知有廣告可供拉取 call back
    @objc optional func bannerViewDidReceiveAd(_ bannerView: VponBannerView)
    /// 通知拉取廣告失敗 call back
    @objc optional func bannerView(_ bannerView: VponBannerView, didFailToReceiveAdWithError error: Error)
    /// 通知廣告已送出曝光事件
    @objc optional func bannerViewDidRecordImpression(_ bannerView: VponBannerView)
    /// 通知廣告已送出點擊事件
    @objc optional func bannerViewDidRecordClick(_ bannerView: VponBannerView)
}

// MARK: - VponSizeType

internal enum VponSizeType: Int {
    case banner = 0
    case rectangle
    case padBanner
    case leaderboard
    case smart
    case standardPortrait
    case smartPortrait
    case customSize
    case interstitial
    case splash
    case mediumRectangle
    case smartLandscape
    case videoInterstitial
    case native
}

// MARK: - VponAdSize

@objcMembers public final class VponAdSize: NSObject {
    
    let size: CGSize
    let adType: VponSizeType
    
    internal init(size: CGSize, adType: VponSizeType) {
        self.size = size
        self.adType = adType
    }
    
    public init(size: CGSize) {
        self.size = size
        self.adType = .customSize
    }
    
    // MARK: - Standard Sizes
    
    /// Use for 320 * 50
    public class func banner() -> VponAdSize {
        return VponAdSize(size: CGSize(width: 320, height: 50), adType: .banner)
    }
    /// Use for 320 * 100
    public class func largeBanner() -> VponAdSize {
        return VponAdSize(size: CGSize(width: 320, height: 100), adType: .banner)
    }
    /// Use for 320 * 480 (for iPad)
    public class func largeRectangle() -> VponAdSize {
        return VponAdSize(size: CGSize(width: 320, height: 480), adType: .padBanner)
    }
    /// Use for 468 * 60 (for iPad)
    public class func fullBanner() -> VponAdSize {
        return VponAdSize(size: CGSize(width: 468, height: 60), adType: .padBanner)
    }
    /// Use for 728 * 90 (for iPad)
    public class func leaderBoard() -> VponAdSize {
        return VponAdSize(size: CGSize(width: 728, height: 90), adType: .leaderboard)
    }
    /// Use for 300 * 250 (for iPad)
    public class func mediumRectangle() -> VponAdSize {
        return VponAdSize(size: CGSize(width: 300, height: 250), adType: .mediumRectangle)
    }
}

// MARK: - VponBannerView

@objcMembers public final class VponBannerView: UIView, AdLifeCycleObserver {

    public var licenseKey: String?
    public weak var rootViewController: UIViewController?
    public weak var delegate: VponBannerViewDelegate?
    public var autoRefresh: Bool = false
    
    private var request: VponAdRequest?
    private var webView: DisplayAdWebView?
    private var controller: BannerController?
    var adLifeCycleManager: AdLifeCycleManager?
    
    private var materialSize: CGSize = .init()
    private var didSetBoundsObserver = false // KVO
    
    // MARK: - Init
    
    public init(adSize: VponAdSize, origin: CGPoint) {
        let size = adSize.size
        super.init(frame: CGRect(origin: origin, size: size))
        self.clipsToBounds = true
        self.translatesAutoresizingMaskIntoConstraints = false
        
        if adSize.adType == .customSize {
            materialSize = smartMaterialSize(type: adSize.adType, showSize: adSize.size)
        } else {
            materialSize = adSize.size
        }
    }
    
    public convenience init(adSize: VponAdSize) {
        self.init(adSize: adSize, origin: .zero)
    }
    
    // For initializing the view from storyboard or xib
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        materialSize = .init()
    }
    
    // MARK: - Load request
    
    public func load(_ request: VponAdRequest) {
        self.request = request
        
        guard VponAdConfiguration.shared.isInitSDK() else {
            delegate?.bannerView?(self, didFailToReceiveAdWithError: ErrorGenerator.initSDKFailed())
            return
        }
        
        guard let licenseKey, !licenseKey.isEmpty else {
            VponConsole.log("Please specify your license key.", .error)
            delegate?.bannerView?(self, didFailToReceiveAdWithError: ErrorGenerator.noAds())
            return
        }
        
        // Check if licenseKey is restricted
        guard RemoteConfigManager.shared.shouldAllowRequest(licenseKey: licenseKey) else {
            delegate?.bannerView?(self, didFailToReceiveAdWithError: ErrorGenerator.noAds())
            return
        }
        
        // Decide which format to request
        let format = String(format: "%.0fx%.0f_mb", materialSize.width, materialSize.height)
        request.format = format
        
        resetController()
        VponConsole.note()
        controller = BannerController()
        guard let controller else { return }
        self.rootViewController = controller.rootViewController
        self.adLifeCycleManager = controller.adLifeCycleManager
        
        adLifeCycleManager?.register(self, .onAdLoaded)
        adLifeCycleManager?.register(self, .onAdFailedToLoad)
        adLifeCycleManager?.register(self, .onAdImpression)
        adLifeCycleManager?.register(self, .onAdClicked)
        
        controller.requestAd(licenseKey: licenseKey, request: request, autoRefresh: autoRefresh) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let webView):
                self.webView = webView
                self.displayWebView()
                
            case .failure(let error):
                self.delegate?.bannerView?(self, didFailToReceiveAdWithError: error)
            }
        }
        
        // Auto refresh -> send request again
        controller.autoRefreshCallback = { [weak self] in
            guard let self, let request = self.request else { return }
            self.load(request)
        }
        
        controller.controllerDidCloseAd = { [weak self] in
            guard let self else { return }
            self.removeFromSuperview()
        }
    }
    
    private func resetController() {
        if let controller {
            controller.stopNextAd()
        }
    }
    
    // MARK: - Display ad
    
    private func displayWebView() {
        guard let webView else { return }
        addSubview(webView)
        NSLayoutConstraint.vpc_bounds(with: webView, to: self)
    }
    
    // MARK: - UIView func
    
    public override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview == nil {
            // Should removeAllObserver when adView still have superview
            // It will be too late to removeAllObserver in deinit because at that moment the superview is nil, making it impossible to remove the observer attached to it.
            removeAllObserver()
        }
    }
    
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if let superview {
            self.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.vpc_aspectFit(with: self, to: superview, materialSize: materialSize)
            addObserverToSuperviews()
        }
        
        if let webView {
            NSLayoutConstraint.vpc_bounds(with: webView, to: self)
        }
    }
    
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        let visible = self.superview != nil && self.window != nil
        if visible {
            webView?.observer = true
            controller?.bannerViewDidMoveToWindow()
        } else {
            adLifeCycleManager?.unregisterAllEvents(self)
            self.removeFromSuperview()
            if !autoRefresh {
                // Important!! autoRefresh 時 delegate 要留著給下次 request callback 用
                self.delegate = nil
            }
            controller?.bannerViewDidMoveToNilWindow()
            webView?.observer = false
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if let superview {
            // self 有可能還沒被加到 superview 上
            NSLayoutConstraint.vpc_aspectFit(with: self, to: superview, materialSize: materialSize)
        }
        
        if let controller { // controller 有可能未被創建
            controller.sendExposureChange()
        }
    }
    
    // MARK: - KVO Observer
    
    private func addObserverToSuperviews() {
        if !didSetBoundsObserver {
            didSetBoundsObserver = true
            self.superview?.addObserver(self, forKeyPath: "bounds", context: nil)
        }
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let superview, let object,
              let objectView = object as? UIView else { return }
        
        if objectView == superview && keyPath == "bounds" {
            self.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.vpc_aspectFit(with: self, to: superview, materialSize: materialSize)
        }
    }
    
    private func removeAllObserver() {
        if didSetBoundsObserver {
            didSetBoundsObserver = false
            self.superview?.removeObserver(self, forKeyPath: "bounds")
        }
    }
    
    // MARK: - Smart size
    
    private func smartMaterialSize(type: VponSizeType, showSize: CGSize) -> CGSize {
        var width: CGFloat = 0.0, height: CGFloat = 0.0
        if CGSizeEqualToSize(showSize, .zero) {
            width = UIScreen.main.bounds.size.width
            height = width * 0.125
        } else {
            width = showSize.width
            height = showSize.height
        }
        let VponAdSizeBanner = VponAdSize.banner()
        let VponAdSizeLargeRectangle = VponAdSize.largeRectangle()
        let VponAdSizeMediumRectangle = VponAdSize.mediumRectangle()
        let VponAdSizeLeaderboard = VponAdSize.leaderBoard()
        let VponAdSizeFullBanner = VponAdSize.fullBanner()
        let VponAdSizeLargeBanner = VponAdSize.largeBanner()
        
        if width >= VponAdSizeLargeRectangle.size.width && height >= VponAdSizeLargeRectangle.size.height {
            return VponAdSizeLargeRectangle.size
        }
        if width >= VponAdSizeMediumRectangle.size.width && height >= VponAdSizeMediumRectangle.size.height {
            return VponAdSizeMediumRectangle.size;
        }
        if width >= VponAdSizeLeaderboard.size.width && height >= VponAdSizeLeaderboard.size.height {
            return VponAdSizeLeaderboard.size;
        }
        if width >= VponAdSizeFullBanner.size.width && height >= VponAdSizeFullBanner.size.height {
            return VponAdSizeFullBanner.size;
        }
        if width >= VponAdSizeLargeBanner.size.width && height >= VponAdSizeLargeBanner.size.height {
            return VponAdSizeLargeBanner.size;
        }
        if height >= VponAdSizeBanner.size.height {
            return VponAdSizeBanner.size;
        }
        return CGSize(width: 480, height: 32)
    }
    
    // MARK: - AdLifeCycleObserver
    
    func receive(_ event: AdLifeCycle, data: [String : Any]?) {
        switch event {
        case .onAdLoaded:
            delegate?.bannerViewDidReceiveAd?(self)
            
        case .onAdFailedToLoad:
            // When webView load failed
            delegate?.bannerView?(self, didFailToReceiveAdWithError: ErrorGenerator.noAds())
            
        case .onAdShow:
            break
            
        case .onAdImpression:
            delegate?.bannerViewDidRecordImpression?(self)
            
        case .onAdClicked:
            delegate?.bannerViewDidRecordClick?(self)
            
        case .onAdOpened:
            break
            
        case .onAdDestroyed:
            break
        }
    }
    
    // MARK: - Deinit
    
    deinit {
        VponConsole.log("[ARC] VponBannerView deinit")
    }
}
