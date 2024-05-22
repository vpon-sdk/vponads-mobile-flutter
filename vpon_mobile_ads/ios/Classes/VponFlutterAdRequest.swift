//
//  VponFlutterAdRequest.swift
//  Pods
//
//  Created by vponinc on 2024/3/28.
//

import VpadnSDKAdKit

enum VponFlutterField: UInt8 {
    case bannerAdSize = 128
    case adRequest = 129
}

/// Bridge between Dart and VponAdRequest
class VponFlutterAdRequest {
    var contentURL: String?
    var contentData: [String: Any]?
    var keywords: [String]?
    
    func asVponAdRequest() -> VponAdRequest {
        let request = VponAdRequest()
        
        if let contentURL {
            request.setContentUrl(contentURL)
        }
        
        if let contentData {
            request.setContentData(contentData)
        }
        
        if let keywords, !keywords.isEmpty {
            for keyword in keywords {
                request.addKeyword(keyword)
            }
        }
        
        return request
    }
}
