//
//  VPAdBase.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/4/26.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

class VpadnAdBase {
    
    var identifier: String?
    var adSystem: String?
    var impressions: [VpadnTracking] = []
    var impression = VpadnTracking()
    var pricing = VpadnPricing()
    var viewableImpression = VpadnViewableImpression()
    var errors: [VpadnTracking] = []
    var adVerifications: [VpadnVerification] = []
    var creatives: [VpadnCreative] = []
    var extensions: [VpadnExtension] = []
    var clickThroughURL: URL?
    var clickTrackingURLs = NSMutableArray()
    /// For compatibility sake (code using ios-vast-player's "single" clickTrackingURL)
    var clickTrackingURL: URL?
    var allTrackings: [VpadnTracking] = []
    
    func sendAsynchronousRequest(url: URL) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error {
                VponConsole.log("[InRead] \(#file), \(#function) Error: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    func sendTracking(_ tracking: VpadnTracking) {
        guard let url = tracking.url else { return }
        VponConsole.log("tracking event: \(tracking.event ?? ""), request url: \(url.absoluteString)")
        sendAsynchronousRequest(url: url)
    }
    
    func sendTracking(by event: String) {
        sendTracking(by: event, marco: nil)
    }
    
    func sendTracking(by event: String, marco: [String: Any]?) {
        let predicate = NSPredicate(format: "event == %@", event)
        let filteredArray = allTrackings.filter { predicate.evaluate(with: $0) }
        for tracking in filteredArray {
            if var url = tracking.url {
                if let marcoDic = marco,
                   let strUrl = url.absoluteString.removingPercentEncoding {
                    
                    for (key, value) in marcoDic {
                        if let value = value as? String, !value.isEmpty {
                            let replacedUrl = strUrl.replacingOccurrences(of: key, with: value)
                            if let newURL = URL(string: replacedUrl) {
                                url = newURL
                            } else {
                                continue
                            }
                        } else {
                            continue
                        }
                    }
                }
                sendAsynchronousRequest(url: url)
                VponConsole.log("tracking event: \(tracking.event ?? ""), request url: \(url.absoluteString)")
            }
        }
    }
    
    func getTrackingByEvent(_ event: String) -> [VpadnTracking] {
        let predicate = NSPredicate(format: "event == %@", event)
        return allTrackings.filter { predicate.evaluate(with: $0) }
    }
}

// MARK: - Entity Implementation

class VpadnTracking: NSObject {
    var identifier: String?
    var type: String?
    @objc var event: String? // For NSPredicate to filter
    var url: URL?
    var offset: TimeInterval?
    
    override init() {
        super.init()
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? VpadnTracking {
            return self.identifier == other.identifier
        }
        return false
    }
    
    init(attributes: [String: Any]) {
        
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["url"] = url
        dict["type"] = type
        dict["event"] = event
        dict["identifier"] = identifier
        dict["offset"] = offset
        return dict
    }
}

class VpadnCategory {
    var authority: String?
    
    init(attributes: [String: Any]) {
        
    }
}

class VpadnPricing {
    var pricing: Double?
    var model: String?
    var currency: String?
    
    init() {
        
    }
    
    init(attributes: [String: Any]) {
        
    }
}

class VpadnSurvey {
    var url: URL?
    var type: String?
    
    init(attributes: [String: Any]) {
        
    }
}

class VpadnViewableImpression {
    var identifier: String?
    /// Multiple <viewableURL> elements
    var viewables: [VpadnTracking] = []
    /// Multiple <notViewableURL> elements
    var notViewables: [VpadnTracking] = []
    /// Multiple <viewUndeterminedURL> elements
    var viewUndetermineds: [VpadnTracking] = []
    
    init() {
        
    }
    
    init(attributes: [String: Any]) {
        
    }
}

class VpadnResource {
    var identifier: String?
    var creativeType: String?
    var content: String?
    var apiFramework: String?
    var browserOptional: Bool?
    var url: URL?
    
    init() {
        
    }
    
    init(attributes: [String: Any]) {
        if let urlValue = attributes["url"] as? URL {
            url = urlValue
        }
        identifier = attributes["identifier"] as? String
        creativeType = attributes["creativeType"] as? String
        content = attributes["content"] as? String
        apiFramework = attributes["apiFramework"] as? String
        browserOptional = attributes["browserOptional"] as? Bool
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["url"] = url
        dict["creativeType"] = creativeType
        dict["apiFramework"] = apiFramework
        dict["identifier"] = identifier
        dict["browserOptional"] = browserOptional
        dict["content"] = content
        return dict
    }
}

class VpadnVerification {
    var vendor: String?
    var verificationParameters: String?
    var javaScriptResources: [VpadnResource] = []
    var flashResources: [VpadnResource] = []
    var viewableImpression: VpadnViewableImpression?
    var trackingEvents: [VpadnTracking] = []
    
