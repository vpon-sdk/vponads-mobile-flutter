import Flutter
import UIKit
import VpadnSDKAdKit
import AdSupport

public class VponPluginPocPlugin: NSObject, FlutterPlugin {
    
    var channel: FlutterMethodChannel?
    var manager: AdInstanceManager
    var readerWriter: FlutterVponAdReaderWriter?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let plugin = VponPluginPocPlugin(binaryMessenger: registrar.messenger())
        registrar.publish(plugin)
        
        let readerWriter = FlutterVponAdReaderWriter()
        plugin.readerWriter = readerWriter
        
        let codec = FlutterStandardMethodCodec(readerWriter: readerWriter)
        
        plugin.channel = FlutterMethodChannel(name: Constant.channelName,
                                                binaryMessenger: registrar.messenger(),
                                                codec: codec)
        registrar.addMethodCallDelegate(plugin, channel: plugin.channel!)
        
        // Register native view
        let factory = VponAdsViewFactory(manager: plugin.manager)
        registrar.register(factory, withId: "\(Constant.channelName)/ad_widget")
        registrar.addApplicationDelegate(plugin)
    }
    
    init(binaryMessenger: FlutterBinaryMessenger) {
        manager = AdInstanceManager(binaryMessenger: binaryMessenger)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let rootController = self.rootController()
        switch call.method {
            
        case "VponAdSDK#initialize":
            // Init Vpon SDK
            VponAdConfiguration.shared.initializeSdk()
            VponAdConfiguration.shared.logLevel = .debug
            
        case "_init":
            manager.disposeAllAds()
            result(nil)
            
        case "VponAdSDK#updateRequestConfiguration":
            guard let arg = call.arguments as? [String: Any] else {
                result(nil)
                return
            }
            let config = VponAdRequestConfiguration.shared
            if let testDeviceIds = arg["testDeviceIds"] as? [String] {
                config.testDeviceIdentifiers = testDeviceIds
            }
            if let maxAdContentRating = arg["maxAdContentRating"] as? String {
                switch maxAdContentRating {
                case "general":
                    config.maxAdContentRating = .general
                case "parentalGuidance":
                    config.maxAdContentRating = .parentalGuidance
                case "teen":
                    config.maxAdContentRating = .teen
                case "matureAudience":
                    config.maxAdContentRating = .matureAudience
                default:
                    config.maxAdContentRating = .unspecified
                }
            }
            if let tagForChildDirectedTreatment = arg["tagForChildDirectedTreatment"] as? Int {
                switch tagForChildDirectedTreatment {
                case 0:
                    config.tagForChildDirectedTreatment = .notForChildDirectedTreatment
                case 1:
                    config.tagForChildDirectedTreatment = .forChildDirectedTreatment
                default:
                    config.tagForChildDirectedTreatment = .unspecified
                }
            }
            if let tagForUnderAgeOfConsent = arg["tagForUnderAgeOfConsent"] as? Int {
                switch tagForUnderAgeOfConsent {
                case 0:
                    config.tagForUnderAgeOfConsent = .notForUnderAgeOfConsent
                case 1:
                    config.tagForUnderAgeOfConsent = .forUnderAgeOfConsent
                default:
                    config.tagForUnderAgeOfConsent = .unspecified
                }
            }
            result(nil)
            
        case "loadInterstitialAd":
            guard let arg = call.arguments as? [String: Any] else {
                result(nil)
                return
            }
            if let key = arg["licenseKey"] as? String,
               let adId = arg["adId"] as? Int,
               let request = arg["request"] as? FlutterAdRequest {
                
                let ad = FlutterInterstitialAd(licenseKey: key, 
                                               request: request,
                                               rootViewController: rootController,
                                               adId: adId)
                manager.loadAd(ad)
            }
            result(nil)
            
        case "loadBannerAd":
            guard let arg = call.arguments as? [String: Any] else {
                result(nil)
                return
            }
            if let key = arg["licenseKey"] as? String,
               let size = arg["size"] as? FlutterBannerAdSize,
               let adId = arg["adId"] as? Int,
               let request = arg["request"] as? FlutterAdRequest {
                
                let ad = FlutterBannerAd(licenseKey: key,
                                         size: size,
                                         request: request,
                                         rootViewController: rootController,
                                         adId: adId)
                manager.loadAd(ad)
            }
            result(nil)
            
            
        case "disposeAd":
            guard let arg = call.arguments as? [String: Any] else {
                result(nil)
                return
            }
            if let adId = arg["adId"] as? Int {
                manager.dispose(adId: adId)
            }
            result(nil)
            
        case "showAdWithoutView":
            guard let arg = call.arguments as? [String: Any] else {
                result(nil)
                return
            }
            if let adId = arg["adId"] as? Int {
                manager.showAd(adId: adId)
            }
            result(nil)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Helper
    
    private func rootController() -> UIViewController {
        let root = UIApplication.shared.delegate?.window??.rootViewController ?? UIApplication.shared.keyWindow?.rootViewController
        
        var presentedViewController = root
        while let presented = presentedViewController?.presentedViewController {
            presentedViewController = presented
        }
        
        return presentedViewController ?? UIViewController()
    }
}
