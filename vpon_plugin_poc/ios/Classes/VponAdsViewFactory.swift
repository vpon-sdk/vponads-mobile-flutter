//
//  VponAdsViewFactory.swift
//  vpon_plugin_poc
//
//  Created by vponinc on 2024/2/23.
//

import Flutter

class VponAdsViewFactory: NSObject, FlutterPlatformViewFactory {
    
    private let manager: AdInstanceManager
    
    init(manager: AdInstanceManager) {
        self.manager = manager
    }
    
    // MARK: - FlutterPlatformViewFactory
    
    func create(withFrame frame: CGRect, 
                viewIdentifier viewId: Int64,
                arguments args: Any?) -> FlutterPlatformView {
        guard let adId = args as? Int,
              let view = manager.ad(for: adId) as? FlutterPlatformView else {
            fatalError("Could not find an ad with id: \(String(describing: args as? Int)). Was this ad already disposed?")
        }
        return view
    }
    
    /// Must implement this method to receive args properly!
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}
