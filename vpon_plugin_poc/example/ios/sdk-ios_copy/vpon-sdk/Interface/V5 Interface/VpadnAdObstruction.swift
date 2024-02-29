//
//  VpadnAdObstruction.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/3/31.
//  Copyright © 2023 com.vpon. All rights reserved.
//

@available(*, deprecated, message: "Use VponAdObstruction instead.")
@objcMembers public final class VpadnAdObstruction: NSObject {
    
    public weak var view: UIView?
    public var purpose: VpadnFriendlyObstructionType = .other
    public var desc = ""
    
    func getPurposeString() -> String {
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
    
    func getOMIDPurpose() -> OMIDFriendlyObstructionType {
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
