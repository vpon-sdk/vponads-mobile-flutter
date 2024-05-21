//
//  VponFlutterReaderWriter.swift
//  vpon_plugin_poc
//
//  Created by vponinc on 2024/1/30.
//

import Flutter

class VponFlutterBannerAdSizeFactory: NSObject {
    
}

/// Translator for converting Dart objects to Vpon Ad SDK objects and vice versa.
class VponFlutterReaderWriter: FlutterStandardReaderWriter {
    
    let adSizeFactory: VponFlutterBannerAdSizeFactory
    
    init(factory: VponFlutterBannerAdSizeFactory) {
        adSizeFactory = factory
        super.init()
    }
    
    convenience override init() {
        self.init(factory: VponFlutterBannerAdSizeFactory())
    }
    
    override func reader(with data: Data) -> FlutterStandardReader {
        let reader = VponFlutterReader(factory: adSizeFactory, data: data)
        return reader
    }
    
    override func writer(with data: NSMutableData) -> FlutterStandardWriter {
        return VponFlutterWriter(data: data)
    }
}

class VponFlutterReader: FlutterStandardReader {
    
    let adSizeFactory: VponFlutterBannerAdSizeFactory
    
    init(factory: VponFlutterBannerAdSizeFactory, data: Data) {
        adSizeFactory = factory
        super.init(data: data)
    }
    
    override func readValue(ofType type: UInt8) -> Any? {
        guard let field = VponFlutterField(rawValue: type) else {
            return super.readValue(ofType: type)
        }
        
        switch field {
        case .adRequest:
            let request = VponFlutterAdRequest()
            request.contentURL = self.readValue(ofType: self.readByte()) as? String
            request.contentData = self.readValue(ofType: self.readByte()) as? [String: Any]
            request.keywords = self.readValue(ofType: self.readByte()) as? [String]
            return request
            
        case .bannerAdSize:
            return VponFlutterBannerAdSize(width: readValue(ofType: readByte()) as? Int,
                                       height: readValue(ofType: readByte()) as? Int)
        }
    }
}

class VponFlutterWriter: FlutterStandardWriter {
    
    override func writeValue(_ value: Any) {
        switch value {
            // 目前沒有呼叫到
//        case is VponFlutterAdRequest:
//            print("writeValue VponFlutterAdRequest \(value)")
//            writeByte(VponFlutterField.adRequest.rawValue)
//            let request = value as! VponFlutterAdRequest
//            if let keywords = request.keywords {
//                self.writeValue(keywords)
//            }
//            if let contentURL = request.contentURL {
//                self.writeValue(contentURL)
//            }
//            if let contentData = request.contentData {
//                self.writeValue(contentData)
//            }
//            if let age = request.userInfoAge {
//                self.writeValue(age)
//            }
//            if let gender = request.userInfoGender {
//                self.writeValue(gender)
//            }
//            if let bday = request.userInfoBirthday {
//                self.writeValue(bday)
//            }
            
        default:
            super.writeValue(value)
        }
    }
}
