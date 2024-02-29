//
//  VponNativeAdLoader.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/10/27.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

@objc public protocol VponNativeAdLoaderDelegate: AnyObject {
    /// 通知有廣告可供拉取 call back
    @objc optional func adLoader(_ adLoader: VponNativeAdLoader, didReceive nativeAd: VponNativeAd)
    /// 通知拉取廣告失敗 call back
    @objc optional func adLoader(_ adLoader: VponNativeAdLoader, didFailToReceiveAdWithError error: Error)
}

@objcMembers public final class VponNativeAdLoader: NSObject {
    
    public weak var delegate: VponNativeAdLoaderDelegate?
    
    private let licenseKey: String
    private weak var rootViewController: UIViewController?
    private var nativeAd: VponNativeAd?
    private var controller: NativeController?
    
    public init(licenseKey: String, rootViewController: UIViewController?) {
        self.licenseKey = licenseKey
        self.rootViewController = rootViewController
    }
    
    public func load(_ request: VponAdRequest) {
        if VponAdConfiguration.shared.isInitSDK() {
            
            guard !licenseKey.isEmpty else {
                VponConsole.log("Please specify your license key.", .error)
                delegate?.adLoader?(self, didFailToReceiveAdWithError: ErrorGenerator.noAds())
                return
            }
            
            // Check if licenseKey is restricted
            guard RemoteConfigManager.shared.shouldAllowRequest(licenseKey: licenseKey) else {
                delegate?.adLoader?(self, didFailToReceiveAdWithError: ErrorGenerator.noAds())
                return
            }
            
            sendAdRequest(request)
        } else {
            delegate?.adLoader?(self, didFailToReceiveAdWithError: ErrorGenerator.initSDKFailed())
        }
    }
    
    private func sendAdRequest(_ request: VponAdRequest) {
        DispatchQueue.main.async {
            VponConsole.note()
            
            self.controller = NativeController()
            self.controller?.rootViewController = self.rootViewController
            self.controller?.requestAd(licenseKey: self.licenseKey, request: request) { result in
                switch result {
                case .success(let nativeAd):
                    self.nativeAd = nativeAd
                    self.delegate?.adLoader?(self, didReceive: nativeAd)
                case .failure(let error):
                    self.delegate?.adLoader?(self, didFailToReceiveAdWithError: error)
                }
            }
        }
    }
    
    // MARK: - Deinit
    
    deinit {
        nativeAd?.unregisterView()
        VponConsole.log("[ARC] VponNativeAdLoader deinit")
    }
}
