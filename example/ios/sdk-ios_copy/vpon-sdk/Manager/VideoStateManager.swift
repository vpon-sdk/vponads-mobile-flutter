//
//  VideoStateManager.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/11/9.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

enum VideoState: CaseIterable {
    case onVideoPause
    case onVideoResume
    case onVideoBufferStart
    case onVideoBufferFinish
    case onVideoStart
    case onVideoFirstQuartile
    case onVideoMidPoint
    case onVideoThirdQuartile
    case onVideoComplete
    case onVideoVolumeChange
    
    case onChangeToFullScreen
    case onChangeToNormal
}

final class VideoStateManager: EventObservable {
    
    typealias Observer = VideoStateObserver
    typealias Event = VideoState
    
    private lazy var observers = [VideoState: [VideoStateObserver]]()
    
    func register(_ observer: VideoStateObserver, _ event: VideoState) {
        guard !(observers[event]?.contains(where: { $0 === observer }) ?? false) else { return } // avoid duplicates
        
        if observers[event] != nil {
            observers[event]?.append(observer)
            return
        }
        observers[event] = [observer]
    }
    
    func unregister(_ observer: VideoStateObserver, _ event: VideoState) {
        observers[event]?.removeAll(where: { $0 === observer })
    }
    
    func unregisterAllEvents(_ observer: VideoStateObserver) {
        VponConsole.log("VideoStateManager unregisterAllEvents from \(observer)")
        for (event, _) in observers {
            unregister(observer, event)
        }
    }
    
    func notify(_ event: VideoState, data: [String: Any]? = nil) {
        guard let observers = observers[event] else { return }
        VponConsole.log("[VideoStateManager] \(event)")
        for observer in observers {
            observer.receive(event, data: data)
        }
    }
    
    // MARK: - Deinit
    
    deinit {
        VponConsole.log("[ARC] VideoStateManager deinit")
    }
}
