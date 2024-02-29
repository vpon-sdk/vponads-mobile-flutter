//
//  VPAdConfiguration.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/4/24.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

@available(*, deprecated, message: "Use VponLogLevel instead.")
@objc public enum VpadnLogLevel: Int {
    case debug = 0
    case defaultLevel = 1
    case dontShow = 99
}

@available(*, deprecated, message: "Use VponAdConfiguration instead.")
@objcMembers public final class VpadnAdConfiguration: NSObject {
    
    public var logLevel: VpadnLogLevel = .defaultLevel {
        didSet {
            // Call v5.6 interface
            switch logLevel {
            case .debug:
                VponAdConfiguration.shared.logLevel = .debug
            case .defaultLevel:
                VponAdConfiguration.shared.logLevel = .default
            case .dontShow:
                VponAdConfiguration.shared.logLevel = .dontShow
            }
        }
    }
 
    public var audioManager = VpadnAdAudioManager.shared
    public var locationManager = VpadnAdLocationManager.shared
    public static let shared = VpadnAdConfiguration()
    
    public func initializeSdk() {
        // Call v5.6 interface
        VponAdConfiguration.shared.initializeSdk()
    }
    
    public class func sdkVersion() -> String {
        return SDK_PLATFORM.appending(SDK_VERSION)
    }
}
