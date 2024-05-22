//
//  VponFlutterInterstitialAd.swift
//  Pods
//
//  Created by vponinc on 2024/3/28.
//

import VpadnSDKAdKit

/// Bridge between Dart and VponInterstitialAd
class VponFlutterInterstitialAd: VponFlutterFullScreenAd {
    
    private var interstitial: VponInterstitialAd?
    private var licenseKey: String
    private var request: VponFlutterAdRequest
    private var rootViewController: UIViewController
    
    init(licenseKey: String, request: VponFlutterAdRequest, rootViewController: UIViewController, adId: Int) {
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
            manager?.logToDart("InterstitialAd failed to show because the ad was not ready.", type: .error)
        }
    }
}

class VponFlutterFullScreenAd: VponFlutterAd, VponFlutterAdWithoutView, VponFullScreenContentDelegate {
    
    // MARK: - VponFlutterAdWithoutView
    
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
