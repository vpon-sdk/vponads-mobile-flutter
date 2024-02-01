//
//  FlutterInterstitialAd.swift
//  vpon_plugin_poc
//
//  Created by vponinc on 2024/1/29.
//

import Foundation
import VpadnSDKAdKit

protocol FlutterAdWithoutView {
    func show()
}

class FlutterAd {
    
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
                                request: request.asVponAdRequest(licenseKey: licenseKey)) { interstitial, error in
            
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
