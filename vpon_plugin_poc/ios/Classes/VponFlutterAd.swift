//
//  VponFlutterInterstitialAd.swift
//  vpon_plugin_poc
//
//  Created by vponinc on 2024/1/29.
//

import Foundation
import Flutter
import VpadnSDKAdKit

protocol VponFlutterAdWithoutView {
    func show()
}

class VponFlutterAd: NSObject {
    
    var adId: Int
    weak var manager: VponAdInstanceManager?
    
    init(adId: Int) {
        self.adId = adId
    }
    
    func load() {}
}
