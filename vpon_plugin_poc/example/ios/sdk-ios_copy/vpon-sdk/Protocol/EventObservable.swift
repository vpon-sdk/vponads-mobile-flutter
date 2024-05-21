//
//  EventObservable.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/11/9.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

/// 自製用來收發監聽事件的協定
protocol EventObservable: AnyObject {
    associatedtype Observer
    associatedtype Event
    
    func register(_ observer: Observer, _ event: Event)
    func unregister(_ observer: Observer, _ event: Event)
    func notify(_ event: Event, data: [String: Any]?)
}
