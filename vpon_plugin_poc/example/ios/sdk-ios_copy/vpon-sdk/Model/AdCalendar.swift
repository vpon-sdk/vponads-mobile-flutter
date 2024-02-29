//
//  AdCalendar.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/3/24.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import WebKit
import EventKit

struct AdCalendar {
    
    /// 標題
    var desc: String = ""
    
    /// 地點名稱
    var locationName: String = ""
    
    /// 概要
    var summary: String = ""
    
    /// 起始時間
    var startDate: Date?
    
    /// 結束時間
    var endDate: Date?
    
    /// 狀態
    var status: EKEventStatus = .none
    
    /// 提醒時間
    var reminderDate: Date?
    
    var transparency: String = ""
    
    /// 循環規則
    var recurrence: EKRecurrenceRule?
    
    /// 是否新增提醒
    var needReminder: Bool = false
    
    /// 是否新增重複
    var needRecurrence: Bool = false
    
    private var isValid: Bool = false
    
    init(message: WKScriptMessage) {
        guard let body = message.body as? String else { return }
        let data = JsonParseHelper.jsonToDictionary(with: body)
        isValid = validCalendar(data: data)
        desc = data["description"] as? String ?? ""
        locationName = data["location"] as? String ?? ""
        summary = data["summary"] as? String ?? ""
        
        if let string = data["start"] as? String,
           let date = Date.parseDateTime(dateTimeString: string) {
            startDate = date
        }
        if let string = data["end"] as? String,
           let date = Date.parseDateTime(dateTimeString: string) {
            endDate = date
        } else if isValid {
            // 如果沒帶 end，預設 start 加 3600s
            endDate = startDate?.addingTimeInterval(60 * 60)
        }
        
        let statusFromData = data["status"] as? String ?? ""
        switch statusFromData {
        case "tentative":
            status = .tentative
        case "confirmed":
            status = .confirmed
        case "cancelled":
            status = .canceled
        default:
            break
        }
        
        if let reminderString = data["reminder"] as? String,
           !reminderString.isEmpty {
            if reminderString.prefix(1) == "-" {
                needReminder = true
                
                if let startDate,
                   let intervalInt = Int(reminderString) {
                    let interval = TimeInterval(intervalInt / 100)
                    reminderDate = startDate.addingTimeInterval(interval)
                }
            } else if let date = Date.parseDateTime(dateTimeString: reminderString) {
                needReminder = true
                reminderDate = date
            }
        }
        
        if let recurrenceData = data["recurrence"] as? [String: Any],
           let frequencyString = recurrenceData["frequency"] as? String {
            
            needRecurrence = true
            let frequency: EKRecurrenceFrequency = getFrequency(frequency: frequencyString)
            let interval = recurrenceData["interval"] as? Int ?? 1
            if let days = recurrenceData["daysInWeek"] as? [Int] {
                var daysOfTheWeek = [EKRecurrenceDayOfWeek]()
                
                for i in 0 ..< days.count {
                    let day = days[i]
                    let dayOfWeek = EKRecurrenceDayOfWeek(EKWeekday(rawValue: day)!)
                    daysOfTheWeek.append(dayOfWeek)
                }
                let daysOfTheMonth = recurrenceData["daysInMonth"] as? [NSNumber]
                let daysOfTheYear = recurrenceData["daysInYear"] as? [NSNumber]
                let weeksOfTheYear = [NSNumber]()
                let monthsOfTheYear = recurrenceData["monthsInYear"] as? [NSNumber]
                let positions = [NSNumber]()
                var end: EKRecurrenceEnd?
                if let expireTime = recurrenceData["expires"] as? String,
                   let date = Date.parseDateTime(dateTimeString: expireTime) {
                    end = EKRecurrenceEnd(end: date)
                }
                self.recurrence = EKRecurrenceRule(recurrenceWith: frequency,
                                                   interval: interval,
                                                   daysOfTheWeek: daysOfTheWeek,
                                                   daysOfTheMonth: daysOfTheMonth,
                                                   monthsOfTheYear: monthsOfTheYear,
                                                   weeksOfTheYear: weeksOfTheYear,
                                                   daysOfTheYear: daysOfTheYear,
                                                   setPositions: positions,
                                                   end: end)
            }
        }
        
    }
    
    /// 是否為有效的行事曆資料
    /// - Returns: true = 有效 / false = 無效
    func canAddCalendar() -> Bool {
        return isValid
    }
    
    private func validCalendar(data: [String: Any]) -> Bool {
        return FormatVerifier.checkUsageDescription("NSCalendarsUsageDescription")
        && data.keys.contains("start")
        && data.keys.contains("description")
    }
    
    private func getFrequency(frequency: String) -> EKRecurrenceFrequency {
        switch frequency {
        case "weekly":
            return .weekly
        case "monthly":
            return .monthly
        case "yearly":
            return .yearly
        default:
            return .daily
        }
    }
}
