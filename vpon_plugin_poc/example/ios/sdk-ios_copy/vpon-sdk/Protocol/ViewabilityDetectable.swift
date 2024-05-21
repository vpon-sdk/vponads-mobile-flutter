//
//  ViewabilityDetectable.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/10/3.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

/// 可執行遮蔽偵測
protocol ViewabilityDetectable {
    /// 負責遮蔽偵測的物件
    var viewabilityDetector: ViewabilityDetector? { get }
}
