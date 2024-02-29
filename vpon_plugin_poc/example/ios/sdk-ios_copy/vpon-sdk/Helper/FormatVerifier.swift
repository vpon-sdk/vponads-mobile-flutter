//
//  FormatVerifier.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/4/12.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

struct FormatVerifier {
    
    // MARK: - 正規化
    
    static func formatURL(_ urlString: String) -> String {
        var newString = urlString
        newString = newString.replacingOccurrences(of: " ", with: "")
        newString = newString.replacingOccurrences(of: "{", with: "")
        newString = newString.replacingOccurrences(of: "}", with: "")
        return newString
    }
    
    static func formatPhoneNumber(_ number: String) -> String {
        var newNumber = number
        newNumber = number.replacingOccurrences(of: " ", with: "")
        newNumber = number.replacingOccurrences(of: "-", with: "")
        newNumber = number.replacingOccurrences(of: "+", with: "")
        newNumber = number.replacingOccurrences(of: "(", with: "")
        newNumber = number.replacingOccurrences(of: ")", with: "")
        return newNumber
    }
    
    // MARK: - Verify
    
    static func isURLValid(_ url: URL) -> Bool {
        return UIApplication.shared.canOpenURL(url)
    }
    
    static func args(_ args: [String: Any], regrexStringByKey key: String) -> String {
        if var string = args[key] as? String,
           let regex = try? NSRegularExpression(pattern: "[=]+[A-Za-z0-9$_-]{0,}+[{]+[A-Za-z0-9$_-]{0,}+[}]") {
            string = regex.stringByReplacingMatches(in: string, range: NSMakeRange(0, string.count), withTemplate: "=")
            string = string.replacingOccurrences(of: "{", with: "")
            string = string.replacingOccurrences(of: "}", with: "")
            string = string.replacingOccurrences(of: " ", with: "")
            return string
        } else {
            return ""
        }
    }
    
    static func args(_ args: [String: Any], regrexURLByKey key: String) -> URL? {
        let urlString = self.args(args, regrexStringByKey: key)
        return URL(string: urlString)
    }
    
    // MARK: - Usage Description Check
    
    static func checkUsageDescription(_ usage: String) -> Bool {
        if let keys = Bundle.main.infoDictionary?.keys {
            return keys.contains(usage)
        } else {
            return false
        }
    }
}
