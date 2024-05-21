//
//  VpadnAdAudioManager.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/4/24.
//  Copyright © 2023 com.vpon. All rights reserved.
//

@available(*, deprecated, message: "Use VponAdAudioManager instead.")
@objcMembers public final class VpadnAdAudioManager: NSObject {
    
    /// 是否由 Application 來控制 Audio
    public var isAudioApplicationManaged = false {
        didSet {
            VponAdAudioManager.shared.isAudioApplicationManaged = isAudioApplicationManaged
        }
    }
    
    public static let shared = VpadnAdAudioManager()
    
    /// Application 通知 SDK 即將播放影音或聲音
    public func noticeApplicationAudioWillStart() {
        VponAdAudioManager.shared.noticeApplicationAudioWillStart()
    }
    
    /// Application 通知 SDK 已結束播放影音或聲音
    public func noticeApplicationAudioDidEnded() {
        VponAdAudioManager.shared.noticeApplicationAudioDidEnded()
    }
}
