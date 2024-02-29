//
//  VponNativeAdView.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/10/27.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

@objcMembers open class VponNativeAdView: UIView {
    
    @IBOutlet public weak var iconView: UIView?
    @IBOutlet public weak var coverImageView: UIView?
    @IBOutlet public weak var ratingValueView: UIView?
    @IBOutlet public weak var ratingScaleView: UIView?
    @IBOutlet public weak var headlineView: UIView?
    @IBOutlet public weak var bodyView: UIView?
    @IBOutlet public weak var callToActionView: UIView?
    @IBOutlet public weak var socialContextView: UIView?
    @IBOutlet public weak var mediaView: VponMediaView?
    
    private var adChoicesView: AdChoicesView?
    
    public var nativeAd: VponNativeAd? {
        didSet {
            if let previousNativeAd = oldValue {
                // 如果同頁面重複要廣告，須釋放前一個 nativeAd 物件
                previousNativeAd.unregisterView()
            }
            
            guard let nativeAd else { return }
            nativeAd.updateMediaSourceIfNeeded()
            nativeAd.loadMediaView(mediaView)
            nativeAd.registerAdView(self)
        }
    }
    
    /// 執行點擊事件
    @objc private func clickHandler(_ sender: Any) {
        nativeAd?.clickHandler(sender)
    }
    
    // MARK: - Deinit
    
    deinit {
        // Crucial!!! to avoid memory leak
        mediaView?.unregisterAllEvents()
        nativeAd?.stopExposureTimer()
        VponConsole.log("[ARC] VponNativeAdView deinit")
    }
}
