//
//  FlutterVponAdReaderWriter.swift
//  vpon_plugin_poc
//
//  Created by vponinc on 2024/1/30.
//

import Flutter
import VpadnSDKAdKit

enum FlutterVponField: UInt8 {
    case adRequest = 129
}

class FlutterAdSizeFactory {
    
}

/// Bridge between Dart and VponAdRequest
class FlutterAdRequest {
    
    var keywords: [String]?
    var contentURL: String?
    
    func asVponAdRequest(licenseKey: String) -> VponAdRequest {
        let request = VponAdRequest()
        if let contentURL {
            request.setContentUrl(contentURL)
        }
        if let keywords, !keywords.isEmpty {
            for keyword in keywords {
                request.addKeyword(keyword)
            }
        }
        return request
    }
}

/// Translator for converting Dart objects to Vpon Ad SDK objects and vice versa.
class FlutterVponAdReaderWriter: FlutterStandardReaderWriter {
    
    let adSizeFactory: FlutterAdSizeFactory
    
    init(factory: FlutterAdSizeFactory) {
        adSizeFactory = factory
        super.init()
    }
    
    convenience override init() {
        self.init(factory: FlutterAdSizeFactory())
    }
    
    override func reader(with data: Data) -> FlutterStandardReader {
        let reader = FlutterVponAdReader(factory: adSizeFactory, data: data)
        return reader
    }
    
    override func writer(with data: NSMutableData) -> FlutterStandardWriter {
        return FlutterVponAdWriter(data: data)
    }
}

class FlutterVponAdReader: FlutterStandardReader {
    
    let adSizeFactory: FlutterAdSizeFactory
    
    init(factory: FlutterAdSizeFactory, data: Data) {
        adSizeFactory = factory
        super.init(data: data)
    }
    
    override func readValue(ofType type: UInt8) -> Any? {
        guard let field = FlutterVponField(rawValue: type) else {
            Console.log("FlutterVponAdReader readValue of type \(type) isn't custom field.)")
            return super.readValue(ofType: type)
        }
        
        switch field {
        case .adRequest:
            let request = FlutterAdRequest()
            request.keywords = self.readValue(ofType: self.readByte()) as? [String]
            request.contentURL = self.readValue(ofType: self.readByte()) as? String
            return request
        }
    }
}

class FlutterVponAdWriter: FlutterStandardWriter {
    
    override func writeValue(_ value: Any) {
        switch value {
        case is FlutterAdRequest:
            self.writeByte(FlutterVponField.adRequest.rawValue)
            let request = value as! FlutterAdRequest
            self.writeValue(request.keywords ?? [])
            self.writeValue(request.contentURL ?? "")
        default:
            super.writeValue(value)
        }
    }
}
