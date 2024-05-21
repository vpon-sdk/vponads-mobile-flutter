//
//  VPBanner.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/4/21.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

@available(*, deprecated, message: "Use VponBannerViewDelegate instead.")
@objc public protocol VpadnBannerDelegate: AnyObject {

    /// 通知有廣告可供拉取 call back
    @objc optional func onVpadnAdLoaded(_ banner: VpadnBanner)

    /// 通知拉取廣告失敗 call back
    @objc optional func onVpadnAd(_ banner: VpadnBanner, failedToLoad error: Error)
    
    /// 通知廣告已送出點擊事件
    @objc optional func onVpadnAdClicked(_ banner: VpadnBanner)

    @available(*, deprecated, message: "No replacement.")
    @objc optional func onVpadnAdWillLeaveApplication(_ banner: VpadnBanner)
    
    @available(*, deprecated, message: "No replacement.")
    @objc optional func onVpadnAdWillOpen(_ banner: VpadnBanner)
    
    @available(*, deprecated, message: "No replacement.")
    @objc optional func onVpadnAdClosed(_ banner: VpadnBanner)

    @available(*, deprecated, message: "No replacement.")
    @objc optional func onVpadnAdRefreshed(_ banner: VpadnBanner)
}

// MARK: - VpadnAdSize

@available(*, deprecated, message: "Use VponAdSize instead.")
@objcMembers public class VpadnAdSize: NSObject {
    let size: CGSize
    let showSize: CGSize
    let adType: VponSizeType

    internal init(size: CGSize, showSize: CGSize, adType: Int) {
        self.size = size
        self.showSize = showSize
        self.adType = VponSizeType(rawValue: adType) ?? .banner
    }

    // Custom size
    public init(CGSize size: CGSize) {
        self.size = CGSize(width: 320, height: 50)
        self.showSize = size
        self.adType = VponSizeType.customSize
    }

    // MARK: - Standard Sizes
    
    /// Use for 320 * 50
    public class func banner() -> VpadnAdSize {
        return VpadnAdSize(size: CGSize(width: 320, height: 50), showSize: CGSize(width: 320, height: 50), adType: VponSizeType.banner.rawValue)
    }
    /// Use for 320 * 100
    public class func largeBanner() -> VpadnAdSize {
        return VpadnAdSize(size: CGSize(width: 320, height: 100), showSize: CGSize(width: 320, height: 100), adType: VponSizeType.banner.rawValue)
    }
    /// Use for 320 * 480 (for iPad)
    public class func largeRectangle() -> VpadnAdSize {
        return VpadnAdSize(size: CGSize(width: 320, height: 480), showSize: CGSize(width: 320, height: 480), adType: VponSizeType.padBanner.rawValue)
    }
    /// Use for 468 * 60 (for iPad)
    public class func fullBanner() -> VpadnAdSize {
        return VpadnAdSize(size: CGSize(width: 468, height: 60), showSize: CGSize(width: 468, height: 60), adType: VponSizeType.padBanner.rawValue)
    }
    /// Use for 728 * 90 (for iPad)
    public class func leaderBoard() -> VpadnAdSize {
        return VpadnAdSize(size: CGSize(width: 728, height: 90), showSize: CGSize(width: 728, height: 90), adType: VponSizeType.leaderboard.rawValue)
    }
    /// Use for 300 * 250 (for iPad)
    public class func mediumRectangle() -> VpadnAdSize {
        return VpadnAdSize(size: CGSize(width: 300, height: 250), showSize: CGSize(width: 300, height: 250), adType: VponSizeType.mediumRectangle.rawValue)
    }
}

// MARK: - VpadnBanner

@available(*, deprecated, message: "Use VponBannerView instead.")
@objcMembers public class VpadnBanner: NSObject {
    
    // MARK: - Properties
    
    @available(*, deprecated, message: "No replacement.")
    public var strBannerId: String? // 目前已沒在用
    
    /// 根控制項
    public weak var rootViewController: UIViewController? {
        didSet {
            if let bannerView, let rootViewController {
                bannerView.rootViewController = rootViewController
            }
        }
    }
    /// Delegate token
    public weak var delegate: VpadnBannerDelegate?
    
    @available(*, deprecated, message: "No replacement.")
    public var platform: String? // 目前已沒在用
    
    @available(*, deprecated, message: "Use VponAdRequestConfiguration.shared.testDeviceIdentifiers instead.")
    public var testIdentifiers: [String] = []
    
