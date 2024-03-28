//
//  VponFlutterBannerAd.swift
//  vpon_plugin_poc
//
//  Created by vponinc on 2024/3/28.
//

import Flutter
import VpadnSDKAdKit

class VponFlutterBannerAdSize {
    var size: VponAdSize?
    var width: Int
    var height: Int
    
    init(width: Int?, height: Int?) {
        self.width = width ?? 320
        self.height = height ?? 50
        self.size = VponAdSize(size: CGSize(width: Double(self.width), height: Double(self.height)))
    }
}

class VponFlutterBannerAd: VponFlutterAd, FlutterPlatformView, VponBannerViewDelegate {
    
    private let bannerView: VponBannerView
    private let adRequest: VponFlutterAdRequest
    private let licenseKey: String
    private let autoRefresh: Bool
   
    
    init(licenseKey: String, size: VponFlutterBannerAdSize, request: VponFlutterAdRequest, rootViewController: UIViewController, adId: Int, autoRefresh: Bool) {
        self.bannerView = VponBannerView(adSize: size.size ?? .banner())
        self.adRequest = request
        self.licenseKey = licenseKey
        self.autoRefresh = autoRefresh
        super.init(adId: adId)
        self.adId = adId
        self.bannerView.rootViewController = rootViewController
    }
    
    override func load() {
        self.bannerView.delegate = self
        self.bannerView.licenseKey = licenseKey
        self.bannerView.autoRefresh = autoRefresh
        self.bannerView.load(adRequest.asVponAdRequest())
    }
    
    deinit {
        manager?.logToDart("FlutterBannerAd deinit")
    }
    
    // MARK: - FlutterPlatformView
    
    func view() -> UIView {
        return bannerView
    }
    
    // MARK: - VponBannerViewDelegate
    
    func bannerViewDidReceiveAd(_ bannerView: VponBannerView) {
        manager?.onAdLoaded(self)
    }
    
    func bannerView(_ bannerView: VponBannerView, didFailToReceiveAdWithError error: Error) {
        manager?.onAdFailed(toLoad: self, error: error)
    }
    
    func bannerViewDidRecordImpression(_ bannerView: VponBannerView) {
        manager?.onBannerImpression(self)
    }
    
    func bannerViewDidRecordClick(_ bannerView: VponBannerView) {
        manager?.adDidRecordClick(self)
    }
}
