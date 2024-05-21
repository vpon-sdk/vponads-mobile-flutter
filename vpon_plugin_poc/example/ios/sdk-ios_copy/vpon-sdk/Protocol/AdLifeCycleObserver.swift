//
//  AdLifeCycleObserver.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/10/24.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

protocol AdLifeCycleObserver: AnyObject {
    var adLifeCycleManager: AdLifeCycleManager? { get }
    func receive(_ event: AdLifeCycle, data: [String: Any]?)
}
