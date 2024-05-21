//
//  VpadnVideoAdCache.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/5/2.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

class VpadnVideoAdCache {
    
    static let shared = VpadnVideoAdCache()
    
    let VPADN_VIDEO_PATH = "/vpadn/"
    let VPADN_VIDEO_FILE_LIST = "videoAdList.plist"
    let MAX_FILE_EXIST_TIME = 604800  // keep alive 7 day
    let MAX_FILE_LIMIT = 10
    let VIDEO_FILE_NAME = "video_name"
    let NOTIFY_VIEWCONTROLLER = "notify_target_view"
    let NOTIFY_TARGET_SUCCESS_FUNCTION = "get_video_success_function"
    let NOTIFY_TARGET_FAILED_FUNCTION = "get_video_failed_function"
    
    var dictFileList: NSMutableDictionary?
    var dictNotifyList: NSMutableDictionary
    var documentSaveFilePath = ""
    var fileListPath = ""
    var nowPlayingVideo = ""
    var dataVideoFile: Data?
    
    private init() {
        documentSaveFilePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0].appending(VPADN_VIDEO_PATH)
        fileListPath = documentSaveFilePath.appending(VPADN_VIDEO_FILE_LIST)
        dictNotifyList = NSMutableDictionary(capacity: 1)
        getFileExistTimeFromDisk()
        updateFileList()
        if !FileManager.default.fileExists(atPath: documentSaveFilePath) {
            try? FileManager.default.createDirectory(atPath: documentSaveFilePath, withIntermediateDirectories: false) // Create folder
        }
        cleanOutOfDateFiles()
    }
    
    func checkFileExist(urlString: String) -> Bool {
        let filePath = getFilePath(with: urlString)
        return FileManager.default.fileExists(atPath: filePath)
    }
    
    func updateFileList() {
        dictFileList?.write(toFile: fileListPath, atomically: true)
    }
    
    func moveItem(at location: URL, fileName: String) {
        checkAndCleanOutOfMemoryData()
        let filePath = documentSaveFilePath + fileName
        // 剪貼Location到目的文件內
        try? FileManager.default.moveItem(at: location, to: URL(fileURLWithPath: filePath))
        let now = Date().timeIntervalSince1970
        let time = Int(now) + MAX_FILE_EXIST_TIME
        dictFileList?[fileName] = String(time)
    }
    
    func deleteFileList(fileName: String) {
        if let dictFileList, dictFileList[fileName] != nil {
            dictFileList.removeObject(forKey: fileName)
            let filePath = documentSaveFilePath.appending(fileName)
            if FileManager.default.fileExists(atPath: filePath) {
                try? FileManager.default.removeItem(atPath: filePath)
                updateFileList()
            }
        }
    }
    
    func getFile(urlString: String) -> Data? {
        let fileName = getFileName(urlString: urlString)
        nowPlayingVideo = fileName
        let filePath = documentSaveFilePath + fileName
        if checkFileExist(urlString: urlString) {
            dataVideoFile = FileManager.default.contents(atPath: filePath)
        } else {
            dataVideoFile = nil
        }
        return dataVideoFile
    }
    
    func getSaveFilePath() -> String {
        return documentSaveFilePath
    }
    
    func getFilePath(with urlString: String) -> String {
        let fileName = getFileName(urlString: urlString)
        nowPlayingVideo = fileName
        return documentSaveFilePath + fileName
    }
    
    func getFileCount() -> Int {
        return dictFileList?.count ?? 0
    }
    
    func getFileName(urlString: String) -> String {
        let array = urlString.components(separatedBy: "/")
        return array[array.count - 1]
    }
    
    private func getFileExistTimeFromDisk() {
        // 判斷 plist 檔案是否存在於對應位置
        if FileManager.default.fileExists(atPath: fileListPath) {
            // 讀取存在的 plist 檔案
            dictFileList = NSMutableDictionary(contentsOfFile: fileListPath)
        } else {
            dictFileList = NSMutableDictionary(capacity: MAX_FILE_LIMIT)
        }
    }
    
    private func checkAndCleanOutOfMemoryData() {
        if getFileCount() < MAX_FILE_LIMIT { return }
        cleanOutOfDateFiles()
        cleanOlderFileWhenFileOverLimit()
    }
    
    private func cleanOutOfDateFiles() {
        if getFileCount() <= 0 { return }
        var deleteFileList = [String]()
        deleteFileList.reserveCapacity(MAX_FILE_LIMIT)
        guard let keyList = dictFileList?.allKeys as? [String] else { return }
        let totalFileCount = keyList.count
        var checkKey = ""
        var checkVideoTime = TimeInterval(0.0)
        let nowTime = Date().timeIntervalSince1970
        for index in 0..<totalFileCount {
            checkKey = keyList[index]
            if checkKey == nowPlayingVideo { continue }
            if let tmp = dictFileList?.object(forKey: checkKey) as? Double {
                checkVideoTime = TimeInterval(tmp)
                // clean out of time data
                if checkVideoTime < nowTime {
                    deleteFileList.append(checkKey)
                    continue
                }
            }
        }
        for fileName in deleteFileList {
            if dictFileList?[fileName] != nil {
                self.deleteFileList(fileName: fileName)
            }
        }
    }
    
    private func cleanOlderFileWhenFileOverLimit() {
        var deleteFileList = [String]()
        deleteFileList.reserveCapacity(MAX_FILE_LIMIT)
        guard let keyList = dictFileList?.allKeys as? [String] else { return }
        let totalFileCount = keyList.count
        if totalFileCount >= MAX_FILE_LIMIT {
            var deleteKey = keyList[0]
            if let moreLongerVideoTime = dictFileList?[deleteKey] as? Double {
                var checkKey = ""
                var checkVideoTime = TimeInterval(0.0)
                for index in 1..<totalFileCount {
                    checkKey = keyList[index]
                    if checkKey == nowPlayingVideo { continue }
                    if let tmp = dictFileList?.object(forKey: checkKey) as? Double {
                        checkVideoTime = TimeInterval(tmp)
                        if checkVideoTime <= moreLongerVideoTime {
                            deleteKey = checkKey
                        }
                    }
                }
                deleteFileList.append(deleteKey)
                for fileName in deleteFileList {
                    if dictFileList?.object(forKey: fileName) != nil {
                        self.deleteFileList(fileName: fileName)
                    }
                }
            }
        }
    }
    
    deinit {
        dictFileList?.removeAllObjects()
        dictNotifyList.removeAllObjects()
    }
}
