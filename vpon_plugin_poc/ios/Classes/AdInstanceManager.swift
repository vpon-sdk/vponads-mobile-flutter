//
//  AdInstanceManager.swift
//  vpon_plugin_poc
//
//  Created by vponinc on 2024/1/29.
//

import Foundation
import Flutter

/// Responsible for calling Dart method using channel.invokeMethod
class AdInstanceManager {
    
    private var ads: [Int: FlutterAd] = [:]
    private let channel: FlutterMethodChannel
    
    init(binaryMessenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: Constant.channelName, binaryMessenger: binaryMessenger)
    }
    
    func ad(for adId: Int) -> FlutterAd? {
        return ads[adId]
    }
    
    func adId(for ad: FlutterAd) -> Int? {
        let matchingKeys = ads.filter { $0.value === ad }.keys
        if matchingKeys.count > 1 {
            Console.log("\(type(of: self)) Error: Multiple keys for a single ad.")
        }
        return matchingKeys.first
    }
    
    func loadAd(_ ad: FlutterAd) {
        ads[ad.adId] = ad
        ad.manager = self
        ad.load()
    }
    
    func showAd(adId: Int) {
        guard let ad = ad(for: adId) as? FlutterAdWithoutView else {
            Console.log("Can't find ad with id: \(adId)")
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
    
    func onAdLoaded(_ ad: FlutterAd) {
        Console.log("AdInstanceManager invoke onAdEvent onAdLoaded")
        channel.invokeMethod(Constant.onAdEvent, arguments: [
            Constant.adId: ad.adId,
            Constant.eventName: "onAdLoaded"
        ])
    }
    
    func onAdFailed(toLoad ad: FlutterAd, error: Error) {
        Console.log("AdInstanceManager invoke onAdEvent onAdFailedToLoad")
        
        channel.invokeMethod(Constant.onAdEvent, arguments: [
            Constant.adId: ad.adId,
            Constant.eventName: "onAdFailedToLoad",
            Constant.loadAdError: "testLoadAdError"
//            Constant.loadAdError: FlutterLoadAdError(error: error as NSError)
        ])
    }
    
    // MARK: - Dart notification - VponFullScreenContentDelegate
    
    func didFailToPresentFullScreenContent(_ ad: FlutterAd, with error: Error) {
        channel.invokeMethod(Constant.onAdEvent, 
                             arguments: [
                                Constant.adId: ad.adId,
                                Constant.eventName: "didFailToPresentFullScreenContentWithError",
                                "error": error
                             ])
    }
    
    func adWillPresentFullScreenContent(_ ad: FlutterAd) {
        sendAdEvent("adWillPresentFullScreenContent", ad: ad)
    }
    
    func adWillDismissFullScreenContent(_ ad: FlutterAd) {
        sendAdEvent("adWillDismissFullScreenContent", ad: ad)
    }
    
    func adDidDismissFullScreenContent(_ ad: FlutterAd) {
        sendAdEvent("adDidDismissFullScreenContent", ad: ad)
    }
    
    // MARK: - General
    
    func adDidRecordImpression(_ ad: FlutterAd) {
        sendAdEvent("adDidRecordImpression", ad: ad)
    }
    
    func adDidRecordClick(_ ad: FlutterAd) {
        sendAdEvent("adDidRecordClick", ad: ad)
    }
    
   
    
    // MARK: - Helper
    
    private func sendAdEvent(_ eventName: String, ad: FlutterAd) {
        Console.log("AdInstanceManager sendAdEvent: onAdEvent \(eventName)")
        channel.invokeMethod(Constant.onAdEvent,
                             arguments: [
                                Constant.adId: ad.adId,
                                Constant.eventName: eventName
                             ])
    }
}
