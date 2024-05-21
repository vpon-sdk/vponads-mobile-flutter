//
//  TrackingManager.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/10/2.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import CommonCrypto

protocol TrackingManagerDelegate: AnyObject {
    var lastVisiblePercent: Float? { get }
    var maxVisiblePercent: Float? { get }
}

final class TrackingManager {
    
    var response: AdResponse
    var click: AdClick?
    
    var adLifeCycleManager: AdLifeCycleManager?
    weak var delegate: TrackingManagerDelegate?
    
    /// 是否送出 Click
    private var didSendClick = false
    /// 是否送出 Impression
    private var didSendImpression = false
    /// 是否送出 OnShow
    private var didSendOnShow = false
    
    private var sequenceNumber: Int = 0
    
    init(response: AdResponse, adLifeCycleManager: AdLifeCycleManager) {
        self.response = response
        self.adLifeCycleManager = adLifeCycleManager
        
        adLifeCycleManager.register(self, .onAdShow)
        adLifeCycleManager.register(self, .onAdImpression)
        adLifeCycleManager.register(self, .onAdClicked)
    }
    
    func sendOnShow() {
        if didSendOnShow  {
            VponConsole.log("[TrackingManager] Skip sending onShow as it has already been sent.")
            return
        }
        guard let urlString = response.onShowURL else {
            VponConsole.log("[TrackingManager] Invalid onShow tracking url!")
            return
        }
        didSendOnShow = true
        VponConsole.log("[AD LIFECYCLE] OnShow invoked", .info)
        sendURLRequest(with: urlString, duration: 0, current: 0) { succeeded in
            if succeeded {
                VponConsole.log("Send on show successfully", .note)
            } else {
                VponConsole.log("Send on show failed", .error)
            }
        }
    }
    
    func sendImpression() {
        if didSendImpression  {
            VponConsole.log("[TrackingManager] Skip sending impression as it has already been sent.")
            return
        }
        guard let urlString = response.impressionURL else {
            VponConsole.log("[TrackingManager] Invalid impression tracking url!")
            return
        }
        didSendImpression = true
        VponConsole.log("[AD LIFECYCLE] Impression invoked", .info)
        sendURLRequest(with: urlString, duration: 0, current: 0) { succeeded in
            if succeeded {
                VponConsole.log("Send impression successfully", .note)
            } else {
                VponConsole.log("Send impression failed", .error)
            }
        }
    }
    
    func sendClick(info: [String : Any]?) {
        if didSendClick  {
            VponConsole.log("[TrackingManager] Skip sending click as it has already been sent.")
            return
        }
        
        if let info, let message = info["message"] as? WKScriptMessage {
            click = AdClick(message: message)
        }
        
        guard let urlString = response.clickURL else {
            VponConsole.log("[TrackingManager] Invalid click tracking url!")
            return
        }
        didSendClick = true
        VponConsole.log("[AD LIFECYCLE] Click invoked", .info)
        sendURLRequest(with: urlString, duration: 0, current: 0) { succeeded in
            if succeeded {
                VponConsole.log("Send click successfully", .note)
            } else {
                VponConsole.log("Send click failed", .error)
            }
        }
    }
    
    func sendMultipleURLRequests(with urlStrings: [String], duration: Double = 0, current: Double = 0) {
        for urlString in urlStrings {
            sendURLRequest(with: urlString, duration: duration, current: current, completion: nil)
        }
    }
    
