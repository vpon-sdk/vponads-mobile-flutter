//
//  AdResponse.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/10/2.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

struct AdVerification {
    var adType: String
    var verifications: [Verification]
}

struct Verification {
    var vendorKey: String
    var verificationParams: String
    var verificationResources: [String]
}

final class AdResponse {
    
    private let httpURLResponse: HTTPURLResponse?
    /// HeaderFields Object
    private var allHeaderFields: [AnyHashable: Any] = [:]
    /// 回應的時間(timestamp)
    var responseTimestamp: TimeInterval
    /// 是否有效
    var isValid = false
    
    var error: Error?
    
    /// 內容 Html String
    var targetHtml: String?
    
    /// 內容網址
    var locationURL: URL?
    
    /// 顯示追蹤 URL
    var onShowURL: String?
    
    /// 點擊追蹤 URL
    var clickURL: String?
    
    /// 曝光追蹤 URL
    var impressionURL: String?
    
    /// OM Verification 用
    var vponAdVerification: AdVerification?
    
    /// req_id (Ad Choices report 用)
    var requestID: String?
    
    /// 狀態
    var status: String = "NETWORK_ERROR"
    
    /// 狀態描述
    var statusDescription: String = "NETWORK_ERROR"
    
    /// 狀態碼
    var statusCode: Int = -1
    
    /// 刷新時間
    var refreshTime: Int = Constants.defaultRefreshAdTime
  
    init(from response: URLResponse) {
        self.httpURLResponse = response as? HTTPURLResponse
        self.responseTimestamp = Date().timeIntervalSince1970
        
        if let httpURLResponse {
            self.isValid = checkResponse(httpURLResponse)
            allHeaderFields = httpURLResponse.allHeaderFields
            
            if let string = allHeaderFields[Constants.ADNResponse.location] as? String {
                locationURL = URL(string: string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
                
                guard let locationURL else { return }
                self.vponAdVerification = parse(key: Constants.ADNResponse.om, from: locationURL)
            }
            
            if let string = allHeaderFields[Constants.ADNResponse.onShow] as? String {
                onShowURL = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            }
            
            if let string = allHeaderFields[Constants.ADNResponse.click] as? String {
                clickURL = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            }
            
            if let string = allHeaderFields[Constants.ADNResponse.impression] as? String {
                impressionURL = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            }
            
            if let time = allHeaderFields[Constants.ADNResponse.refreshTime] as? Int {
                refreshTime = time
            }
            
            if let code = allHeaderFields[Constants.ADNResponse.statusCode] as? String {
                statusCode = Int(code) ?? -1
            }
            
            if let string = allHeaderFields[Constants.ADNResponse.status] as? String {
                status = string
            }
            
            if let string = allHeaderFields[Constants.ADNResponse.statusDescription] as? String {
                statusDescription = string
            }
            
            if let string = allHeaderFields[Constants.ADNResponse.requestID] as? String {
                requestID = string
            }
        }
        
        if !isValid {
            error = ErrorGenerator.requestFailed(code: statusCode, status: status, description: statusDescription)            
        }
        showLog()
    }
    
    private func checkResponse(_ response: HTTPURLResponse) -> Bool {
        return response.allHeaderFields.keys.contains(Constants.ADNResponse.location) && response.allHeaderFields.keys.contains(Constants.ADNResponse.impression) && response.statusCode == 302
    }
    
    // MARK: - Parse verification
    
    private func parse(key: String, from url: URL) -> AdVerification? {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = urlComponents.queryItems else { return nil }
        
        let jsonString = value(for: key, from: queryItems)
        guard !jsonString.isEmpty else {
            VponConsole.log("[AdResponse] om string from ad url is empty!")
            return nil
        }
        guard let jsonData = jsonString.data(using: .utf8) else { return nil }
        
        do {
            guard let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as? [String: Any],
                  let type = jsonObject[Constants.OM.ADNKey.adType] as? String,
                  let verifications = jsonObject[Constants.OM.ADNKey.verification] as? [[String: Any]] else {
                return nil
            }

            guard !verifications.isEmpty else {
                VponConsole.log("[AdResponse] Empty verifications!")
                return nil
            }
            
            let isValid = verifyOMVerifications(verifications, adType: type)
            guard isValid else {
                VponConsole.log("[AdResponse] Invalid verifications!")
                return nil
            }
            
            var allVerifications = [Verification]()
            for data in verifications {
                if let urls = data[Constants.OM.ADNKey.verificationResources] as? [String],
                   let k = data[Constants.OM.ADNKey.vendorKey] as? String,
                   let p = data[Constants.OM.ADNKey.vendorParams] as? String {
                    
                    
                    let verification = Verification(vendorKey: k, verificationParams: p, verificationResources: urls)
                    allVerifications.append(verification)
                    
                }
            }
            
            return AdVerification(adType: type, verifications: allVerifications)
            
        } catch {
            VponConsole.log("[AdResponse] Parse verification failed, reason \(error.localizedDescription)")
            return nil
        }
    }
    
    private func verifyOMVerifications(_ verifications: [[String: Any]], adType type: String) -> Bool {
        switch type {
        case "d":
            // verification script not null, not empty
            let urlPredicate = NSPredicate(format: "ANY SELF.u.length > 0 && NONE SELF.u CONTAINS ''")
            let urlNotEmpty = verifications.filter { urlPredicate.evaluate(with: $0)
            }
            return urlNotEmpty.isEmpty ? false : true
            
        case let t where ["dv", "n", "nv"].contains(t):
            // verification script not null, not empty + vendor key not null, not empty + vendor parameter not null, not empty
            let vendorPredicate = NSPredicate(format: "SELF.k.length > 0 && SELF.p.length > 0 && ANY SELF.u.length > 0 && NONE SELF.u CONTAINS ''")
            let vendorNotEmpty = verifications.filter { vendorPredicate.evaluate(with: $0) }
            return vendorNotEmpty.isEmpty ? false : true
        default:
            return false
        }
    }
    
    private func value(for key: String, from queryItems: [URLQueryItem]) -> String {
        let predicate = NSPredicate(format: "name=%@", key)
        let items = queryItems.filter{ predicate.evaluate(with: $0)}
        if !items.isEmpty, let queryItem = items.first {
            return queryItem.value ?? ""
        } else {
            return ""
        }
    }
    
    // MARK: - Log
    
    private func showLog() {
        if !isValid { return }
        VponConsole.log("AD URL: \(locationURL?.absoluteString ?? "N/A")")
        VponConsole.log("OnShow URL: \(onShowURL ?? "N/A")")
        VponConsole.log("Impression URL: \(impressionURL ?? "N/A")")
        VponConsole.log("Click URL: \(clickURL ?? "N/A")")
        if let vponAdVerification {
            VponConsole.log("Verification: \(vponAdVerification)")
        } else {
            VponConsole.log("Verification is nil!")
        }
    }
}
