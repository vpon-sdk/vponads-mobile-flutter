//
//  PlatformAdView.swift
//  vpon_plugin_poc
//
//  Created by vponinc on 2024/1/10.
//

import UIKit
import VpadnSDKAdKit
import Flutter

class VponAdsViewFactory:NSObject, FlutterPlatformViewFactory {

    var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {

        return PlatformAdView(frame, viewID: viewId, args: args, messenger: messenger)
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}


class PlatformAdView:NSObject, FlutterPlatformView {
    
    var channel: FlutterMethodChannel?

    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    lazy var webview: WKWebView = {
        let webview = WKWebView()
        webview.backgroundColor = .systemYellow
        return webview
    }()
    
    var adView: UIView?

    init(_ frame: CGRect, viewID: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
        super.init()
        channel = FlutterMethodChannel(name: "vpon_plugin_poc", binaryMessenger: messenger)
        channel?.invokeMethod("showBanner", arguments: nil, result: { result in
            Console.log("showBanner with result: \(String(describing: result))")
        })
//        nameLabel.text = "我是 iOS Test View"
//        webview.load(URLRequest(url: URL(string: "https://google.com")!))
       
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func view() -> UIView {
        let errorView = UIView()
        errorView.backgroundColor = .red
        return adView ?? errorView
    }
}
