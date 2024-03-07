//
//  FlutterNativeAdFactory.swift
//  vpon_plugin_poc
//
//  Created by vponinc on 2024/3/6.
//

import VpadnSDKAdKit

public protocol FlutterNativeAdFactory {
    func createNativeAd(nativeAd: VponNativeAd) -> VponNativeAdView?
}
