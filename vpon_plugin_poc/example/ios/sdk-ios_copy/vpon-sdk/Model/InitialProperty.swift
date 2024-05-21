//
//  InitialProperty.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/3/29.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import WebKit

struct OrientationProperty {
    
    var forceOrientation: VponForceOrientation = .portrait
    var allowOrientationChange: Bool = false
    
    mutating func updateWithData(_ data: [String: Any]) {
        if let allow = data["allowOrientationChange"] as? Bool {
            allowOrientationChange = allow
        }
        if let orientation = data["forceOrientation"] as? String {
            switch orientation {
            case "portrait":
                forceOrientation = .portrait
            case "landscape":
                forceOrientation = .landscape
            default:
                forceOrientation = .none
            }
        }
    }
}

struct ExpandProperty {
    
    var width: CGFloat = 0
    var height: CGFloat = 0
    var isModal: Bool = true
    var useCustomClose: Bool = false
    
    mutating func updateWithData(_ data: [String: Any]) {
        width = data["width"] as? CGFloat ?? 0
        height = data["height"] as? CGFloat ?? 0
        isModal = data["isModal"] as? Bool ?? true
        useCustomClose = data["useCustomClose"] as? Bool ?? false
    }
}

struct InitialProperty {
    
    var expandProperty = ExpandProperty()
    var orientationProperty = OrientationProperty()
    
    mutating func update(with message: WKScriptMessage) {
        guard let body = message.body as? String else { return }
        let data = JsonParseHelper.jsonToDictionary(with: body)
        if let expand = data["expandProperties"] as? [String: Any] {
            expandProperty.updateWithData(expand)
        }
        if let orientation = data["orientationProperties"] as? [String: Any] {
            orientationProperty.updateWithData(orientation)
        }
    }
}
