//
//  AdRequestHelper.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/9/28.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

final class AdRequestHelper {
    
    private let service = RequestService()
    private var request: VponAdRequest?
    private var licenseKey: String?
    
    func requestAd(licenseKey: String, request: VponAdRequest, extras: [String: Any]? = nil, completion: @escaping (Result<AdResponse, Error>) -> Void) {
        self.licenseKey = licenseKey
        self.request = request
        
        let requestParams = generateParams()
        guard let url = composeRequestURL(with: requestParams) else {
            VponConsole.log("Error making request URL!")
            return
        }
        VponConsole.log("Params: \(requestParams as AnyObject)")
        VponConsole.log("Request URL: \(url.absoluteString)")

        service.sendAdRequest(with: url) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    let vponResponse = AdResponse(from: response)
                    
                    if let error = vponResponse.error {
                        VponConsole.log("[AD LIFECYCLE] ReceivedFailToLoad invoked, reason: \(vponResponse.statusCode) | \(vponResponse.status) | \(vponResponse.statusDescription)", .info)
                        completion(.failure(error))
                    } else {
                        
                        guard let adURL = vponResponse.locationURL else {
                            completion(.failure(ErrorGenerator.noAds()))
                            return
                        }
                        
                        guard request.format != "na" else {
                            completion(.success(vponResponse))
                            return
                        }
                        // Only for display ad (banner & interstitial)
                        AdRequestHelper.requestContent(with: adURL) { content in
                            vponResponse.targetHtml = content
                            completion(.success(vponResponse))
                        } failure: {
                            completion(.failure(ErrorGenerator.noAds()))
                        }
                    }
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// 請求網頁內容
    class func requestContent(with url: URL, completion: @escaping (String) -> Void, failure: (() -> Void)? = nil) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let targetHtml = String(data: data, encoding: .utf8) {
                completion(targetHtml)
            } else {
                failure?()
            }
        }
        task.resume()
    }
    
    // MARK: - Helper
    
    private func generateParams() -> [String: String] {
        guard let request else { return [:] }
        var params = [String: String]()
        let factory = ParamsFactory(request: request)
        
        for key in AdRequestKey.allCases {
            if let value = factory.getRequestParam(for: key), value != "" {
                params[key.rawValue] = value
            }
        }
        
        params[AdRequestKey.licenseKey.rawValue] = licenseKey
        
        return params
    }
    
    private func composeRequestURL(with params: [String: String], extras: [String: Any] = [:]) -> URL? {
        var urlComponents = URLComponents(string: Constants.Domain.requestAdService)!
        // 使用 percentEncodedQueryItems 避免 urlComponents.url 進行二次編碼
        urlComponents.percentEncodedQueryItems = params.map({ key, value in
            let queryItemValue: String
            if key == AdRequestKey.ms.rawValue {
                // ms 值本身已編碼過
                queryItemValue = value
            } else {
                // 其他參數統一在此 encode
                queryItemValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?
                                      .replacingOccurrences(of: ":00", with: "")
                                      .replacingOccurrences(of: "+0", with: "+")
                                      .replacingOccurrences(of: "-0", with: "-")
                                      .replacingOccurrences(of: " ", with: "%20")
                                      .replacingOccurrences(of: "+", with: "%2B")
                                      .replacingOccurrences(of: ":", with: "%3A") ?? value
            }
            return URLQueryItem(name: key, value: queryItemValue)
        })
        return urlComponents.url
    }
    
// 舊的做法留存供參
//    func composeRequestURL(with params: [String: String], extras: [String: String] = [:]) -> URL? {

//        params.append(extras)

//        var urlString = Constants.Domain.requestAdService
//        let keys = params.keys
//        for key in keys {
//            if let value = params[key], !value.isEmpty {
//                if key == keys.first {
//                    urlString = urlString.appending("?\(key)=\(value)")
//                } else {
//                    urlString = urlString.appending("&\(key)=\(value)")
//                }
//            } else { continue }
//        }
//        return URL(string: urlString)
//    }
}
