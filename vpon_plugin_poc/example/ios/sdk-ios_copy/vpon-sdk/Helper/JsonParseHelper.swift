//
//  JsonParseHelper.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/2/6.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

struct JsonParseHelper {
    
    static func parseJson(with jsonString: String) -> Any? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        do {
            let result = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            return result
        } catch {
            VponConsole.log("JsonParseHelper.parseJson error: \(error.localizedDescription) with jsonString: \(jsonString)")
            return nil
        }
    }
    
    static func jsonToString(with jsonString: String) -> String {
        if let result = JsonParseHelper.parseJson(with: jsonString) as? String {
            return result
        } else {
            return ""
        }
    }
    
    static func jsonToDictionary(with jsonString: String) -> [String: Any] {
        if let result = JsonParseHelper.parseJson(with: jsonString) as? [String: Any] {
            return result
        } else {
            return [:]
        }
    }
    
    static func jsonToArray(with jsonString: String) -> [Any] {
        if let result = JsonParseHelper.parseJson(with: jsonString) as? [Any] {
            return result
        } else {
            return []
        }
    }
    
    static func dictionaryToJson(with data: [AnyHashable: Any], prettyPrinted: Bool) -> String {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: prettyPrinted ? [.prettyPrinted, .sortedKeys] : [.sortedKeys])
            return String(data: jsonData, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
    
    static func arrayToJson(with data: NSArray, prettyPrinted: Bool) -> String {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: prettyPrinted ? .prettyPrinted : JSONSerialization.WritingOptions(rawValue: 0))
            return String(data: jsonData, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
}
