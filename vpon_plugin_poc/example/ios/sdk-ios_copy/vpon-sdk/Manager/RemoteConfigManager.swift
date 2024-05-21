//
//  RemoteConfigManager.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/11/9.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

final class RemoteConfigManager {
    
    struct AdChoices: Codable {
        let bid: String?
        let position: String
        let link: String
    }
    
    enum AdChoicePosition: String {
        case upperRight = "ur"
        case upperLeft = "ul"
        case lowerRight = "lr"
        case lowerLeft = "ll"
    }
    
    static let shared = RemoteConfigManager()
    
    private var currentConfig: [String: Any]?
    private var nextUpdateDate: Date?
    
    private init() {
        currentConfig = UserDefaults.standard.dictionary(forKey: Constants.UserDefaults.config)
        nextUpdateDate = UserDefaults.standard.object(forKey: Constants.Config.nextUpdateTime) as? Date
    }
    
    // MARK: - Interface
    
    /// 檢查 config 是否需要更新
    func checkConfig() {
        if let nextUpdateDate {
            let now = Date()
            
            if now.compare(nextUpdateDate) == .orderedAscending {
                return
            } else {
                updateConfigFromServer { success in
                    
                }
            }
        } else {
            // nextUpdateTime is nil -> updateConfig
            updateConfigFromServer { success in
                
            }
        }
    }
    
    /// 是否允許來自這個 licenseKey 的 ad request
    func shouldAllowRequest(licenseKey: String) -> Bool {
        guard let whiteList = currentConfig?[Constants.Config.whiteList] as? [[String: Any]] else { return true }
        
        if whiteList.count > 0 {
            for member in whiteList {
                let whiteLicenseKey = member[Constants.Config.whiteListBid] as? String
                
                if licenseKey == whiteLicenseKey,
                   let allowPercentage = member[Constants.Config.whiteListAllowPercent] as? Float {
                    
                    let random = Float(arc4random()) / Float(UInt32.max)
                    if random > allowPercentage {
                        return false // -> restrict ad request
                    } else {
                        return true
                    }
                }
            }
            // licenseKey is not in whiteList -> pass
            return true
            
        } else {
            // whiteList is empty -> pass
            return true
        }
    }

    func getAdChoiceInfo(of licenseKey: String) -> (position: String, urlString: String) {
        let defaultSettings = ("ur", "https://www.vpon.com/zh-hant/privacy-policy/")
        
        guard let adChoicesInfo = currentConfig?[Constants.Config.adChoices] as? [[String: Any]] else {
            VponConsole.log("[RemoteConfigManager] Error getting ad choice info from currentConfig! currentConfig: \(String(describing: currentConfig))")
            return defaultSettings
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: adChoicesInfo, options: [])
            let adChoicesItems = try JSONDecoder().decode([AdChoices].self, from: jsonData)
            
            // 先 loop 有 bid 的 item，若與 licenseKey 相符則 return 對應的設定
            for adChoicesItem in adChoicesItems where adChoicesItem.bid != nil {
                if let bid = adChoicesItem.bid, bid == licenseKey {
                    let position = adChoicesItem.position
                    let link = adChoicesItem.link
                    VponConsole.log("[RemoteConfigManager] Found custom ad choices settings of licenseKey: \(bid), position: \(position), link: \(link)")
                   return (position, link)
                }
            }
            
            // 沒有符合的 bid，讀取預設值（bid == nil 的 item）
            if let defaultItem = adChoicesItems.first(where: { $0.bid == nil }) {
                let position = defaultItem.position
                let link = defaultItem.link
                return (position, link)
            }
            
            // 連一個 item 都沒有 -> 返回預設值
            return defaultSettings
            
        } catch {
            VponConsole.log("[RemoteConfigManager] Error decoding ad choices data: \(error.localizedDescription)")
            return defaultSettings
        }
    }
    
    // MARK: - Logic
    
    /// 從 server 抓取最新的 config json 內容
    private func updateConfigFromServer(completion: @escaping (Bool) -> Void) {
        calculateNextUpdateDate()
        
        let urlString = Constants.Config.url
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, error == nil {
                do {
                    let dictionary = try JSONSerialization.jsonObject(with: data) as! [String: Any]
                    self.currentConfig = dictionary
                    UserDefaults.standard.set(self.currentConfig, forKey: Constants.UserDefaults.config)
                    VponConsole.log("[RemoteConfigManager] Successfully updated remote config.")
                    VponConsole.log("[RemoteConfigManager] Current config: \(self.currentConfig as AnyObject)")
                    completion(true)
                } catch {
                    VponConsole.log("[RemoteConfigManager] Failed to update remote config: \(error.localizedDescription)")
                    completion(false)
                }
            } else {
                VponConsole.log("[RemoteConfigManager] Failed to update remote config: \(String(describing: error?.localizedDescription))")
                completion(false)
            }
        }.resume()
    }
    
    /// 更新下次 updateConfigFromServer 的時間門檻
    private func calculateNextUpdateDate() {
        let currentTime = Date()
        guard let todayAt4PM = getDate(addingDay: 0, addingHour: 16),
              let tomorrowAt8AM = getDate(addingDay: 1, addingHour: 8) else { return }
        
        if currentTime.compare(todayAt4PM) == .orderedDescending {
            // after 16:00
            nextUpdateDate = tomorrowAt8AM
            UserDefaults.standard.setValue(nextUpdateDate, forKey: Constants.Config.nextUpdateTime)
            return
        }
        
        guard let todayAt8AM = getDate(addingDay: 0, addingHour: 8) else { return }
        
        if currentTime.compare(todayAt8AM) == .orderedDescending {
            // between 8:00 and 16:00
            nextUpdateDate = todayAt4PM
            UserDefaults.standard.setValue(nextUpdateDate, forKey: Constants.Config.nextUpdateTime)
            return
            
        } else {
            // before or at 8:00
            nextUpdateDate = todayAt8AM
            UserDefaults.standard.setValue(nextUpdateDate, forKey: Constants.Config.nextUpdateTime)
            return
        }
    }
    
    // MARK: - Helper
    
    /// 取得從現在 Date 起增加指定天數 / 小時的 Date
    private func getDate(addingDay addDay: Int, addingHour addHour: Int) -> Date? {
        let calendar = Calendar.current
        let now = Date()
        
        let dateComponents = DateComponents(day: addDay)
        guard let date = calendar.date(byAdding: dateComponents, to: now) else { return nil }
        
        var dateAtSpecificTimeComponents = calendar.dateComponents([.era, .year, .month, .day], from: date)
        dateAtSpecificTimeComponents.hour = addHour
        
        let dateAtSpecificTime = calendar.date(from: dateAtSpecificTimeComponents)!
        return dateAtSpecificTime
    }
}
