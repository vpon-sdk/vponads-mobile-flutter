//
//  VponFlutterNativeAd.swift
//  vpon_plugin_poc
//
//  Created by vponinc on 2024/3/28.
//

import Flutter
import VpadnSDKAdKit

class VponFlutterNativeAd: VponFlutterAd, FlutterPlatformView, VponNativeAdLoaderDelegate, VponNativeAdDelegate {
    
    private let licenseKey: String
    private let adRequest: VponFlutterAdRequest
    private let nativeAdFactory: VponFlutterNativeAdFactory
    private var adView: UIView?
    private let adLoader: VponNativeAdLoader
    
    init(licenseKey: String,
         adRequest: VponFlutterAdRequest,
         nativeAdFactory: VponFlutterNativeAdFactory,
         rootViewController: UIViewController,
         adId: Int) {
        
        self.licenseKey = licenseKey
        self.adRequest = adRequest
        self.nativeAdFactory = nativeAdFactory
        self.adLoader = VponNativeAdLoader(licenseKey: licenseKey, rootViewController: rootViewController)
        super.init(adId: adId)
        self.adLoader.delegate = self
    }
    
    override func load() {
        adLoader.load(adRequest.asVponAdRequest())
    }
    
    // MARK: - FlutterPlatformView
    
    func view() -> UIView {
        let test = UIView()
        test.backgroundColor = .red
        #warning("What to do if adView is nil?")
        return adView ?? test
    }
    
    // MARK: - VponNativeAdLoaderDelegate
    
    func adLoader(_ adLoader: VponNativeAdLoader, didReceive nativeAd: VponNativeAd) {
        adView = nativeAdFactory.createNativeAd(nativeAd: nativeAd)
        nativeAd.delegate = self
        manager?.onAdLoaded(self)
    }
    
    func adLoader(_ adLoader: VponNativeAdLoader, didFailToReceiveAdWithError error: Error) {
        manager?.onAdFailed(toLoad: self, error: error)
    }
    
    // MARK: - VponNativeAdDelegate
    
    func nativeAdDidRecordClick(_ nativeAd: VponNativeAd) {
        manager?.adDidRecordClick(self)
    }
    
    func nativeAdDidRecordImpression(_ nativeAd: VponNativeAd) {
        manager?.onNativeAdImpression(self)
    }
}
