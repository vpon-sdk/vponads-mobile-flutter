//
//  VponAdObstruction.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/10/3.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

@objc public enum VponFriendlyObstructionType: Int {
    case mediaControls = 0
    case closeAd
    case notVisible
    case other
}

@objcMembers public final class VponAdObstruction: NSObject {
    
    public weak var view: UIView?
    public var purpose: VponFriendlyObstructionType = .other
    public var desc = ""
    
    // For admob adapter use
    @objc public class func getVponPurpose(_ int: Int) -> VponFriendlyObstructionType {
        switch int {
        case 0:
            return VponFriendlyObstructionType.mediaControls
        case 1:
            return VponFriendlyObstructionType.closeAd
        case 2:
            return VponFriendlyObstructionType.notVisible
        default:
            return VponFriendlyObstructionType.other
        }
    }
    
    internal func getPurposeString() -> String {
        switch purpose {
        case .mediaControls:
            return "OTHER"
        case .closeAd:
            return "CLOSE_AD"
        case .notVisible:
            return "NOT_VISIBLE"
        case .other:
            return "VIDEO_CONTROLS"
        }
    }
    
    internal func getOMIDPurpose() -> OMIDFriendlyObstructionType {
        switch purpose {
        case .mediaControls:
            return .mediaControls
        case .closeAd:
            return .closeAd
        case .notVisible:
            return .notVisible
        case .other:
            return .other
        }
    }
}
