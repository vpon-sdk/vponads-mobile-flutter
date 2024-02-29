//
//  RequestService.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/9/28.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

final class RequestService: NSObject {
    
    private let SESSION_TIMEOUT = 1800
    private let AD_REQUEST_TIMEOUT = 3
    private let VPON_STORAGE_COOKIE_FILE = "/vponCookieFile"
    private let VPON_COOKIE_NAME = "Vpadn-Guid"
    private let VIDEO_CACHE_CHECK_TIMW = 86400
    private let DEFAULT_LOCARION_CACHE_TIME = 300
    private let DEFAULT_LOCARION_CACHE_ACCURACY = 300.0
     
    /// 請求廣告
    /// - Parameters:
    ///   - url: 廣告位置
    ///   - success: 成功執行的邏輯
    ///   - failure: 失敗執行的邏輯
    func sendAdRequest(with url: URL, completion: @escaping (Result<URLResponse, Error>) -> Void) {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        var request = URLRequest(url: url)
        request.cachePolicy = URLRequest.CachePolicy.useProtocolCachePolicy
        request.timeoutInterval = TimeInterval(AD_REQUEST_TIMEOUT)
        if let userAgent = DeviceInfo.shared.getUserAgent() {
            request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        }
        request.setValue("0", forHTTPHeaderField: "Keep-Alive")
        
        let cookieInfo = getCookieInfo()
        if !cookieInfo.isEmpty {
            request.setValue(cookieInfo, forHTTPHeaderField: "Cookie")
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failure(error))
            } else if let response {
                completion(.success(response))
            } else {
                completion(.failure(ErrorGenerator.noAds()))
            }
        }
        task.resume()
        session.finishTasksAndInvalidate()
    }
    
    private func getCookieInfo() -> String {
        var path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
        path.append(VPON_STORAGE_COOKIE_FILE)
        
        if let cookieData = NSDictionary(contentsOfFile: path) as? [HTTPCookiePropertyKey: Any], !cookieData.isEmpty {
            var cookieInfo = ""
            var bHasVponCookie = false
            for cookie in HTTPCookieStorage.shared.cookies ?? [] {
                if cookie.name == VPON_COOKIE_NAME {
                    bHasVponCookie = true
                    if let date = cookie.expiresDate {
                        cookieInfo = "\(cookie.name)=\(cookie.value); Domain=\(cookie.domain); Expires=\(date); Path=\(cookie.path)"
                    } else {
                        cookieInfo = "\(cookie.name)=\(cookie.value); Domain=\(cookie.domain); Expires=; Path=\(cookie.path)"
                    }
                    break
                }
            }
            if !bHasVponCookie, let httpGetCookie = HTTPCookie(properties: cookieData) {
                HTTPCookieStorage.shared.setCookie(httpGetCookie)
            }
            return cookieInfo
        } else {
            return ""
        }
    }
}

// MARK: - URLSessionDataDelegate

extension RequestService: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        // 处理每次接收的数据
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // 请求完成,成功或者失败的处理
    }
}

// MARK: - URLSessionTaskDelegate

extension RequestService: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        // return nil , 防止自動跳轉 location
        completionHandler(nil)
    }
}
