//
//  Date+VpadnAd.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/3/6.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

extension Date {
    
    /**
     * The following acronyms and characters are used from XEP-0082 to represent time-related concepts:
     *
     * CCYY four-digit year portion of Date
     * MM   two-digit month portion of Date
     * DD   two-digit day portion of Date
     * -    ISO 8601 separator among Date portions
     * T    ISO 8601 separator between Date and Time
     * hh   two-digit hour portion of Time (00 through 23)
     * mm   two-digit minutes portion of Time (00 through 59)
     * ss   two-digit seconds portion of Time (00 through 59)
     * :    ISO 8601 separator among Time portions
     * .    ISO 8601 separator between seconds and milliseconds
     * sss  fractional second addendum to Time (MAY contain any number of digits)
     * TZD  Time Zone Definition (either "Z" for UTC or "(+|-)hh:mm" for a specific time zone)
     *
     **/
    
    /// 轉換成特定日期字串
    /// - Parameters:
    ///   - date: 日期
    ///   - format: 轉換格式
    static func dateString(_ date: Date, format: String) -> String {
        let df = DateFormatter()
        df.formatterBehavior = .behavior10_4 // Use unicode patterns (as opposed to 10_3)
        df.dateFormat = format
        return df.string(from: date)
    }
    
    /// 轉換日期字串 (yyyy-MM-dd)
    /// - Parameter dateString: 日期字串
    static func parseDate(with dateString: String) -> Date? {
        if dateString.count < 10 { return nil }
        
        // The Date profile defines a date without including the time of day.
        // The lexical representation is as follows:
        //
        // CCYY-MM-DD
        //
        // Example:
        //
        // 1776-07-04
        let df = DateFormatter()
        df.formatterBehavior = .behavior10_4
        df.dateFormat = "yyyy-MM-dd"
        
        let result = df.date(from: dateString)
        return result
    }
    
    static func parseDateTime(dateTimeString: String, withMandatoryTimeZone mandatoryTZ: Bool = true) -> Date? {
        if dateTimeString.count < 19 { return nil }
        
        // The DateTime profile is used to specify a non-recurring moment in time to an accuracy of seconds (or,
        // optionally, fractions of a second). The format is as follows:
        //
        // CCYY-MM-DDThh:mm:ss[.sss]{TZD}
        //
        // Examples:
        //
        // 1969-07-21T02:56:15
        // 1969-07-21T02:56:15Z
        // 1969-07-20T21:56:15-05:00
        // 1969-07-21T02:56:15.123
        // 1969-07-21T02:56:15.123Z
        // 1969-07-20T21:56:15.123-05:00
        
        var hasMilliSeconds = false
        var hasTimeZoneInfo = false
        var hasTimeZoneOffset = false
        
        if dateTimeString.count > 19 {
            var c = dateTimeString[dateTimeString.index(dateTimeString.startIndex, offsetBy: 19)]
            
            // 檢查是否有毫秒
            if c == "." {
                hasMilliSeconds = true
                
                if dateTimeString.count < 23 {
                    return nil
                }
                
                if dateTimeString.count > 23 {
                    c = dateTimeString[dateTimeString.index(dateTimeString.startIndex, offsetBy: 23)]
                }
            }
            
            // 檢查是否有時區資訊
            if c == "Z" {
                hasTimeZoneInfo = true
                hasTimeZoneOffset = false
            } else if c == "+" || c == "-" {
                hasTimeZoneInfo = true
                hasTimeZoneOffset = true
                
                if hasMilliSeconds {
                    if dateTimeString.count < 29 {
                        return nil
                    }
                } else {
                    if dateTimeString.count < 25 {
                        return nil
                    }
                }
            }
        }
        
        if mandatoryTZ && !hasTimeZoneInfo { return nil }
        
        let df = DateFormatter()
        df.formatterBehavior = .behavior10_4 // Use unicode patterns (as opposed to 10_3)
        
        if hasMilliSeconds {
            if hasTimeZoneInfo {
                if hasTimeZoneOffset {
                    df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS" // 時區偏移量需另行計算
                } else {
                    df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                }
            } else {
                df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
            }
        } else if hasTimeZoneInfo {
            if hasTimeZoneOffset {
                df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss" // 時區偏移量需另行計算
            } else {
                df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            }
        } else {
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        }
        
        var result: Date?
        
        if hasTimeZoneInfo && !hasTimeZoneOffset {
            // NSDateFormatter 會回傳正確的日期，但時區會是系統時區
            
            guard let utcDate = df.date(from: dateTimeString) else { return nil }
            
            let localTZO = TimeZone.current.secondsFromGMT()
            
            result = utcDate.addingTimeInterval(TimeInterval(localTZO))
        } else if hasTimeZoneInfo && hasTimeZoneOffset {
            var subStr1: String
            var subStr2: String
            
            if hasMilliSeconds {
                subStr1 = String(dateTimeString[..<dateTimeString.index(dateTimeString.startIndex, offsetBy: 23)])
                subStr2 = String(dateTimeString[dateTimeString.index(dateTimeString.startIndex, offsetBy: 23)...])
            } else {
                subStr1 = String(dateTimeString[..<dateTimeString.index(dateTimeString.startIndex, offsetBy: 19)])
                subStr2 = String(dateTimeString[dateTimeString.index(dateTimeString.startIndex, offsetBy: 19)...])
            }
            
            guard let timeInLocalTZO = df.date(from: subStr1) else { return nil }
            
            let remoteTZO = self.parseTimeZoneOffset(subStr2)
            let localTZO = TimeZone.current.secondsFromGMT()
            let tzoDiff = TimeInterval(localTZO) - remoteTZO
            result = timeInLocalTZO.addingTimeInterval(tzoDiff)
        } else {
            result = df.date(from: dateTimeString)
        }
        return result
    }
    
    /// 轉換時間 (yyyy-MM-dd'T'HH:mm) 成 Timestamp
    /// - Parameter tzo: 時間字串
    static func parseTimeZoneOffset(_ tzo: String) -> TimeInterval {
        let df = DateFormatter()
        df.formatterBehavior = .behavior10_4 // Use unicode patterns (as opposed to 10_3)
        df.dateFormat = "yyyy-MM-dd'T'HH:mm"
        
        // The tzo value is supposed to start with '+' or '-'.
        // Spec says: (+-)HH:mm
        
        let tzoSubStr = tzo.count > 1 ? String(tzo.suffix(from: tzo.index(after: tzo.startIndex))) : nil
        
        let str1 = "1982-05-20T00:00"
        let str2 = "1982-05-20T\(tzoSubStr ?? "")"
        
        let date1 = df.date(from: str1)
        let date2 = df.date(from: str2)
        
        var result: TimeInterval = 0
        
        if let date1 = date1, let date2 = date2 {
            result = date2.timeIntervalSince(date1)
        }
        
        if tzo.hasPrefix("-") {
            result = -1 * result
        }
        return result
    }
    
}
