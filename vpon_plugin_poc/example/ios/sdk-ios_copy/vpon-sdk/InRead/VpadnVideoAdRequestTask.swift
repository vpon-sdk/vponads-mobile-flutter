//
//  VpadnVideoAdRequestTask.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/5/2.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import AVFoundation

protocol VpadnVideoAdRequestTaskDelegate: AnyObject {
    func task(_ task: VpadnVideoAdRequestTask, didReceiveVideoLength videoLength: Int64, mimeType: String)
    func taskDidReceiveVideoDataWithTask(_ task: VpadnVideoAdRequestTask)
    func taskDidFinishLoading(_ task: VpadnVideoAdRequestTask)
    func taskDidFailLoading(_ task: VpadnVideoAdRequestTask, error: Error)
}

class VpadnVideoAdRequestTask: NSObject {
    
    let TIMEOUT = 15.0
    
    weak var delegate: VpadnVideoAdRequestTaskDelegate?
    var url: URL?
    var offset: Int = 0
    var videoLength: Int64 = 0
    var downLoadingOffset: Int = 0
    var mimeType: String?
    var didFinishLoading = false
    
    private var session: URLSession?
    private var task: URLSessionDataTask?
    private var taskArray = [URLSessionDataTask]()
    private var once = false
    private var fileHandle: FileHandle?
    private var tempPath: String?
    
    func setURL(_ url: URL, offset: Int) {
        self.url = url
        self.offset = offset
        tempPath = VpadnVideoAdCache.shared.getSaveFilePath().appending(url.lastPathComponent)
        
        // 如果建立第二次请求，先移除原来文件，再创建新的
        if let tempPath, taskArray.count >= 1 {
            try? FileManager.default.removeItem(atPath: tempPath)
            FileManager.default.createFile(atPath: tempPath, contents: nil)
        }
        
        downLoadingOffset = 0
        
        guard var actualURLComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
        let requestURL = actualURLComponents.url else { return }
        actualURLComponents.scheme = "https"
        
        var request = URLRequest(url: requestURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: TIMEOUT)
        if offset > 0 && videoLength > 0 {
            request.addValue("bytes=\(offset)-\(videoLength - 1)", forHTTPHeaderField: "Range")
        }
        task?.cancel()
        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        task = session?.dataTask(with: request)
        task?.resume()
    }
    
    func continueLoading() {
        once = true
        guard let url,
              var actualURLComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
        let requestURL = actualURLComponents.url else { return }
        actualURLComponents.scheme = "https"
        
        
        var request = URLRequest(url: requestURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: TIMEOUT)
        request.addValue("bytes=\(downLoadingOffset)-\(videoLength - 1)", forHTTPHeaderField: "Range")
        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        task = session?.dataTask(with: request)
        task?.resume()
    }
}

extension VpadnVideoAdRequestTask: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let tempPath else { return }
        
        didFinishLoading = false
        
        let httpResponse = HTTPURLResponse()
        let dict = httpResponse.allHeaderFields
        let content = dict["Content-Range"] as? String
        let array = content?.components(separatedBy: "/")
        
        if let length = array?.last  {
            if Int(length) == 0 {
                videoLength = httpResponse.expectedContentLength
            } else {
                videoLength = Int64(length) ?? 0
            }
        }
        mimeType = "video/mp4"
        delegate?.task(self, didReceiveVideoLength: videoLength, mimeType: mimeType!)
        if let task {
            taskArray.append(task)
        }
        
        if FileManager.default.fileExists(atPath: tempPath) {
            try? FileManager.default.removeItem(atPath: tempPath)
        }
        FileManager.default.createFile(atPath: tempPath, contents: nil)
        fileHandle = FileHandle(forWritingAtPath: tempPath)
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        // 寫入數據
        fileHandle?.seekToEndOfFile()
        fileHandle?.write(data)
        downLoadingOffset += data.count
        delegate?.taskDidReceiveVideoDataWithTask(self)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error as? NSError {
            if error.code == -1001 && !once {
                // 網路超時，重試一次
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.continueLoading()
                }
            }
            delegate?.taskDidFailLoading(self, error: error)
            
            // 網路中斷：-1005
            // 無網路連接：-1009
            // 請求超時：-1001
            // 服務器內部錯誤：-1004
            // 找不到服務器：-1003
            VponConsole.log("\(#file), \(#function) 錯誤代碼：\(error.code), 原因：\(error.localizedDescription)")
        } else {
            if taskArray.count < 2,
            let tempPath,
            let url = URL(string: tempPath ){
                didFinishLoading = true
                VpadnVideoAdCache.shared.moveItem(at: url, fileName: task.response?.suggestedFilename ?? "")
            }
            delegate?.taskDidFinishLoading(self)
        }
        fileHandle?.closeFile()
    }
}