    init() {
        
    }
    
    func toDictionary() -> [String: Any] {
        var dictionary: [String: Any] = [:]
        dictionary["vendor"] = vendor
        dictionary["verificationParameters"] = verificationParameters
        dictionary["javaScriptResources"] = javaScriptResources.map { $0.toDictionary() }
        dictionary["flashResources"] = flashResources.map { $0.toDictionary() }
        dictionary["viewableImpression"] = viewableImpression
        dictionary["trackingEvents"] = trackingEvents.map { $0.toDictionary() }
        
        return dictionary
    }
}

class VpadnUniversalAdId {
    var identifier: String?
    var idRegistry: String?
    var idValue: String?
    
    init() {
        
    }
    
    init(attributes: [String: Any]) {
        
    }
}

class VpadnAdParameters {
    var data: String?
    var xmlEncode: String?
    
    init() {
        
    }
    
    init(attributes: [String: Any]) {
        
    }
}

class VpadnMediaFile {
    var url: URL?
    var identifier: String?
    var delivery: String?
    var type: String?
    var codec: String?
    var apiFramework: String?
    var bitrate: Double?
    var minBitrate: Double?
    var maxBitrate: Double?
    var width: Float?
    var height: Float?
    var mantainAspectRatio: Bool?
    var scalable: Bool?
    
    init() {
        
    }
    
    init(attributes: [String: Any]) {
        
    }
}

class VpadnClick {
    var identifier: String?
    var clickThrough: URL?
    /// Multiple <VpadnTracking> elements
    var clickTracking: [VpadnTracking] = []
    /// Multiple <VpadnTracking> elements
    var customClick: [VpadnTracking] = []
    
    init() {
        
    }
    
    init(attributes: [String: Any]) {
        
    }
}

class VpadnIcon {
    var identifier: String?
    var program: String?
    var xPosition: Float?
    var yPosition: Float?
    var width: Float?
    var height: Float?
    var duration: Double?
    var offset: Double?
    var pxratio: Double?
    var apiFramework: String?
    var iconClicks = VpadnClick()
    /// Multiple <VpadnTracking> elements
    var iconViewTracking: [VpadnTracking] = []
    var staticResource = VpadnResource()
    var iFrameResource = VpadnResource()
    var htmlResource = VpadnResource()
    
    init(attributes: [String: Any]) {
        
    }
}

class VpadnLinear {
    var identifier: String?
    var skipoffset: Double?
    var duration: TimeInterval?
    var adParameters = VpadnAdParameters()
    /// Multiple <VpadnMediaFile> elements
    var mediaFiles: [VpadnMediaFile] = []
    /// Multiple <VpadnTracking> elements
    var trackingEvents: [VpadnTracking] = []
    /// Multiple <VpadnIcon> elements
    var icons: [VpadnIcon] = []
    var videoClicks = VpadnClick()
    
    init() {
        
    }
    
    init(attributes: [String: Any]) {
        
    }
}

class VpadnNonLinearAd {
    var identifier: String?
    var nonLinear = VpadnClick()
    /// Multiple <VpadnTracking> elements
    var trackingEvents: [VpadnTracking] = []
    
    init() {
        
    }
    
    init(attributes: [String: Any]) {
        
    }
}

class VpadnCompanion: VpadnClick {
    var expandedWidth: Float?
    var expandedHeight: Float?
    var assetWidth: Float?
    var assetHeight: Float?
    var width: Float?
    var height: Float?
    var pxratio: Double?
    var program: String?
    var apiFramework: String?
    var adSlotID: String?
    var altText: String?
    /// Multiple <VpadnTracking> elements
    var trackingEvents: [VpadnTracking] = []
    var adParameters = VpadnAdParameters()
    var staticResource = VpadnResource()
    var iFrameResource = VpadnResource()
    var htmlResource = VpadnResource()
    
    override init() {
        super.init()
    }
    
    override init(attributes: [String: Any]) {
        super.init(attributes: attributes)
    }
}

class VpadnCreative {
    var identifier: String?
    var sequence: Double?
    var adId: String?
    var apiFramework: String?
    var universalAdId = VpadnUniversalAdId()
    var linear = VpadnLinear()
    var nonLinearAds = VpadnNonLinearAd()
    var companionAds = VpadnCompanion()
    
    init() {
        
    }
    
    init(attributes: [String: Any]) {
        
    }
}

class VpadnExtension {
    var type: String?
    var adVerifications = [VpadnVerification]()
  
    init() {
        
    }
    
    init(attributes: [String: Any]) {
        
    }
}
