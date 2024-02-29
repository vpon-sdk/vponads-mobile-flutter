//
//  VponInterstitialAd.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/8/9.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

@objc public protocol VponFullScreenContentAd { }

@objc public protocol VponFullScreenContentDelegate: AnyObject {
    /// 通知廣告已送出曝光事件
    @objc optional func adDidRecordImpression(_ ad: VponFullScreenContentAd)
    /// 通知廣告已送出點擊事件
    @objc optional func adDidRecordClick(_ ad: VponFullScreenContentAd)
    /// 通知廣告即將展示在畫面上
    @objc optional func adWillPresentScreen(_ ad: VponFullScreenContentAd)
    /// 通知廣告即將從畫面上移除
    @objc optional func adWillDismissScreen(_ ad: VponFullScreenContentAd)
    /// 通知廣告已從畫面上移除
    @objc optional func adDidDismissScreen(_ ad: VponFullScreenContentAd)
    /// 通知廣告呈現在畫面失敗
    @objc optional func ad(_ ad: VponFullScreenContentAd, didFailToPresentFullScreenContentWithError error: Error)
}

@objcMembers public final class VponInterstitialAd: NSObject, VponFullScreenContentAd {
    
    public weak var delegate: VponFullScreenContentDelegate?
    internal var controller: InterstitialController?

    
    public static func load(licenseKey: String, request: VponAdRequest, completion: @escaping (_ interstitial: VponInterstitialAd?, _ error: Error?) -> Void) {
        guard VponAdConfiguration.shared.isInitSDK() else {
            completion(nil, ErrorGenerator.initSDKFailed())
            return
        }
        
        guard !licenseKey.isEmpty else {
            VponConsole.log("Please specify your license key.", .error)
            completion(nil, ErrorGenerator.noAds())
            return
        }
        
        // Check if licenseKey is restricted
        guard RemoteConfigManager.shared.shouldAllowRequest(licenseKey: licenseKey) else {
            completion(nil, ErrorGenerator.noAds())
            return
        }
        
        request.format = "mi"
        
        InterstitialController.requestAd(licenseKey: licenseKey, request: request, completion: completion)
    }
    
    public func present(fromRootViewController rootViewController: UIViewController) {
        guard let controller else {
            delegate?.ad?(self, didFailToPresentFullScreenContentWithError: ErrorGenerator.noAds())
            return
        }
        delegate?.adWillPresentScreen?(self)
        controller.present(fromRootViewController: rootViewController)
        
        controller.willDismiss = { [weak self] in
            guard let self else { return }
            delegate?.adWillDismissScreen?(self)
        }
        
        controller.didDismiss = { [weak self] in
            guard let self else { return }
            delegate?.adDidDismissScreen?(self)
        }
        
        controller.didRecordImpression = {
            [weak self] in
                guard let self else { return }
                delegate?.adDidRecordImpression?(self)
        }
        
        controller.didRecordClick = {
            [weak self] in
                guard let self else { return }
                delegate?.adDidRecordClick?(self)
        }
    }
    
    // MARK: - Deinit
    
    deinit {
        controller?.unregisterAllEvents()
        VponConsole.log("[ARC] VponInterstitialAd deinit")
    }
}
