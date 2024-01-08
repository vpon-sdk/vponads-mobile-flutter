import Flutter
import UIKit
import VpadnSDKAdKit
import AdSupport

public class VponPluginPocPlugin: NSObject, FlutterPlugin {
    
    var interstitial: VpadnInterstitial?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "vpon_plugin_poc", binaryMessenger: registrar.messenger())
        let instance = VponPluginPocPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        VpadnAdConfiguration.shared.initializeSdk()
        VpadnAdConfiguration.shared.logLevel = .defaultLevel
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        case "loadInterstitialAd":
            let request = VpadnAdRequest()
            request.setTestDevices([ASIdentifierManager.shared().advertisingIdentifier.uuidString])
            
            // Deal with arguments from Dart
            if let arg = call.arguments as? [String: Any],
               let key = arg["licenseKey"] as? String {
               
                interstitial = VpadnInterstitial(licenseKey: key)
                // interstitial = VpadnInterstitial(licenseKey: "8a80854b79a9f2ce0179c09793ab4b79")
                interstitial?.delegate = self
                interstitial?.loadRequest(request)
                result(nil)
                
            } else {
                result(FlutterError(code: "errorSetLicenseKey", message: "data or format error", details: nil))
            }
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

extension VponPluginPocPlugin: VpadnInterstitialDelegate {
    public func onVpadnInterstitialLoaded(_ interstitial: VpadnInterstitial) {
        if let vc = UIApplication.shared.keyWindow?.rootViewController {
            DispatchQueue.main.async {
                interstitial.showFromRootViewController(vc)
            }
        }
    }
    
    public func onVpadnInterstitial(_ interstitial: VpadnInterstitial, failedToLoad error: Error) {
        print("[VponPluginPocPlugin] onVpadnInterstitial failedToLoad with error: \(error.localizedDescription)")
    }
}
