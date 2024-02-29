//
//  LocalStorageHelper.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/4/14.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

struct LocalStorageInfo {
    
    static let shared = LocalStorageInfo()
    
    private var fileManager = FileManager()
    private var documentPath: String
    private var filePath: String
    private var config: NSMutableDictionary
    
    private init() {
        self.config = NSMutableDictionary()
        self.documentPath = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).map(\.path)[0] + "/vpadn/config"
        self.filePath = documentPath + "/info.plist"
        
        if self.fileManager.fileExists(atPath: documentPath), let dictionary = NSMutableDictionary(contentsOfFile: filePath) {
            // if plist exists -> save to config
            self.config = dictionary
        } else {
            // if plist not exists -> create new one and save
            try? fileManager.createDirectory(atPath: documentPath, withIntermediateDirectories: true, attributes: nil)
            config.write(toFile: filePath, atomically: true)
        }
    }
    
    func isExists(key: String) -> Bool {
        let allKeys = (config.allKeys as? [String]) ?? []
        return allKeys.contains(key)
    }
    
    func read(key: String) -> String {
        if isExists(key: key), let value = config[key] as? String {
            return value
        } else {
            return ""
        }
    }
    
    func update(key: String, value: String) {
        let tmp = config
        tmp.setValue(value, forKey: key)
        tmp.write(toFile: filePath, atomically: true)
    }
    
    // This method is not being used.
    func remove(key: String) {
        guard isExists(key: key) else { return }
        let tmp = config
        tmp.removeObject(forKey: key)
        tmp.write(toFile: filePath, atomically: true)
    }
}
