//
//  VpadnAdParser.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/4/28.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

protocol VpadnAdParserDelegate: AnyObject {
    func vpadnAdParserDidFinish(ad: VpadnAdVast)
    func vpadnAdGetWrapperDidError(ad: VpadnAdVast)
    func vpadnAdGetWrapperDidTimeOut(ad: VpadnAdVast)
    func vpadnAdOverWrapperLimit(ad: VpadnAdVast)
}

class VpadnAdParser: NSObject {
    
    // MARK: - Attributes from Video Ad Serving Template (iab)
    
    private let ATTRIBUTE_ID = "id"
    private let ATTRIBUTE_VENDOR = "vendor"
    private let ATTRIBUTE_SEQUENCE = "sequence"
    private let ATTRIBUTE_EVENT = "event"
    private let ATTRIBUTE_OFFSET = "offset"
    private let ATTRIBUTE_EXPANDEDWIDTH = "expandedWidth"
    private let ATTRIBUTE_EXPANDEDHEIGHT = "expandedHeight"
    private let ATTRIBUTE_ASSET_WIDTH = "assetWidth"
    private let ATTRIBUTE_ASSET_HEIGHT = "assetHeight"
    private let ATTRIBUTE_HEIGHT = "height"
    private let ATTRIBUTE_WIDTH = "width"
    private let ATTRIBUTE_PXRATIO = "pxratio"
    private let ATTRIBUTE_AD_SLOT_ID = "adSlotID"
    private let ATTRIBUTE_ALT_TEXT = "altText"
    private let ATTRIBUTE_API_FRAMEWORK = "apiFramework"
    private let ATTRIBUTE_CREATIVE_TYPE = "creativeType"
    private let ATTRIBUTE_XML_ENCODED = "xmlEncoded"
    private let ATTRIBUTE_AUTHORITY = "authority"
    private let ATTRIBUTE_MODEL = "model"
    private let ATTRIBUTE_CURRENCY = "currency"
    private let ATTRIBUTE_BITRATE = "bitrate"
    private let ATTRIBUTE_PROGRESSIVE = "progressive"
    private let ATTRIBUTE_SCALABLE = "scalable"
    private let ATTRIBUTE_TYPE = "type"
    private let ATTRIBUTE_BROWSER_OPTIONAL = "browserOptional"
    
    private let ATTRIBUTE_MAINTAIN_ASPECT_RATIO = "maintainAspectRatio"
    
    
    // MARK: - Properties
    
    private let VpadnVideoAdParserErrorDomain = "VpadnVideoAdParserErrorDomain"
    private weak var delegate: VpadnAdParserDelegate?
    private var vpadnAdVast: VpadnAdVast = VpadnAdVast()
    private var vpadnAdInline: VpadnAdInline?
    private var vpadnAdWrapper: VpadnAdWrapper?
    private var isWrapper: Bool?
    private var currentPath: String = ""
    
    // MARK: - Methods
    
    func parserVast(withXml document: String, delegate: VpadnAdParserDelegate) {
        self.delegate = delegate
        parse(document)
    }
    
    private func parse(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
    }
    
    private func getXmlDocument(adTagURL: URL?) {
        guard let adTagURL else {
            getWrapperError()
            return
        }
        
        var request = URLRequest(url: adTagURL)
        request.timeoutInterval = 30
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }
            if (error != nil) || data == nil {
                if (error as? NSError)?.code == -1001 {
                    self.getWrapperTimeout()
                } else {
                    self.getWrapperError()
                }
            } else {
                let parser = XMLParser(data: data!)
                parser.delegate = self
                parser.parse()
            }
        }.resume()
    }
    
    // MARK: - Error handle
    
    private func getWrapperError() {
        delegate?.vpadnAdGetWrapperDidError(ad: vpadnAdVast)
    }
    
    private func overWrapperLimit() {
        delegate?.vpadnAdOverWrapperLimit(ad: vpadnAdVast)
    }
    
    private func getWrapperTimeout() {
        delegate?.vpadnAdGetWrapperDidTimeOut(ad: vpadnAdVast)
    }
    
    // MARK: - Helper
    
    private func secondsForTimeString(_ string: String) -> Int {
        let components = string.components(separatedBy: ":")
        let hours = Int(components[0]) ?? 0
        let minutes = Int(components[0]) ?? 0
        let seconds = Int(components[0]) ?? 0
        return (hours * 60 * 60) + (minutes * 60) + seconds
    }
}

// MARK: - XMLParserDelegate

extension VpadnAdParser: XMLParserDelegate {
    // 文檔開始的時候觸發
    func parserDidStartDocument(_ parser: XMLParser) {
//        VPSDKHelper.log("\(#file), \(#function)")
    }
    
    // 文檔出錯的時候觸發
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        getWrapperError()
    }
    
    // 遇到一個開始標籤的時候觸發
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        guard !elementName.isEmpty else { return }
        
        currentPath = elementName.appending(":\(currentPath)")
        
