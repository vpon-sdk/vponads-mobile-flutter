//
//  VPInterstitial.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/4/21.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

@available(*, deprecated, message: "Use VponFullScreenContentDelegate instead.")
@objc public protocol VpadnInterstitialDelegate: AnyObject {

    /// 通知有廣告可供拉取 call back
    @objc optional func onVpadnInterstitialLoaded(_ interstitial: VpadnInterstitial)

    /// 通知拉取廣告失敗 call back
    @objc optional func onVpadnInterstitial(_ interstitial: VpadnInterstitial, failedToLoad error: Error)

    @available(*, deprecated, message: "No replacement.")
    @objc optional func onVpadnInterstitialWillLeaveApplication(_ interstitial: VpadnInterstitial)

    /// 通知廣告即將被開啟
    @objc optional func onVpadnInterstitialWillOpen(_ interstitial: VpadnInterstitial)

    /// 通知廣告已被關閉
    @objc optional func onVpadnInterstitialClosed(_ interstitial: VpadnInterstitial)

    /// 通知廣告已送出點擊事件
    @objc optional func onVpadnInterstitialClicked(_ interstitial: VpadnInterstitial)
}

@available(*, deprecated, message: "Use VponInterstitialAd instead.")
@objcMembers public final class VpadnInterstitial: NSObject {

    // MARK: - Properties

    /// Delegate token
    public weak var delegate: VpadnInterstitialDelegate?
    
    @available(*, deprecated, message: "No replacement.")
    public var strBannerId: String? // 目前已沒在用
    
    @available(*, deprecated, message: "No replacement.")
    public var platform: String? // 目前已沒在用
    
    @available(*, deprecated, message: "No replacement.")
    public var hasBeenUsed: Bool = false // 目前已沒在用
    
    @available(*, deprecated, message: "Use VponAdRequestConfiguration.shared.testDeviceIdentifiers instead.")
    public var testIdentifiers: [String] = []
    
    // MARK: - v5.6 integration
    
    private var licenseKey: String
    private var newInterstitial: VponInterstitialAd?

    // MARK: - Initializer

    /// 初始化方法
    /// - Parameter licenseKey: 版位 ID (BannerID, PlacementID)
    public init(licenseKey: String) {
        self.licenseKey = licenseKey
        super.init()
    }

    // MARK: - 開始取得廣告

    /// 取得廣告
    public func loadRequest(_ request: VpadnAdRequest) {
        let newRequest = request.toNewInterface()
        VponInterstitialAd.load(licenseKey: licenseKey, request: newRequest) { interstitial, error in
            
            if let interstitial {
                self.newInterstitial = interstitial
                interstitial.delegate = self
                self.delegate?.onVpadnInterstitialLoaded?(self)
            }
            
            if let error {
                self.delegate?.onVpadnInterstitial?(self, failedToLoad: error)
            }
        }
    }

    /// 顯示廣告
    /// - Parameter rootViewCtrl: 根控制項
    public func showFromRootViewController(_ rootViewCtrl: UIViewController) {
        if let newInterstitial {
            newInterstitial.present(fromRootViewController: rootViewCtrl)
        }
    }

    @available(*, deprecated, message: "No replacement.")
    public func isReady() -> Bool {
        // 目前已沒在用
        return true
    }
    
    // MARK: - Deinit
    
    deinit {
        VponConsole.log("[ARC] VpadnInterstitial deinit")
    }
}

// MARK: - v5.6 integration

extension VpadnInterstitial: VponFullScreenContentDelegate {
    
    public func adWillPresentScreen(_ ad: VponFullScreenContentAd) {
        delegate?.onVpadnInterstitialWillOpen?(self)
    }
    
    public func adDidDismissScreen(_ ad: VponFullScreenContentAd) {
        delegate?.onVpadnInterstitialClosed?(self)
    }
    
    public func adDidRecordClick(_ ad: VponFullScreenContentAd) {
        delegate?.onVpadnInterstitialClicked?(self)
    }
   
    public func adWillDismissScreen(_ ad: VponFullScreenContentAd) {
        // No corresponding implementation
    }
    
    public func ad(_ ad: VponFullScreenContentAd, didFailToPresentFullScreenContentWithError error: Error) {
        // No corresponding implementation
    }
    
    public func adDidRecordImpression(_ ad: VponFullScreenContentAd) {
        // No corresponding implementation
    }
}
