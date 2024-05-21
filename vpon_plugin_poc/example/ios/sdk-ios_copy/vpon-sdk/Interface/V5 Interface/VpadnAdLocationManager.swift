//
//  VpadnAdLocationManager.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/4/14.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import CoreLocation

@available(*, deprecated, message: "Use VponAdLocationManager instead.")
@objcMembers public final class VpadnAdLocationManager: NSObject {
    
    public static let shared = VpadnAdLocationManager()
    
    /// SDK 是否能使用 Location
    public var isEnable: Bool {
        didSet {
            // Call v5.6 interface
            VponAdLocationManager.shared.isEnable = isEnable
        }
    }
    
    
    private override init() {
        isEnable = true
        super.init()
    }
}
