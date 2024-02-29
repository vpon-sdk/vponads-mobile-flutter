//
//  FlutterInterstitialAd.swift
//  vpon_plugin_poc
//
//  Created by vponinc on 2024/1/29.
//

import Foundation
import Flutter
import VpadnSDKAdKit

protocol FlutterAdWithoutView {
    func show()
}

class FlutterAd: NSObject {
    
    var adId: Int
    weak var manager: AdInstanceManager?
    
    init(adId: Int) {
        self.adId = adId
    }
    
    func load() {}
}

class FlutterFullScreenAd: FlutterAd, FlutterAdWithoutView, VponFullScreenContentDelegate {
    
    // MARK: - FlutterAdWithoutView
    
    func show() {
        // Must be overridden by subclasses
        fatalError("Must override show() in a subclass")
    }
    
    // MARK: - VponFullScreenContentDelegate
    
    func ad(_ ad: VponFullScreenContentAd, didFailToPresentFullScreenContentWithError error: Error) {
        manager?.didFailToPresentFullScreenContent(self, with: error)
    }
    
    func adWillPresentScreen(_ ad: VponFullScreenContentAd) {
        manager?.adWillPresentFullScreenContent(self)
    }
    
    func adWillDismissScreen(_ ad: VponFullScreenContentAd) {
        manager?.adWillDismissFullScreenContent(self)
    }
    
    func adDidDismissScreen(_ ad: VponFullScreenContentAd) {
        manager?.adDidDismissFullScreenContent(self)
    }
    
    func adDidRecordImpression(_ ad: VponFullScreenContentAd) {
        manager?.adDidRecordImpression(self)
    }
    
    func adDidRecordClick(_ ad: VponFullScreenContentAd) {
        manager?.adDidRecordClick(self)
    }
}

/// Bridge between Dart and VponInterstitialAd
class FlutterInterstitialAd: FlutterFullScreenAd {
    
    private var interstitial: VponInterstitialAd?
    private var licenseKey: String
    private var request: FlutterAdRequest
    private var rootViewController: UIViewController
    
    init(licenseKey: String, request: FlutterAdRequest, rootViewController: UIViewController, adId: Int) {
        self.licenseKey = licenseKey
        self.request = request
        self.rootViewController = rootViewController
        super.init(adId: adId)
        self.adId = adId
    }
    
    override func load() {
        VponInterstitialAd.load(licenseKey: licenseKey,
                                request: request.asVponAdRequest()) { interstitial, error in
            
            if let error {
                Console.log("FlutterInterstitialAd load error", type: .error)
                self.manager?.onAdFailed(toLoad: self, error: error)
                return
            }
            interstitial?.delegate = self
            self.interstitial = interstitial
            self.manager?.onAdLoaded(self)
        }
    }
    
    override func show() {
        if let interstitial {
            interstitial.present(fromRootViewController: rootViewController)
        } else {
            Console.log("InterstitialAd failed to show because the ad was not ready.")
        }
    }
}

class FlutterBannerAdSize {
    var size: VponAdSize?
    var width: Int
    var height: Int
    
    init(width: Int?, height: Int?) {
        self.width = width ?? 320
        self.height = height ?? 50
        self.size = VponAdSize(size: CGSize(width: Double(self.width), height: Double(self.height)))
    }
    
//    init(adSize size: VponAdSize) {
//        self.size = size
        #warning("Is VponAdSize necessary to have size interface?")
//        self.width = size.size.width
//        self.height = size.size.height
//    }
}

class FlutterBannerAd: FlutterAd, FlutterPlatformView, VponBannerViewDelegate {
    
    private let bannerView: VponBannerView
    private let adRequest: FlutterAdRequest
    private let licenseKey: String
   
    
    init(licenseKey: String, size: FlutterBannerAdSize, request: FlutterAdRequest, rootViewController: UIViewController, adId: Int) {
        self.bannerView = VponBannerView(adSize: size.size ?? .banner())
        self.adRequest = request
        self.licenseKey = licenseKey
        super.init(adId: adId)
        self.adId = adId
        self.bannerView.rootViewController = rootViewController
    }
    
    override func load() {
        self.bannerView.delegate = self
        self.bannerView.licenseKey = licenseKey
        self.bannerView.load(adRequest.asVponAdRequest())
    }
    
//    func getAdSize() -> FlutterBannerAdSize {
//        return FlutterBannerAdSize(adSize: bannerView.adSize)
//    }
    
    deinit {
        Console.log("FlutterBannerAd deinit")
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
        manager?.adDidRecordImpression(self)
    }
    
    func bannerViewDidRecordClick(_ bannerView: VponBannerView) {
        manager?.adDidRecordClick(self)
    }
}
