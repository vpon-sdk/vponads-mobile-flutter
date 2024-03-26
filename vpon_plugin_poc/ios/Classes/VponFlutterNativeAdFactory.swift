//
//  FlutterNativeAdFactory.swift
//  vpon_plugin_poc
//
//  Created by vponinc on 2024/3/6.
//

import VpadnSDKAdKit

@objc public protocol VponFlutterNativeAdFactory {
    func createNativeAd(nativeAd: VponNativeAd) -> VponNativeAdView?
}
