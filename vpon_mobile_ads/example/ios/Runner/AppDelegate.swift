import UIKit
import vpon_mobile_ads
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        
        let nativeAdFactory = NativeAdFactory()
        let _ = VponMobileAdsPlugin.registerNativeAdFactory(registry: self, factoryId: "VponNativeAdFactory", nativeAdFactory: nativeAdFactory)
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
