//
//  VponAdInstanceManager.swift
//  vpon_mobile_ads
//
//  Created by vponinc on 2024/1/29.
//

import Foundation
import Flutter

/// Responsible for calling Dart method using channel.invokeMethod
class VponAdInstanceManager {
    
    private var ads: [Int: VponFlutterAd] = [:]
    private let channel: FlutterMethodChannel
    
    init(binaryMessenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: Constant.channelName, binaryMessenger: binaryMessenger)
    }
    
    func ad(for adId: Int) -> VponFlutterAd? {
        return ads[adId]
    }
    
    func adId(for ad: VponFlutterAd) -> Int? {
        let matchingKeys = ads.filter { $0.value === ad }.keys
        if matchingKeys.count > 1 {
            logToDart("\(type(of: self)) Error: Multiple keys for a single ad.", type: .error)
        }
        return matchingKeys.first
    }
    
    func loadAd(_ ad: VponFlutterAd) {
        ads[ad.adId] = ad
        ad.manager = self
        ad.load()
    }
    
    func showAd(adId: Int) {
        guard let ad = ad(for: adId) as? VponFlutterAdWithoutView else {
            logToDart("Can't find ad with id: \(adId)", type: .error)
            return
        }
        
        ad.show()
    }
    
    func dispose(adId: Int) {
        ads.removeValue(forKey: adId)
    }
    
    func disposeAllAds() {
        ads.removeAll()
    }
    
    func onAdLoaded(_ ad: VponFlutterAd) {
        logToDart("VponAdInstanceManager invoke onAdEvent onAdLoaded")
        channel.invokeMethod(Constant.onAdEvent, arguments: [
            Constant.adId: ad.adId,
            Constant.eventName: "onAdLoaded"
        ])
    }
    
    func onAdFailed(toLoad ad: VponFlutterAd, error: Error) {
        logToDart("VponAdInstanceManager invoke onAdEvent onAdFailedToLoad")
        channel.invokeMethod(Constant.onAdEvent, arguments: [
            Constant.adId: ad.adId,
            Constant.eventName: "onAdFailedToLoad",
            Constant.loadAdError: [Constant.errorDescription: error.localizedDescription,
                                   Constant.errorCode: (error as NSError).code]
        ])
    }
    
    // MARK: - Send event to Dart - FullScreen content ad callback
    
    func didFailToPresentFullScreenContent(_ ad: VponFlutterAd, with error: Error) {
        channel.invokeMethod(Constant.onAdEvent,
                             arguments: [
                                Constant.adId: ad.adId,
                                Constant.eventName: "didFailToPresentFullScreenContentWithError",
                                Constant.loadAdError: [Constant.errorDescription: error.localizedDescription,
                                                       Constant.errorCode: (error as NSError).code]
                             ])
    }
    
    func adDidRecordImpression(_ ad: VponFlutterAd) {
        sendAdEvent("adDidRecordImpression", ad: ad)
    }
    
    func adWillPresentFullScreenContent(_ ad: VponFlutterAd) {
        sendAdEvent("adWillPresentFullScreenContent", ad: ad)
    }
    
    func adWillDismissFullScreenContent(_ ad: VponFlutterAd) {
        sendAdEvent("adWillDismissFullScreenContent", ad: ad)
    }
    
    func adDidDismissFullScreenContent(_ ad: VponFlutterAd) {
        sendAdEvent("adDidDismissFullScreenContent", ad: ad)
    }
    
    // MARK: - Send event to Dart - Banner ad callback
    
    func onBannerImpression(_ ad: VponFlutterBannerAd) {
        sendAdEvent("onBannerImpression", ad: ad)
    }
    
    // MARK: - Send event to Dart -  Native ad callback
    
    func onNativeAdImpression(_ ad: VponFlutterNativeAd) {
        sendAdEvent("onNativeAdImpression", ad: ad)
    }
    
    // MARK: - Send event to Dart - callback
    
    func adDidRecordClick(_ ad: VponFlutterAd) {
        sendAdEvent("adDidRecordClick", ad: ad)
    }
    
    // MARK: - Helper
    
    /// Print console log from Dart.
    func logToDart(_ message: String, type: LogType = .debug) {
        channel.invokeMethod(Constant.nativeLog,
                             arguments: [
                                "message": message,
                                "type": type.rawValue
                             ])
    }
    
    private func sendAdEvent(_ eventName: String, ad: VponFlutterAd) {
        logToDart("VponAdInstanceManager sendAdEvent: onAdEvent \(eventName)")
        channel.invokeMethod(Constant.onAdEvent,
                             arguments: [
                                Constant.adId: ad.adId,
                                Constant.eventName: eventName
                             ])
    }
}