    private func sendURLRequest(with urlString: String, duration: Double, current: Double, completion: ((_ succeeded: Bool) -> Void)?) {
        let replacedURL = replaceMarco(with: urlString, duration: duration, current: current)
        if let url = URL(string: replacedURL) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let error {
                    VponConsole.log("[TrackingManager] Send tracking failed with error: \(error.localizedDescription). URL: \(replacedURL)")
                    completion?(false)
                } else {
                    VponConsole.log("[TrackingManager] Send tracking successfully")
                    completion?(true)
                }
            }.resume()
        } else {
            VponConsole.log("[TrackingManager] Send tracking failed. URL: \(replacedURL)")
        }
    }
    
    // MARK: - Helper
    
    private func replaceMarco(with urlString: String, duration: Double, current: Double) -> String {
        var newURLString = urlString
        guard !urlString.isEmpty else { return urlString }
        
        if urlString.contains("{CurrentTime}") {
            newURLString = newURLString.replacingOccurrences(of: "{CurrentTime}", with: String(format: "%f", current))
        }
        
        if urlString.contains("{TotalTime}") {
            newURLString = newURLString.replacingOccurrences(of: "{TotalTime}", with: String(format: "%f", duration))
        }
        
        if urlString.contains("{Vpadn-Sid}") {
            let sessionID = Int(Float(Date().timeIntervalSince1970))
            let id = String(describing: sessionID)
            newURLString = newURLString.replacingOccurrences(of: "{Vpadn-Sid}", with: id)
        }
        
        if urlString.contains("{Vpadn-Seq}") {
            let id = String(describing: sequenceNumber)
            sequenceNumber += 1
            newURLString = newURLString.replacingOccurrences(of: "{Vpadn-Seq}", with: id)
        }
        
        if urlString.contains("{Vpadn-App}"),
           let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String,
           let hashName = md5(appName) {
            newURLString = newURLString.replacingOccurrences(of: "{Vpadn-App}", with: String(format: "%f", hashName))
        }
        
        if urlString.contains("{Vpadn-Guid}") {
            newURLString = newURLString.replacingOccurrences(of: "{Vpadn-Guid}", with: "")
        }
        
        if urlString.contains("{Vpadn-uuid}") {
            newURLString = newURLString.replacingOccurrences(of: "{Vpadn-uuid}", with: "")
        }
        
        if urlString.contains("{Vpadn-uuid-md5}") {
            newURLString = newURLString.replacingOccurrences(of: "{Vpadn-uuid-md5}", with: "")
        }
        
        if urlString.contains("[click_x]") {
            if let click, let position = click.position {
                let value = String(format: "%.0f", position.x)
                newURLString = newURLString.replacingOccurrences(of: "[click_x]", with: value)
            } else {
                newURLString = newURLString.replacingOccurrences(of: "[click_x]", with: "-1")
            }
        }
        
        if urlString.contains("[click_y]") {
            if let click, let position = click.position {
                let value = String(format: "%.0f", position.y)
                newURLString = newURLString.replacingOccurrences(of: "[click_y]", with: value)
            } else {
                newURLString = newURLString.replacingOccurrences(of: "[click_y]", with: "-1")
            }
        }
        
        if urlString.contains("[get_resp_time]") {
            let value = String(format: "%.0f", response.responseTimestamp)
            newURLString = newURLString.replacingOccurrences(of: "[get_resp_time]", with: value)
        }
        
        if urlString.contains("[current_exposure_percent]"), let percent = delegate?.lastVisiblePercent {
            let value = String(format: "%.0f", percent)
            newURLString = newURLString.replacingOccurrences(of: "[current_exposure_percent]", with: value)
        }

        if urlString.contains("[max_exposure_percent]"),  let percent = delegate?.maxVisiblePercent {
            let value = String(format: "%.0f", percent)
            newURLString = newURLString.replacingOccurrences(of: "[max_exposure_percent]", with: value)
        }
        
        return newURLString
    }
    
    /// 計算一個字串的 MD5 雜湊值（hash value），並以字串的形式回傳。
    /// ```
    /// MD5 是一種常用的雜湊函數（hash function），它可以將任意長度的資料（如字串、檔案等）轉換成一個 128 位元的散列值（hash value），且不可逆，即無法根據雜湊值來推出原始資料。
    /// 在這段程式碼中，使用了 CommonCrypto 庫中的 CC_MD5 函數來計算 MD5 雜湊值。首先將輸入字串轉換為 C 字串，再使用 CC_MD5 函數計算其雜湊值，最後將雜湊值轉換成 16 進位的字串形式，以便輸出。
    /// ```
    private func md5(_ str: String) -> String? {
        guard let cStr = str.cString(using: .utf8) else {
            return nil
        }
        
        var result = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        CC_MD5(cStr, CC_LONG(strlen(cStr)), &result)
        
        return result.map { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Deinit
    
    func unregisterAdLifeCycleEvents() {
        adLifeCycleManager?.unregisterAllEvents(self)
    }
    
    deinit {
        VponConsole.log("[ARC] TrackingManager deinit")
    }
}

// MARK: - AdLifeCycleObserver

extension TrackingManager: AdLifeCycleObserver {
    func receive(_ event: AdLifeCycle, data: [String : Any]?) {
        switch event {
            
        case .onAdShow:
            sendOnShow()
            
        case .onAdImpression:
            sendImpression()
            
        case .onAdClicked:
            sendClick(info: data)
            
        default:
            return
        }
    }
}
