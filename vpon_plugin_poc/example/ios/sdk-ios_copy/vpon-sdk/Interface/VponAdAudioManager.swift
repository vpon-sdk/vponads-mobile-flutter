//
//  VponAdAudioManager.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/10/25.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import AVKit

@objcMembers public final class VponAdAudioManager: NSObject {
    
    /// 是否由 Application 來控制 Audio
    public var isAudioApplicationManaged = false {
        didSet {
            VponConsole.log("[SDK-Initialization] IsAudioApplicationManaged: \(isAudioApplicationManaged)", .info)
        }
    }
    
    public static let shared = VponAdAudioManager()
    private var session: AVAudioSession = AVAudioSession.sharedInstance()
    
    /// Application 通知 SDK 即將播放影音或聲音
    public func noticeApplicationAudioWillStart() {
        isAudioApplicationManaged = true
    }
    
    /// Application 通知 SDK 已結束播放影音或聲音
    public func noticeApplicationAudioDidEnded() {
        isAudioApplicationManaged = false
        setCategoryAndMixOthers()
        setActive(true)
    }
    
    internal func setCategoryAndMixOthers() {
        if isAudioApplicationManaged { return }
        VponConsole.log("[SDK-Initialization] AudioSession category playback and mix with others invoked.")
        try? session.setCategory(.playback, options: .mixWithOthers)
    }
    
    internal func setActive(_ active: Bool) {
        if isAudioApplicationManaged { return }
        VponConsole.log("[SDK-Initialization] AudioSession setActive: \(active)")
        try? session.setActive(active)
    }
}
