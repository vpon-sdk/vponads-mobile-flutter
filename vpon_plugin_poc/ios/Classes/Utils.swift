//
//  Utils.swift
//  vpon_plugin_poc
//
//  Created by vponinc on 2024/1/31.
//

import Foundation
import OSLog

struct Constant {
    /// "plugins.flutter.io/vpon"
    static let channelName = "plugins.flutter.io/vpon"
    static let adId = "adId"
    static let onAdEvent = "onAdEvent"
    static let eventName = "eventName"
    static let loadAdError = "loadAdError"
    static let errorDescription = "errorDescription"
    static let errorCode = "errorCode"
}

struct Console {
    
    static func log(_ message: String, type: OSLogType = .debug) {
        print("<Plugin> [iOS Native] \(message)")
//        os_log("<Plugin> [iOS Native] %@", log: .default, type: type , message)
    }
}
