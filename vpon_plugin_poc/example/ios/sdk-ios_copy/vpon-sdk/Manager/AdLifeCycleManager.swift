//
//  AdLifeCycleManager.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/10/12.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

enum AdLifeCycle: CaseIterable {
    case onAdLoaded
    case onAdFailedToLoad
    case onAdShow
    case onAdImpression
    case onAdClicked // 同個廣告只有第一次點擊時觸發
    case onAdOpened // 點擊廣告 open browser 時觸發，對應到 MRAID open()
    case onAdDestroyed
}

final class AdLifeCycleManager: EventObservable {
    
    typealias Observer = AdLifeCycleObserver
    typealias Event = AdLifeCycle
    
    private lazy var observers = [AdLifeCycle: [AdLifeCycleObserver]]()
    
    func register(_ observer: AdLifeCycleObserver, _ event: AdLifeCycle) {
        guard !(observers[event]?.contains(where: { $0 === observer }) ?? false) else { return } // avoid duplicates
        
        if observers[event] != nil {
            observers[event]?.append(observer)
            return
        }
        observers[event] = [observer]
    }
    
    func unregister(_ observer: AdLifeCycleObserver, _ event: AdLifeCycle) {
        observers[event]?.removeAll(where: { $0 === observer })
    }
    
    func unregisterAllEvents(_ observer: AdLifeCycleObserver) {
        VponConsole.log("AdLifeCycleManager unregisterAllEvents from \(observer)")
        for (event, _) in observers {
            unregister(observer, event)
        }
    }
    
    func notify(_ event: AdLifeCycle, data: [String: Any]? = nil) {
        VponConsole.log("[AdLifeCycleManager] \(event)")
        guard let observers = observers[event] else { return }
        for observer in observers {
            observer.receive(event, data: data)
        }
    }
    
    // MARK: - Deinit
    
    deinit {
        VponConsole.log("[ARC] AdLifeCycleManager deinit")
    }
}
