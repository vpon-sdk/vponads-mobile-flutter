//
//  NativeAdFactory.swift
//  Runner
//
//  Created by vponinc on 2024/3/6.
//

import VpadnSDKAdKit
import vpon_plugin_poc

class NativeAdFactory: FlutterNativeAdFactory {
    
    func createNativeAd(nativeAd: VponNativeAd) -> VponNativeAdView? {
        guard let adView = Bundle.main.loadNibNamed("NativeAdView", owner: nil)?.first as? VponNativeAdView else {
            return nil
        }
        
        (adView.headlineView as! UILabel).text = nativeAd.headline
        (adView.bodyView as! UILabel).text = nativeAd.body
        (adView.iconView as! UIImageView).image = nativeAd.icon?.image
        adView.mediaView?.mediaContent = nativeAd.mediaContent
        NSLog("mediaContent: \(nativeAd.mediaContent)")
        NSLog("mediaView: \(adView.mediaView)")
        (adView.callToActionView as! UIButton).setTitle(nativeAd.callToAction, for: .normal)
        adView.nativeAd = nativeAd
        
        return adView
    }
}
