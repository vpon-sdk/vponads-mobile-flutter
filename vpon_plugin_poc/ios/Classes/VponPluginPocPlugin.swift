import Flutter
import UIKit
import VpadnSDKAdKit
import AdSupport

enum MappedBannerSize: String {
    case banner = "banner"
    
    var size: CGSize {
        switch self {
        case .banner:
            return .init(width: 320, height: 50)
        }
    }
}

public class VponPluginPocPlugin: NSObject, FlutterPlugin {
    
    static var channel: FlutterMethodChannel?
    
    var interstitial: VpadnInterstitial?
    var banner: VpadnBanner?
    var mappedSize: MappedBannerSize?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        channel = FlutterMethodChannel(name: "vpon_plugin_poc", binaryMessenger: registrar.messenger())
        let instance = VponPluginPocPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel!)
        
        // Register native view
        let factory = PlatformAdViewFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: "plugins.flutter.io/custom_platform_view")
        
        // Init Vpon SDK
        VpadnAdConfiguration.shared.initializeSdk()
        VpadnAdConfiguration.shared.logLevel = .defaultLevel
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        case "loadInterstitialAd":
            // Deal with arguments from Dart
            if let arg = call.arguments as? [String: Any],
               let key = arg["licenseKey"] as? String,
               let request = arg["adRequest"] as? [String: Any],
               let autoRefresh = request["autoRefresh"] as? Bool,
               let contentURL = request["contentUrl"] as? String,
               let contentData = request["contentData"] as? [String: Any] {
                
                let request = VpadnAdRequest()
                request.autoRefresh = autoRefresh
                request.setContentUrl(contentURL)
                request.setContentData(contentData)
                
                request.setTestDevices([ASIdentifierManager.shared().advertisingIdentifier.uuidString])
                interstitial = VpadnInterstitial(licenseKey: key)
           
                interstitial?.delegate = self
                interstitial?.loadRequest(request)
                result(nil)
                
            } else {
                result(FlutterError(code: "errorSetLicenseKey", message: "data or format error", details: nil))
            }
        case "showInterstitial":
            if let vc = UIApplication.shared.keyWindow?.rootViewController {
                DispatchQueue.main.async {
                    self.interstitial?.showFromRootViewController(vc)
                }
            }
            
        case "loadBannerAd":
            let request = VpadnAdRequest()
            request.setTestDevices([ASIdentifierManager.shared().advertisingIdentifier.uuidString])
            
            // Deal with arguments from Dart
            if let arg = call.arguments as? [String: Any],
               let key = arg["licenseKey"] as? String,
               let size = arg["adSize"] as? String {
               
                mappedSize = MappedBannerSize(rawValue: size)
                var adSize: VpadnAdSize
                switch mappedSize {
                case .banner:
                    adSize = .banner()
                default:
                    adSize = .banner()
                }
                banner = VpadnBanner(licenseKey: key, adSize: adSize)
                banner?.delegate = self
                banner?.loadRequest(request)
                result(nil)
                
            } else {
                result(FlutterError(code: "errorSetLicenseKey", message: "data or format error", details: nil))
            }
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func convertBannerSize(from size: VpadnAdSize) {
       
    }
}

extension VponPluginPocPlugin: VpadnInterstitialDelegate {
    public func onVpadnInterstitialLoaded(_ interstitial: VpadnInterstitial) {
        VponPluginPocPlugin.channel?.invokeMethod("onVpadnInterstitialLoaded", arguments: "", result: { result in
            if let error = result as? FlutterError {
                
                print("error = \(error.message), \(error.code)")
            }
        })
    }
    
    public func onVpadnInterstitial(_ interstitial: VpadnInterstitial, failedToLoad error: Error) {
        print("[VponPluginPocPlugin] onVpadnInterstitial failedToLoad with error: \(error.localizedDescription)")
    }
}

extension VponPluginPocPlugin: VpadnBannerDelegate {
    public func onVpadnAdLoaded(_ banner: VpadnBanner) {
        print("[VponPluginPocPlugin] onVpadnAdLoaded")
        guard let adView = banner.getVpadnAdView(),
              let mappedSize else { return }
        // how to present banner?
        // 1. prepare banner here in platformView, but need adContainer size & position
        // 2. invoke dart method to show banner
    }
    
    public func onVpadnAd(_ banner: VpadnBanner, failedToLoad error: Error) {
        print("[VponPluginPocPlugin] onVpadnBanner failedToLoad with error: \(error.localizedDescription)")
    }
}
