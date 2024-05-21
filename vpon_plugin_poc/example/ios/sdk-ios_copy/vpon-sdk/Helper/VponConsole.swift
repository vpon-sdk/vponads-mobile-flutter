//
//  VponConsole.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/10/25.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation
import OSLog

struct VponConsole {
    
    /// 打印 Console Log
    /// - Parameter message: 要印出的文字
    static func log(_ message: String) {
        log(message, .debug)
    }
    
    /// 打印 Console Log
    /// - Parameters:
    ///   - message: 要印出的文字
    ///   - type: Log Level
    static func log(_ message: String, _ type: VponLogTag) {
        let logLevel = VponAdConfiguration.shared.logLevel
        if logLevel == .dontShow { return }
        
        var osLogType: OSLogType
        
        switch type {
        case .warning:
            osLogType = .info
            os_log("<VPON> %@ %@", log: .default, type: osLogType, type.rawValue , message)
          
        case .info:
            osLogType = .info
            os_log("<VPON> %@ %@", log: .default, type: osLogType, type.rawValue , message)
            
        case .error:
            osLogType = .error
            os_log("<VPON> %@ %@", log: .default, type: osLogType, type.rawValue , message)
        
        case .note:
            osLogType = .info
            os_log("<VPON> %@ %@", log: .default, type: osLogType, type.rawValue , message)
        
        case .debug:
            guard logLevel == .debug else { return }
            osLogType = .default
            os_log("<VPON> %@ %@", log: .default, type: osLogType, type.rawValue , message)
        }
    }
    
    /// SDK Note Log
    static func note() {
        VponConsole.log("SDK Version: \(SDK_VERSION)", .note)
        VponConsole.log("Build Date: \(BUILD_NUMBER)", .note)
        VponConsole.log("IDFA: \(DeviceInfo.shared.getAdvertisingIdentifier())", .note)
    }
}
