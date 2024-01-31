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
    
    private func ad(for adId: Int) -> FlutterAd? {
        return ads[adId]
    }
    
    private func adId(for ad: FlutterAd) -> Int? {
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
    
    func onAdLoaded(_ ad: FlutterAd) {
        Console.log("AdInstanceManager invoke onAdEvent onAdLoaded")
        channel.invokeMethod(Constant.onAdEvent, arguments: [
            Constant.adId: ad.adId,
            Constant.eventName: "onAdLoaded"
        ])
    }
    
    func onAdFailed(toLoad: FlutterAd, error: Error) {
        Console.log("AdInstanceManager invoke onAdEvent onAdFailedToLoad")
        channel.invokeMethod(Constant.onAdEvent, arguments: [Constant.eventName: "onAdFailedToLoad"])
    }
    
    // MARK: - Dart notification - VponFullScreenContentDelegate
    
    func didFailToPresentFullScreenContent(_ ad: FlutterAd, with error: Error) {
        channel.invokeMethod(Constant.onAdEvent, 
                             arguments: [
                                Constant.eventName: "didFailToPresentFullScreenContent",
                                "error": error
                             ])
    }
    
    func adWillPresentScreen(_ ad: FlutterAd) {
        sendAdEvent("adWillPresentScreen", ad: ad)
    }
    
    // MARK: - Helper
    
    private func sendAdEvent(_ eventName: String, ad: FlutterAd) {
        Console.log("AdInstanceManager sendAdEvent: onAdEvent \(eventName)")
        channel.invokeMethod(Constant.onAdEvent,
                             arguments: [
                                Constant.eventName: eventName
                             ])
    }
}
