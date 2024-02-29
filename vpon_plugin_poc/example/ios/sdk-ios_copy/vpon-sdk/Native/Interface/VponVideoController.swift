//
//  VponVideoController.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/10/30.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

@objc public protocol VponVideoControllerDelegate: AnyObject {
    /// 通知 video ad 影片開始播放
    @objc optional func videoControllerDidPlayVideo(_ videoController: VponVideoController)
    /// 通知 video ad 影片暫停播放
    @objc optional func videoControllerDidPauseVideo(_ videoController: VponVideoController)
    /// 通知 video ad 影片播放完畢
    @objc optional func videoControllerDidEndVideoPlayback(_ videoController: VponVideoController)
    /// 通知 video ad 影片被靜音
    @objc optional func videoControllerDidMuteVideo(_ videoController: VponVideoController)
    /// 通知 video ad 影片被取消靜音
    @objc optional func videoControllerDidUnmuteVideo(_ videoController: VponVideoController)
}

@objcMembers public final class VponVideoController: NSObject {
    
    public weak var delegate: VponVideoControllerDelegate?
    
    internal func notifyVideoDidPlay() {
        delegate?.videoControllerDidPlayVideo?(self)
    }
    
    internal func notifyVideoDidPause() {
        delegate?.videoControllerDidPauseVideo?(self)
    }
    
    internal func notifyVideoDidEndVideoPlayback() {
        delegate?.videoControllerDidEndVideoPlayback?(self)
    }
    
    internal func notifyVideoDidMute() {
        delegate?.videoControllerDidMuteVideo?(self)
    }
    
    internal func notifyVideoDidUnmute() {
        delegate?.videoControllerDidUnmuteVideo?(self)
    }
}
