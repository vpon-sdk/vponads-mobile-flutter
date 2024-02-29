//
//  VponEnumeration.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/10/2.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

enum VponMediaSource {
    case none
    case native
}

enum VponLogTag: String {
    case debug = "[DEBUG]"
    case info = "[INFO]"
    case warning = "[WARNING]"
    case error = "[ERROR]"
    case note = "[NOTE]"
}

enum VponPlacementType: Int {
    case inline = 0
    case interstitial
}


enum VponReceivedState: Int {
    case failed = 0
    case success
    case none
}

enum VponForceOrientation {
    case portrait
    case landscape
    case none
}





// InRead
enum VponPlayerState {
    case buffering
    case loaded
    case playing
    case stopped
    case pause
    case failed
}