    // MARK: - v5.6 integration
    
    private var bannerView: VponBannerView?
    
    // MARK: - Initializer
    
    /// 初始化方法
    /// - Parameter licenseKey: 版位 ID (BannerID, PlacementID)
    /// - Parameter adSize: 廣告 Size
    public init(licenseKey: String, adSize: VpadnAdSize) {
        let newSize = VponAdSize(size: adSize.size, adType: adSize.adType)
        bannerView = VponBannerView(adSize: newSize)
        bannerView?.licenseKey = licenseKey

        super.init()
        bannerView?.delegate = self
    }
    
    // MARK: - Convenience Function
    
    public func cgSize(from adSize: VpadnAdSize) -> CGSize {
        var resultSize = adSize.size
        let type = adSize.adType
        if type == .smartLandscape || type == .smartPortrait {
            resultSize = smartMaterialSize(type: type, showSize: .zero)
        }
        return resultSize
    }
    
    // MARK: - 開始取得廣告
    
    /// 取得廣告
    public func loadRequest(_ request: VpadnAdRequest) {
        VponAdRequestConfiguration.shared.testDeviceIdentifiers = self.testIdentifiers
        
        let newRequest = request.toNewInterface()
        bannerView?.autoRefresh = request.autoRefresh
        bannerView?.load(newRequest)
    }
    
    // MARK: - Helper
    
    private func smartMaterialSize(type: VponSizeType, showSize: CGSize) -> CGSize {
        var width: CGFloat = 0.0, height: CGFloat = 0.0
        if CGSizeEqualToSize(showSize, .zero) {
            width = UIScreen.main.bounds.size.width
            height = width * 0.125
        } else {
            width = showSize.width
            height = showSize.height
        }
        let VpadnAdSizeBanner = VpadnAdSize.banner()
        let VpadnAdSizeLargeRectangle = VpadnAdSize.largeRectangle()
        let VpadnAdSizeMediumRectangle = VpadnAdSize.mediumRectangle()
        let VpadnAdSizeLeaderboard = VpadnAdSize.leaderBoard()
        let VpadnAdSizeFullBanner = VpadnAdSize.fullBanner()
        let VpadnAdSizeLargeBanner = VpadnAdSize.largeBanner()
        
        if width >= VpadnAdSizeLargeRectangle.size.width && height >= VpadnAdSizeLargeRectangle.size.height {
            return VpadnAdSizeLargeRectangle.size
        }
        if width >= VpadnAdSizeMediumRectangle.size.width && height >= VpadnAdSizeMediumRectangle.size.height {
            return VpadnAdSizeMediumRectangle.size;
        }
        if width >= VpadnAdSizeLeaderboard.size.width && height >= VpadnAdSizeLeaderboard.size.height {
            return VpadnAdSizeLeaderboard.size;
        }
        if width >= VpadnAdSizeFullBanner.size.width && height >= VpadnAdSizeFullBanner.size.height {
            return VpadnAdSizeFullBanner.size;
        }
        if width >= VpadnAdSizeLargeBanner.size.width && height >= VpadnAdSizeLargeBanner.size.height {
            return VpadnAdSizeLargeBanner.size;
        }
        if height >= VpadnAdSizeBanner.size.height {
            return VpadnAdSizeBanner.size;
        }
        return CGSize(width: 480, height: 32)
    }
    
    /// 取得廣告 View
    public func getVpadnAdView() -> UIView? {
        if let bannerView {
            return bannerView
        } else {
            return nil
        }
    }
    
    // MARK: - Deinit
    
    deinit {
        VponConsole.log("[ARC] VpadnBanner deinit")
    }
}

// MARK: - v5.6 integration

extension VpadnBanner: VponBannerViewDelegate {
    
    public func bannerViewDidReceiveAd(_ bannerView: VponBannerView) {
        delegate?.onVpadnAdLoaded?(self)
    }
    
    public func bannerView(_ bannerView: VponBannerView, didFailToReceiveAdWithError error: Error) {
        delegate?.onVpadnAd?(self, failedToLoad: error)
    }
    
    public func bannerViewDidRecordImpression(_ bannerView: VponBannerView) {
        // No corresponding implementation
    }
    
    public func bannerViewDidRecordClick(_ bannerView: VponBannerView) {
        delegate?.onVpadnAdClicked?(self)
    }
}