//        VPSDKHelper.log("\(#file), \(#function) >------------------------------------------------------------")
//        VPSDKHelper.log("\(#file), \(#function) Current Path: \(currentPath)")
//        VPSDKHelper.log("\(#file), \(#function) AttributeDict: \(attributeDict)\n")
        
        switch currentPath {
        case "Wrapper:Ad:VAST:":
            isWrapper = true
            let temp = VpadnAdWrapper()
            temp.identifier = attributeDict[ATTRIBUTE_ID] ?? ""
            vpadnAdWrapper = temp
            
        case "Impression:Wrapper:Ad:VAST:":
            let temp = VpadnTracking()
            temp.identifier = attributeDict[ATTRIBUTE_ID] ?? ""
            temp.event = "impression"
            vpadnAdWrapper?.impressions.append(temp)
            
        case "ViewableImpression:Wrapper:Ad:VAST:":
            if let id = attributeDict[ATTRIBUTE_ID] {
                vpadnAdWrapper?.viewableImpression.identifier = id
            }
            
        case "Viewable:ViewableImpression:Wrapper:Ad:VAST:":
            let temp = VpadnTracking()
            temp.event = "viewable"
            vpadnAdWrapper?.viewableImpression.viewables.append(temp)
            
        case "NotViewable:ViewableImpression:Wrapper:Ad:VAST:":
            let temp = VpadnTracking()
            temp.event = "notViewable"
            vpadnAdWrapper?.viewableImpression.viewables.append(temp)
            
        case "ViewUndetermined:ViewableImpression:Wrapper:Ad:VAST:":
            let temp = VpadnTracking()
            temp.event = "viewUndetermined"
            vpadnAdWrapper?.viewableImpression.viewables.append(temp)
            
        case "Verification:AdVerifications:Wrapper:Ad:VAST:":
            let temp = VpadnVerification()
            temp.vendor = attributeDict[ATTRIBUTE_VENDOR] ?? ""
            vpadnAdWrapper?.adVerifications.append(temp)
            
        case "Viewable:ViewableImpression:Verification:AdVerifications:Wrapper:Ad:VAST:":
            let verification = vpadnAdWrapper?.adVerifications.last
            let temp = VpadnTracking()
            temp.event = "viewable"
            verification?.viewableImpression?.viewables.append(temp)
            
        case "NotViewable:ViewableImpression:Verification:AdVerifications:Wrapper:Ad:VAST:":
            let verification = vpadnAdWrapper?.adVerifications.last
            let temp = VpadnTracking()
            temp.event = "notViewable"
            verification?.viewableImpression?.notViewables.append(temp)
            
        case "ViewUndetermined:ViewableImpression:Verification:AdVerifications:Wrapper:Ad:VAST:":
            let verification = vpadnAdWrapper?.adVerifications.last
            let temp = VpadnTracking()
            temp.event = "viewUndetermined"
            verification?.viewableImpression?.viewUndetermineds.append(temp)
            
        case "Creative:Creatives:Wrapper:Ad:VAST:":
            let temp = VpadnCreative()
            temp.identifier = attributeDict[ATTRIBUTE_ID] ?? ""
            if let sequence = attributeDict[ATTRIBUTE_SEQUENCE], let double = Double(sequence) {
                temp.sequence = double
            }
            vpadnAdWrapper?.creatives.append(temp)
            
        case "Tracking:TrackingEvents:Linear:Creative:Creatives:Wrapper:Ad:VAST:":
            let creative = vpadnAdWrapper?.creatives.last
            let temp = VpadnTracking()
            temp.event = attributeDict[ATTRIBUTE_EVENT]
            let parser = VpadnTimeIntervalFormatter()
            if let offset = attributeDict[ATTRIBUTE_OFFSET] {
                temp.offset = parser.timeInterval(with: offset)
            }
            creative?.linear.trackingEvents.append(temp)
            
        case "ClickTracking:VideoClicks:Linear:Creative:Creatives:Wrapper:Ad:VAST:":
            let creative = vpadnAdWrapper?.creatives.last
            let temp = VpadnTracking()
            temp.identifier = attributeDict[ATTRIBUTE_ID] ?? ""
            temp.event = "clickTracking"
            creative?.linear.videoClicks.clickTracking.append(temp)
            
        case "CustomClick:VideoClicks:Linear:Creative:Creatives:Wrapper:Ad:VAST:":
            let creative = vpadnAdWrapper?.creatives.last
            let temp = VpadnTracking()
            temp.identifier = attributeDict[ATTRIBUTE_ID] ?? ""
            temp.event = "customClick"
            creative?.linear.videoClicks.customClick.append(temp)
            
        case "Companion:CompanionAds:Creative:Creatives:Wrapper:Ad:VAST:":
            let creative = vpadnAdWrapper?.creatives.last
            creative?.companionAds.identifier = attributeDict[ATTRIBUTE_ID] ?? ""
            creative?.companionAds.expandedWidth = Float(attributeDict[ATTRIBUTE_EXPANDEDWIDTH] ?? "0")
            creative?.companionAds.expandedHeight = Float(attributeDict[ATTRIBUTE_EXPANDEDHEIGHT] ?? "0")
            creative?.companionAds.assetWidth = Float(attributeDict[ATTRIBUTE_ASSET_WIDTH] ?? "0")
            creative?.companionAds.assetHeight = Float(attributeDict[ATTRIBUTE_ASSET_HEIGHT] ?? "0")
            creative?.companionAds.height = Float(attributeDict[ATTRIBUTE_HEIGHT] ?? "0")
            creative?.companionAds.width = Float(attributeDict[ATTRIBUTE_WIDTH] ?? "0")
            creative?.companionAds.pxratio = Double(attributeDict[ATTRIBUTE_PXRATIO] ?? "0")
            creative?.companionAds.adSlotID = attributeDict[ATTRIBUTE_AD_SLOT_ID] ?? ""
            creative?.companionAds.altText = attributeDict[ATTRIBUTE_ALT_TEXT] ?? ""
            creative?.companionAds.apiFramework = attributeDict[ATTRIBUTE_API_FRAMEWORK] ?? ""
            
        case "StaticResource:Companion:CompanionAds:Creative:Creatives:Wrapper:Ad:VAST:":
            let creative = vpadnAdWrapper?.creatives.last
            creative?.companionAds.staticResource.creativeType = attributeDict[ATTRIBUTE_CREATIVE_TYPE] ?? ""
            
        case "AdParameters:Companion:CompanionAds:Creative:Creatives:Wrapper:Ad:VAST:":
            let creative = vpadnAdWrapper?.creatives.last
            creative?.companionAds.adParameters.xmlEncode = attributeDict[ATTRIBUTE_XML_ENCODED] ?? ""
            
        case "CompanionClickTracking:Companion:CompanionAds:Creative:Creatives:Wrapper:Ad:VAST:":
            let creative = vpadnAdWrapper?.creatives.last
            let temp = VpadnTracking()
            temp.identifier = attributeDict[ATTRIBUTE_ID] ?? ""
            temp.event = "clickTracking"
            creative?.companionAds.clickTracking.append(temp)
            
        case "Tracking:TrackingEvents:Companion:CompanionAds:Creative:Creatives:Wrapper:Ad:VAST:":
            let creative = vpadnAdWrapper?.creatives.last
            let temp = VpadnTracking()
            temp.event = attributeDict[ATTRIBUTE_EVENT] ?? ""
            let parser = VpadnTimeIntervalFormatter()
            if let offset = attributeDict[ATTRIBUTE_OFFSET] {
                temp.offset = parser.timeInterval(with: offset)
            }
            creative?.companionAds.trackingEvents.append(temp)
            
        case "InLine:Ad:VAST:":
            isWrapper = false
            let temp = VpadnAdInline()
            vpadnAdInline = temp
            
        case "Impression:InLine:Ad:VAST:":
            let temp = VpadnTracking()
            temp.identifier = attributeDict[ATTRIBUTE_ID] ?? ""
            temp.event = "impression"
            vpadnAdInline?.impressions.append(temp)
            
        case "ViewableImpression:InLine:Ad:VAST:":
            vpadnAdInline?.viewableImpression.identifier = attributeDict[ATTRIBUTE_ID] ?? ""
            
        case "Viewable:ViewableImpression:InLine:Ad:VAST:":
            let temp = VpadnTracking()
            temp.event = "viewable"
            vpadnAdInline?.viewableImpression.viewables.append(temp)
            
        case "NotViewable:ViewableImpression:InLine:Ad:VAST:":
            let temp = VpadnTracking()
            temp.event = "notViewable"
            vpadnAdInline?.viewableImpression.notViewables.append(temp)
            
        case "ViewUndetermined:ViewableImpression:InLine:Ad:VAST:":
            let temp = VpadnTracking()
            temp.event = "viewUndetermined"
            vpadnAdInline?.viewableImpression.viewUndetermineds.append(temp)
            
        case "Verification:AdVerifications:InLine:Ad:VAST:":
            let temp = VpadnVerification()
            temp.vendor = attributeDict[ATTRIBUTE_VENDOR] ?? ""
            vpadnAdInline?.adVerifications.append(temp)
            
        case "JavaScriptResource:Verification:AdVerifications:InLine:Ad:VAST:":
            let verification = vpadnAdInline?.adVerifications.last
            let temp = VpadnResource()
            temp.apiFramework = attributeDict[ATTRIBUTE_API_FRAMEWORK] ?? ""
            verification?.javaScriptResources.append(temp)
            
        case "FlashResource:Verification:AdVerifications:InLine:Ad:VAST:":
            let verification = vpadnAdInline?.adVerifications.last
            let temp = VpadnResource()
            temp.apiFramework = attributeDict[ATTRIBUTE_API_FRAMEWORK] ?? ""
            verification?.flashResources.append(temp)
            
        case "Viewable:ViewableImpression:Verification:AdVerifications:InLine:Ad:VAST:":
            let verification = vpadnAdInline?.adVerifications.last
            let temp = VpadnTracking()
            temp.event = "viewable"
            verification?.viewableImpression?.viewables.append(temp)
            
        case "NotViewable:ViewableImpression:Verification:AdVerifications:InLine:Ad:VAST:":
            let verification = vpadnAdInline?.adVerifications.last
            let temp = VpadnTracking()
            temp.event = "notViewable"
            verification?.viewableImpression?.notViewables.append(temp)
            
        case "ViewUndetermined:ViewableImpression:Verification:AdVerifications:InLine:Ad:VAST:":
            let verification = vpadnAdInline?.adVerifications.last
            let temp = VpadnTracking()
            temp.event = "viewUndetermined"
            verification?.viewableImpression?.viewUndetermineds.append(temp)
            
        case "Category:InLine:Ad:VAST:":
            vpadnAdInline?.category?.authority = attributeDict[ATTRIBUTE_AUTHORITY] ?? ""
            
        case "Pricing:InLine:Ad:VAST:":
            vpadnAdInline?.pricing.model = attributeDict[ATTRIBUTE_MODEL] ?? ""
            vpadnAdInline?.pricing.currency = attributeDict[ATTRIBUTE_CURRENCY] ?? ""
            
        case "Creative:Creatives:InLine:Ad:VAST:":
            let temp = VpadnCreative()
            temp.identifier = attributeDict[ATTRIBUTE_ID] ?? ""
            temp.sequence = Double(attributeDict[ATTRIBUTE_SEQUENCE] ?? "0")
            vpadnAdInline?.creatives.append(temp)
            
        case "Tracking:TrackingEvents:Linear:Creative:Creatives:InLine:Ad:VAST:":
            let creative = vpadnAdInline?.creatives.last
            let temp = VpadnTracking()
            temp.event = attributeDict[ATTRIBUTE_EVENT] ?? ""
            let parser = VpadnTimeIntervalFormatter()
            if let offset = attributeDict[ATTRIBUTE_OFFSET] {
                temp.offset = parser.timeInterval(with: offset)
            }
            creative?.linear.trackingEvents.append(temp)
            
        case "ClickTracking:VideoClicks:Linear:Creative:Creatives:InLine:Ad:VAST:":
            let creative = vpadnAdInline?.creatives.last
            let temp = VpadnTracking()
            temp.identifier = attributeDict[ATTRIBUTE_ID] ?? ""
            temp.event = "clickTracking"
            creative?.linear.videoClicks.clickTracking.append(temp)
            
        case "CustomClick:VideoClicks:Linear:Creative:Creatives:InLine:Ad:VAST:":
            let creative = vpadnAdInline?.creatives.last
            let temp = VpadnTracking()
            temp.identifier = attributeDict[ATTRIBUTE_ID] ?? ""
            temp.event = "customClick"
            creative?.linear.videoClicks.customClick.append(temp)
            
        case "Companion:CompanionAds:Creative:Creatives:InLine:Ad:VAST:":
            let creative = vpadnAdInline?.creatives.last
            creative?.companionAds.identifier = attributeDict[ATTRIBUTE_ID] ?? ""
            creative?.companionAds.expandedWidth = Float(attributeDict[ATTRIBUTE_EXPANDEDWIDTH] ?? "0")
            creative?.companionAds.expandedHeight = Float(attributeDict[ATTRIBUTE_EXPANDEDHEIGHT] ?? "0")
            creative?.companionAds.assetWidth = Float(attributeDict[ATTRIBUTE_ASSET_WIDTH] ?? "0")
            creative?.companionAds.assetHeight = Float(attributeDict[ATTRIBUTE_ASSET_HEIGHT] ?? "0")
            creative?.companionAds.height = Float(attributeDict[ATTRIBUTE_HEIGHT] ?? "0")
            creative?.companionAds.width = Float(attributeDict[ATTRIBUTE_WIDTH] ?? "0")
            creative?.companionAds.pxratio = Double(attributeDict[ATTRIBUTE_PXRATIO] ?? "0")
            creative?.companionAds.adSlotID = attributeDict[ATTRIBUTE_AD_SLOT_ID] ?? ""
            creative?.companionAds.altText = attributeDict[ATTRIBUTE_ALT_TEXT] ?? ""
            creative?.companionAds.apiFramework = attributeDict[ATTRIBUTE_API_FRAMEWORK] ?? ""
            
        case "StaticResource:Companion:CompanionAds:Creative:Creatives:InLine:Ad:VAST:":
            let creative = vpadnAdInline?.creatives.last
            creative?.companionAds.staticResource.creativeType = attributeDict[ATTRIBUTE_CREATIVE_TYPE] ?? ""
            
        case "AdParameters:Companion:CompanionAds:Creative:Creatives:InLine:Ad:VAST:":
            let creative = vpadnAdInline?.creatives.last
            creative?.companionAds.adParameters.xmlEncode = attributeDict[ATTRIBUTE_XML_ENCODED] ?? ""
            
        case "CompanionClickTracking:Companion:CompanionAds:Creative:Creatives:InLine:Ad:VAST:":
            let creative = vpadnAdInline?.creatives.last
            let temp = VpadnTracking()
            temp.identifier = attributeDict[ATTRIBUTE_ID] ?? ""
            temp.event = "companionClickTracking"
            creative?.companionAds.clickTracking.append(temp)
            
        case "Tracking:TrackingEvents:Companion:CompanionAds:Creative:Creatives:InLine:Ad:VAST:":
            let creative = vpadnAdInline?.creatives.last
            let temp = VpadnTracking()
            temp.event = attributeDict[ATTRIBUTE_EVENT] ?? ""
            let parser = VpadnTimeIntervalFormatter()
            if let offset = attributeDict["offset"] {
                temp.offset = parser.timeInterval(with: offset)
            }
            creative?.companionAds.trackingEvents.append(temp)
            
        case "MediaFile:MediaFiles:Linear:Creative:Creatives:InLine:Ad:VAST:":
            let creative = vpadnAdInline?.creatives.last
            let temp = VpadnMediaFile()
            temp.identifier = attributeDict[ATTRIBUTE_ID] ?? ""
            temp.bitrate = Double(attributeDict[ATTRIBUTE_BITRATE] ?? "0")
            temp.delivery = attributeDict[ATTRIBUTE_PROGRESSIVE] ?? ""
            temp.height = Float(attributeDict[ATTRIBUTE_HEIGHT] ?? "0")
            temp.width = Float(attributeDict[ATTRIBUTE_WIDTH] ?? "0")
            temp.mantainAspectRatio = attributeDict[ATTRIBUTE_MAINTAIN_ASPECT_RATIO] == "1" ? true : false
            temp.scalable = attributeDict[ATTRIBUTE_SCALABLE] == "1" ? true : false
            temp.type = attributeDict[ATTRIBUTE_TYPE] ?? ""
            creative?.linear.mediaFiles.append(temp)
            
        case "Extension:Extensions:InLine:Ad:VAST:":
            let temp = VpadnExtension()
            temp.type = attributeDict[ATTRIBUTE_TYPE] ?? ""
            vpadnAdInline?.extensions.append(temp)
            
        case "Verification:AdVerifications:Extension:Extensions:InLine:Ad:VAST:":
            let vpExtension = vpadnAdInline?.extensions.last
            let temp = VpadnVerification()
            temp.vendor = attributeDict[ATTRIBUTE_VENDOR] ?? ""
            vpExtension?.adVerifications.append(temp)
            
        case "JavaScriptResource:Verification:AdVerifications:Extension:Extensions:InLine:Ad:VAST:":
            let vpExtension = vpadnAdInline?.extensions.last
            let verification = vpExtension?.adVerifications.last
            let temp = VpadnResource()
            temp.apiFramework = attributeDict[ATTRIBUTE_API_FRAMEWORK] ?? ""
            temp.browserOptional = attributeDict[ATTRIBUTE_BROWSER_OPTIONAL] == "true" ? true : false
            verification?.javaScriptResources.append(temp)
            
        case "Tracking:TrackingEvents:Verification:AdVerifications:Extension:Extensions:InLine:Ad:VAST:":
            let vpExtension = vpadnAdInline?.extensions.last
            let verification = vpExtension?.adVerifications.last
            let temp = VpadnTracking()
            temp.event = attributeDict[ATTRIBUTE_EVENT]
            verification?.trackingEvents.append(temp)
            
        default:
            break
        }
    }
    
    // 遇到字符串時候觸發，該方法是解析元素文本內容主要場所
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard !string.isEmpty && string.replacingOccurrences(of: " ", with: "") != "" else { return }
//        VPSDKHelper.log("\(#file), \(#function) Characters: \(string)")
        
        switch currentPath {
        case "AdSystem:Wrapper:Ad:VAST:":
            vpadnAdWrapper?.adSystem = string
            
        case "VASTAdTagURI:Wrapper:Ad:VAST:":
            vpadnAdWrapper?.adTagURL = URL(string: string)
            
        case "Error:Wrapper:Ad:VAST:":
            let temp = VpadnTracking()
            temp.url = URL(string: string)
            temp.event = "error"
            vpadnAdWrapper?.errors.append(temp)
            vpadnAdWrapper?.allTrackings.append(temp)
            
        case "Impression:Wrapper:Ad:VAST:":
            if let temp = vpadnAdWrapper?.impressions.last {
                temp.url = URL(string: string)
                vpadnAdWrapper?.impressions.append(temp)
                vpadnAdWrapper?.allTrackings.append(temp)
            }
            
        case "Viewable:ViewableImpression:Wrapper:Ad:VAST:":
            if let temp = vpadnAdWrapper?.viewableImpression.viewables.last {
                temp.url = URL(string: string)
                vpadnAdWrapper?.allTrackings.append(temp)
            }
            
        case "NotViewable:ViewableImpression:Wrapper:Ad:VAST:":
            if let temp = vpadnAdWrapper?.viewableImpression.notViewables.last {
                temp.url = URL(string: string)
                vpadnAdWrapper?.allTrackings.append(temp)
            }
            
        case "ViewUndetermined:ViewableImpression:Wrapper:Ad:VAST:":
            if let temp = vpadnAdWrapper?.viewableImpression.viewUndetermineds.last {
                temp.url = URL(string: string)
                vpadnAdWrapper?.allTrackings.append(temp)
            }
            
        case "Viewable:ViewableImpression:Verification:AdVerifications:Wrapper:Ad:VAST:":
            let verification = vpadnAdWrapper?.adVerifications.last
            if let temp = verification?.viewableImpression?.viewables.last {
                temp.url = URL(string: string)
                vpadnAdWrapper?.allTrackings.append(temp)
            }
            
        case "NotViewable:ViewableImpression:Verification:AdVerifications:Wrapper:Ad:VAST:":
            let verification = vpadnAdWrapper?.adVerifications.last
            if let temp = verification?.viewableImpression?.notViewables.last {
                temp.url = URL(string: string)
                vpadnAdWrapper?.allTrackings.append(temp)
            }
            
        case "ViewUndetermined:ViewableImpression:Verification:AdVerifications:Wrapper:Ad:VAST:":
            let verification = vpadnAdWrapper?.adVerifications.last
            if let temp = verification?.viewableImpression?.viewUndetermineds.last {
                temp.url = URL(string: string)
                vpadnAdWrapper?.allTrackings.append(temp)
            }
            
        case "Tracking:TrackingEvents:Linear:Creative:Creatives:Wrapper:Ad:VAST:":
            let creative = vpadnAdWrapper?.creatives.last
            if let tracking = creative?.linear.trackingEvents.last {
                tracking.url = URL(string: string)
                vpadnAdWrapper?.allTrackings.append(tracking)
            }
            
        case "ClickTracking:VideoClicks:Linear:Creative:Creatives:Wrapper:Ad:VAST:":
            let creative = vpadnAdWrapper?.creatives.last
            if let tracking = creative?.linear.videoClicks.clickTracking.last {
                tracking.url = URL(string: string)
                vpadnAdWrapper?.allTrackings.append(tracking)
            }
            
        case "CustomClick:VideoClicks:Linear:Creative:Creatives:Wrapper:Ad:VAST:":
            let creative = vpadnAdWrapper?.creatives.last
            if let tracking = creative?.linear.videoClicks.customClick.last {
                tracking.url = URL(string: string)
                vpadnAdWrapper?.allTrackings.append(tracking)
            }
            
        case "StaticResource:Companion:CompanionAds:Creative:Creatives:Wrapper:Ad:VAST:":
            let creative = vpadnAdWrapper?.creatives.last
            creative?.companionAds.staticResource.url = URL(string: string)
            
        case "IFrameResource:Companion:CompanionAds:Creative:Creatives:Wrapper:Ad:VAST:":
            let creative = vpadnAdWrapper?.creatives.last
            creative?.companionAds.iFrameResource.url = URL(string: string)
            
        case "HTMLResource:Companion:CompanionAds:Creative:Creatives:Wrapper:Ad:VAST:":
            let creative = vpadnAdWrapper?.creatives.last
            creative?.companionAds.htmlResource.url = URL(string: string)
            
        case "AdParameters:Companion:CompanionAds:Creative:Creatives:Wrapper:Ad:VAST:":
            let creative = vpadnAdWrapper?.creatives.last
            creative?.companionAds.adParameters.data = string
            
        case "AltText:Companion:CompanionAds:Creative:Creatives:Wrapper:Ad:VAST:":
            let creative = vpadnAdWrapper?.creatives.last
            creative?.companionAds.altText = string
            
        case "CompanionClickThrough:Companion:CompanionAds:Creative:Creatives:Wrapper:Ad:VAST:":
            let creative = vpadnAdWrapper?.creatives.last
            creative?.companionAds.clickThrough = URL(string: string)
            
        case "CompanionClickTracking:Companion:CompanionAds:Creative:Creatives:Wrapper:Ad:VAST:":
            let creative = vpadnAdWrapper?.creatives.last
            if let tracking = creative?.companionAds.clickTracking.last {
                tracking.url = URL(string: string)
                vpadnAdWrapper?.allTrackings.append(tracking)
            }
            
        case "Tracking:TrackingEvents:Companion:CompanionAds:Creative:Creatives:Wrapper:Ad:VAST:":
            let creative = vpadnAdWrapper?.creatives.last
            if let tracking = creative?.companionAds.trackingEvents.last {
                tracking.url = URL(string: string)
                vpadnAdWrapper?.allTrackings.append(tracking)
            }
            
        case "AdSystem:InLine:Ad:VAST:":
            vpadnAdInline?.adSystem = string
            
        case "AdTitle:InLine:Ad:VAST:":
            vpadnAdInline?.adTitle = string
            
        case "Description:InLine:Ad:VAST:":
            vpadnAdInline?.desc = string
            
        case "Advertiser:InLine:Ad:VAST:":
            vpadnAdInline?.advertiser = string
            
        case "Pricing:InLine:Ad:VAST:":
            vpadnAdInline?.pricing.pricing = Double(string)
            
        case "Error:InLine:Ad:VAST:":
            let temp = VpadnTracking()
            temp.url = URL(string: string)
            temp.event = "error"
            vpadnAdInline?.errors.append(temp)
            vpadnAdInline?.allTrackings.append(temp)
            
        case "Impression:InLine:Ad:VAST:":
            if let temp = vpadnAdInline?.impressions.last {
                temp.url = URL(string: string)
                vpadnAdInline?.impressions.append(temp)
                vpadnAdInline?.allTrackings.append(temp)
            }
            
        case "Viewable:ViewableImpression:InLine:Ad:VAST:":
            if let tracking = vpadnAdInline?.viewableImpression.viewables.last {
                tracking.url = URL(string: string)
                vpadnAdInline?.allTrackings.append(tracking)
            }
            
        case "NotViewable:ViewableImpression:InLine:Ad:VAST:":
            if let tracking = vpadnAdInline?.viewableImpression.notViewables.last {
                tracking.url = URL(string: string)
                vpadnAdInline?.allTrackings.append(tracking)
            }
            
        case "ViewUndetermined:ViewableImpression:InLine:Ad:VAST:":
            if let tracking = vpadnAdInline?.viewableImpression.viewUndetermineds.last {
                tracking.url = URL(string: string)
                vpadnAdInline?.allTrackings.append(tracking)
            }
            
        case "JavaScriptResource:Verification:AdVerifications:InLine:Ad:VAST:":
            let verification = vpadnAdInline?.adVerifications.last
            let temp = verification?.javaScriptResources.last
            temp?.url = URL(string: string)
            
        case "FlashResource:Verification:AdVerifications:InLine:Ad:VAST:":
            let verification = vpadnAdInline?.adVerifications.last
            let temp = verification?.flashResources.last
            temp?.url = URL(string: string)
            
        case "Viewable:ViewableImpression:Verification:AdVerifications:InLine:Ad:VAST:":
            let verification = vpadnAdInline?.adVerifications.last
            if let tracking = verification?.viewableImpression?.viewables.last {
                tracking.url = URL(string: string)
                vpadnAdInline?.allTrackings.append(tracking)
            }
            
        case "NotViewable:ViewableImpression:Verification:AdVerifications:InLine:Ad:VAST:":
            let verification = vpadnAdInline?.adVerifications.last
            if let tracking = verification?.viewableImpression?.notViewables.last {
                tracking.url = URL(string: string)
                vpadnAdInline?.allTrackings.append(tracking)
            }
            
        case "ViewUndetermined:ViewableImpression:Verification:AdVerifications:InLine:Ad:VAST:":
            let verification = vpadnAdInline?.adVerifications.last
            if let tracking = verification?.viewableImpression?.viewUndetermineds.last {
                tracking.url = URL(string: string)
                vpadnAdInline?.allTrackings.append(tracking)
            }
            
        case "Duration:Linear:Creative:Creatives:InLine:Ad:VAST:":
            let creative = vpadnAdInline?.creatives.last
            let parser = VpadnTimeIntervalFormatter()
            creative?.linear.duration = parser.timeInterval(with: string)
            
        case "AdParameters:Linear:Creative:Creatives:InLine:Ad:VAST:":
            let creative = vpadnAdInline?.creatives.last
            creative?.linear.adParameters.data = string
            
        case "Tracking:TrackingEvents:Linear:Creative:Creatives:InLine:Ad:VAST:":
            let creative = vpadnAdInline?.creatives.last
            if let tracking = creative?.linear.trackingEvents.last {
                tracking.url = URL(string: string)
                vpadnAdInline?.allTrackings.append(tracking)
            }
            
        case "ClickTracking:VideoClicks:Linear:Creative:Creatives:InLine:Ad:VAST:":
            let creative = vpadnAdInline?.creatives.last
            if let tracking = creative?.linear.videoClicks.clickTracking.last {
                tracking.url = URL(string: string)
                vpadnAdInline?.allTrackings.append(tracking)
            }
            
        case "ClickThrough:VideoClicks:Linear:Creative:Creatives:InLine:Ad:VAST:":
            let creative = vpadnAdInline?.creatives.last
            creative?.linear.videoClicks.clickThrough = URL(string: string)
            vpadnAdInline?.clickThroughURL = URL(string: string)
                
        case "CustomClick:VideoClicks:Linear:Creative:Creatives:InLine:Ad:VAST:":
            let creative = vpadnAdInline?.creatives.last
            if let tracking = creative?.linear.videoClicks.customClick.last {
                tracking.url = URL(string: string)
                vpadnAdInline?.allTrackings.append(tracking)
            }
            
        case "MediaFile:MediaFiles:Linear:Creative:Creatives:InLine:Ad:VAST:":
            let creative = vpadnAdInline?.creatives.last
            let mediaFile = creative?.linear.mediaFiles.last
            var stringCopy = string
            stringCopy = stringCopy.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if !string.isEmpty {
                mediaFile?.url = URL(string: stringCopy)
            }
            
        case "StaticResource:Companion:CompanionAds:Creative:Creatives:InLine:Ad:VAST:":
            let creative = vpadnAdInline?.creatives.last
            creative?.companionAds.staticResource.url = URL(string: string)
            
        case "IFrameResource:Companion:CompanionAds:Creative:Creatives:InLine:Ad:VAST:":
            let creative = vpadnAdInline?.creatives.last
            creative?.companionAds.iFrameResource.url = URL(string: string)
            
        case "HTMLResource:Companion:CompanionAds:Creative:Creatives:InLine:Ad:VAST:":
            let creative = vpadnAdInline?.creatives.last
            creative?.companionAds.htmlResource.url = URL(string: string)
            
        case "AdParameters:Companion:CompanionAds:Creative:Creatives:InLine:Ad:VAST:":
            let creative = vpadnAdInline?.creatives.last
            creative?.companionAds.adParameters.data = string
            
        case "AltText:Companion:CompanionAds:Creative:Creatives:InLine:Ad:VAST:":
            let creative = vpadnAdInline?.creatives.last
            creative?.companionAds.altText = string
            
        case "CompanionClickThrough:Companion:CompanionAds:Creative:Creatives:InLine:Ad:VAST:":
            let creative = vpadnAdInline?.creatives.last
            creative?.companionAds.clickThrough = URL(string: string)
            
        case "CompanionClickTracking:Companion:CompanionAds:Creative:Creatives:InLine:Ad:VAST:":
            let creative = vpadnAdInline?.creatives.last
            if let tracking = creative?.companionAds.clickTracking.last {
                tracking.url = URL(string: string)
                vpadnAdInline?.allTrackings.append(tracking)
            }
            
        case "Tracking:TrackingEvents:Companion:CompanionAds:Creative:Creatives:InLine:Ad:VAST:":
            let creative = vpadnAdInline?.creatives.last
            if let tracking = creative?.companionAds.trackingEvents.last {
                tracking.url = URL(string: string)
                vpadnAdInline?.allTrackings.append(tracking)
            }
            
        case "JavaScriptResource:Verification:AdVerifications:Extension:Extensions:InLine:Ad:VAST:":
            let vpExtension = vpadnAdInline?.extensions.last
            let verification = vpExtension?.adVerifications.last
            let temp = verification?.javaScriptResources.last
            temp?.url = URL(string: string)
            
        case "Tracking:TrackingEvents:Verification:AdVerifications:Extension:Extensions:InLine:Ad:VAST:":
            let vpExtension = vpadnAdInline?.extensions.last
            let verification = vpExtension?.adVerifications.last
            if let tracking = verification?.trackingEvents.last {
                tracking.url = URL(string: string)
                vpadnAdInline?.allTrackings.append(tracking)
            }
            
        case "VerificationParameters:Verification:AdVerifications:Extension:Extensions:InLine:Ad:VAST:":
            let vpExtension = vpadnAdInline?.extensions.last
            let verification = vpExtension?.adVerifications.last
            verification?.verificationParameters = string
            
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if currentPath == "VAST:", let wrapper = vpadnAdWrapper {
            vpadnAdVast.adWrappers.append(wrapper)
            vpadnAdWrapper = nil
        } else if currentPath == "Ad:VAST:", let inline = vpadnAdInline {
            vpadnAdVast.adInlines.append(inline)
            vpadnAdInline = nil
        }
        
        if !currentPath.isEmpty {
            let path = elementName + ":"
            currentPath = String(currentPath.dropFirst(path.count))
//            VPSDKHelper.log("\(#file), \(#function) Remove Path: \(elementName)")
//            VPSDKHelper.log("\(#file), \(#function) ------------------------------------------------------------<")
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        if vpadnAdVast.adWrappers.count > 5 {
            overWrapperLimit()
            return
        }
        
        if isWrapper ?? false {
            if let wrapper = vpadnAdVast.adWrappers.last {
                self.currentPath = ""
                let reentrantAvoidanceQueue = DispatchQueue(label: "reentrantAvoidanceQueue")
                reentrantAvoidanceQueue.async {
                    self.getXmlDocument(adTagURL: wrapper.adTagURL)
                }
                reentrantAvoidanceQueue.sync {}
            }
         } else {
            delegate?.vpadnAdParserDidFinish(ad: vpadnAdVast)
         }
    }
}
