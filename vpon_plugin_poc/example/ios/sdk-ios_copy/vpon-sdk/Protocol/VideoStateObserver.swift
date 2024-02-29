//
//  VideoStateObserver.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/11/21.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

/// 監聽影片播放進度（目前只有 Native ad 使用）
protocol VideoStateObserver: AnyObject {
    var videoStateManager: VideoStateManager? { get }
    func receive(_ event: VideoState, data: [String: Any]?)
}
