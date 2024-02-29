//
//  NativeGestureRecognizer.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/11/28.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

final class NativeGestureRecognizer: UITapGestureRecognizer {

    public override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        
        self.numberOfTapsRequired = 1
        self.numberOfTouchesRequired = 1
    }
}
