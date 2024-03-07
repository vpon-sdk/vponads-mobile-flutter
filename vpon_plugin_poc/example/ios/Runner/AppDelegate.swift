import UIKit
import vpon_plugin_poc
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        
        let nativeAdFactory = NativeAdFactory()
        VponPluginPocPlugin.registerNativeAdFactory(registry: self, factoryId: "adFactoryExample", nativeAdFactory: nativeAdFactory)
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
