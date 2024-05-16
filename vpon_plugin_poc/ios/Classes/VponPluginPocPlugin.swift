import Flutter
import UIKit
import VpadnSDKAdKit
import AdSupport

public class VponPluginPocPlugin: NSObject, FlutterPlugin {
    
    var channel: FlutterMethodChannel?
    var manager: VponAdInstanceManager
    var readerWriter: VponFlutterReaderWriter?
    private var nativeAdFactories: [String: VponFlutterNativeAdFactory] = [:]
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let plugin = VponPluginPocPlugin(binaryMessenger: registrar.messenger())
        registrar.publish(plugin)
        
        let readerWriter = VponFlutterReaderWriter()
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
        manager = VponAdInstanceManager(binaryMessenger: binaryMessenger)
    }
    
    public static func registerNativeAdFactory(registry: FlutterPluginRegistry, factoryId: String, nativeAdFactory: VponFlutterNativeAdFactory) -> Bool {
        let pluginClassName = String(describing: VponPluginPocPlugin.self)
        guard let vponPlugin = registry.valuePublished(byPlugin: pluginClassName) as? VponPluginPocPlugin else {
            let reason = String(format: "Could not find a \(pluginClassName) instance. The plugin may have not been registered.")
            NSException(name: .invalidArgumentException, reason: reason).raise()
            return false
        }
        
        if vponPlugin.nativeAdFactories[factoryId] != nil {
            vponPlugin.manager.logToDart("A NativeAdFactory with factoryId: \(factoryId) already exists", type: .error)
            return false
        }
        
        vponPlugin.nativeAdFactories[factoryId] = nativeAdFactory
        return true
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let rootController = self.rootController()
        switch call.method {
            
        case .initializeSDK:
            VponAdConfiguration.shared.initializeSdk()
            result(nil)
            
        case .setLogLevel:
            guard let arg = call.arguments as? [String: Int],
                  let status = arg["level"],
                  let validLevel = VponLogLevel(rawValue: status) else {
                result(FlutterError.invalidArgument)
                return
            }
            VponAdConfiguration.shared.logLevel = validLevel
            result(nil)
            
            
        case ._init:
            manager.disposeAllAds()
            result(nil)
            
        case .getVponID:
            let id = VponAdConfiguration.shared.getVponID()
            result(id)
            
        case .setLocationManagerEnable:
            guard let arg = call.arguments as? [String: Bool],
                  let isEnable = arg["isEnable"] else {
                result(FlutterError.invalidArgument)
                return
            }
            VponAdLocationManager.shared.isEnable = isEnable
            result(nil)
            
        case .setAudioApplicationManaged:
            guard let arg = call.arguments as? [String: Bool],
                  let isManaged = arg["isManaged"] else {
                result(FlutterError.invalidArgument)
                return
            }
            VponAdAudioManager.shared.isAudioApplicationManaged = isManaged
            result(nil)
            
        case .noticeApplicationAudioWillStart:
            VponAdAudioManager.shared.noticeApplicationAudioWillStart()
            result(nil)
            
        case .noticeApplicationAudioDidEnd:
            VponAdAudioManager.shared.noticeApplicationAudioDidEnded()
            result(nil)
            
        case .setConsentStatus:
            guard let arg = call.arguments as? [String: Int],
                  let status = arg["status"],
                  let validStatus = VponConsentStatus(rawValue: status) else {
                result(FlutterError.invalidArgument)
                return
            }
            VponUCB.shared.setConsentStatus(validStatus)
            result(nil)
            
        case .updateRequestConfiguration:
            guard let arg = call.arguments as? [String: Any] else {
                result(FlutterError.invalidArgument)
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
            
        case .getVersionString:
            let version = VponAdConfiguration.sdkVersion()
            result(version)
            
        case .loadInterstitialAd:
            guard let arg = call.arguments as? [String: Any] else {
                result(FlutterError.invalidArgument)
                return
            }
            if let key = arg["licenseKey"] as? String,
               let adId = arg["adId"] as? Int,
               let request = arg["request"] as? VponFlutterAdRequest {
                
                let ad = VponFlutterInterstitialAd(licenseKey: key,
                                                   request: request,
                                                   rootViewController: rootController,
                                                   adId: adId)
                manager.loadAd(ad)
                result(nil)
            } else {
                result(FlutterError.invalidArgument)
            }
            
        case .loadBannerAd:
            guard let arg = call.arguments as? [String: Any] else {
                result(FlutterError.invalidArgument)
                return
            }
            if let key = arg["licenseKey"] as? String,
               let size = arg["size"] as? VponFlutterBannerAdSize,
               let adId = arg["adId"] as? Int,
               let request = arg["request"] as? VponFlutterAdRequest {
                
                let ad = VponFlutterBannerAd(licenseKey: key,
                                             size: size,
                                             request: request,
                                             rootViewController: rootController,
                                             adId: adId)
                manager.loadAd(ad)
                result(nil)
            } else {
                result(FlutterError.invalidArgument)
            }
            
        case .loadNativeAd:
            guard let arg = call.arguments as? [String: Any],
                  let factoryId = arg["factoryId"] as? String else {
                result(FlutterError.invalidArgument)
                return
            }
            
            guard let factory = nativeAdFactories[factoryId] else {
                let message = "Can't find NativeAdFactory with id: \(factoryId)"
                result(FlutterError(code: "NativeAdError", message: message, details: nil))
                return
            }
            
            if let key = arg["licenseKey"] as? String,
               let adId = arg["adId"] as? Int,
               let request = arg["request"] as? VponFlutterAdRequest {
                let nativeAd = VponFlutterNativeAd(licenseKey: key,
                                                   adRequest: request,
                                                   nativeAdFactory: factory,
                                                   rootViewController: rootController,
                                                   adId: adId)
                manager.loadAd(nativeAd)
                result(nil)
            } else {
                result(FlutterError.invalidArgument)
            }
            
        case .disposeAd:
            guard let arg = call.arguments as? [String: Any],
                  let adId = arg["adId"] as? Int else {
                result(FlutterError.invalidArgument)
                return
            }
            manager.dispose(adId: adId)
            result(nil)
            
        case .showAdWithoutView:
            guard let arg = call.arguments as? [String: Any],
                  let adId = arg["adId"] as? Int else {
                result(FlutterError.invalidArgument)
                return
            }
            manager.showAd(adId: adId)
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
