//
//  VpadnVideoAdURLSession.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/5/2.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import AVFoundation
import CoreServices

protocol VpadnVideoAdURLSessionDelegate: AnyObject {
    func taskDidFinishLoading(_ task: VpadnVideoAdRequestTask)
    func taskDidFailLoading(_ task: VpadnVideoAdRequestTask, error: Error)
}

class VpadnVideoAdURLSession: NSObject {
    
    let VPADNSCHEME = "vpadnscheme"
    
    weak var delegate: VpadnVideoAdURLSessionDelegate?
    var task: VpadnVideoAdRequestTask?
    private var pendingRequests = [AVAssetResourceLoadingRequest]()
    private var videoPath: String?
    
    func getSchemeVideoURL(url: URL) -> URL? {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.scheme = VPADNSCHEME
        return components?.url
    }
    
    private func fillInContentInformation(contentInformationRequest: AVAssetResourceLoadingContentInformationRequest) {
        guard let task, let mimeType = task.mimeType else { return }
        let contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)?.takeRetainedValue()
        contentInformationRequest.isByteRangeAccessSupported = true
        contentInformationRequest.contentType = contentType as String?
        contentInformationRequest.contentLength = task.videoLength
    }
    
    private func dealWithLoadingRequest(_ loadingRequest: AVAssetResourceLoadingRequest) {
        guard let interceptedURL = loadingRequest.request.url else { return }
        let range = NSRange(location: Int(loadingRequest.dataRequest?.currentOffset ?? 0), length: Int.max)
        
        if let task {
            // 如果新的 range 的起始位置比當前緩存的位置還大 300k，則重新按照 range 請求數據
            // 如果往回拖也重新請求
            if task.offset + task.downLoadingOffset + 1024 * 300 < range.location || range.location < task.offset {
                task.setURL(interceptedURL, offset: range.location)
            }
        } else {
            task = VpadnVideoAdRequestTask()
            task?.delegate = self
            task?.setURL(interceptedURL, offset: 0)
        }
    }
    
    // MARK: - AVURLAsset resource loader methods
    
    private func processPendingRequests() {
        var requestsCompleted = [AVAssetResourceLoadingRequest]() // 請求完成的數組
        // 每次下載一塊數據都是一次請求，把這些請求放到數組，遍歷數組
        for loadingRequest in pendingRequests {
            if let infoRequest = loadingRequest.contentInformationRequest {
                fillInContentInformation(contentInformationRequest: infoRequest) // 對每次請求加上長度，文件類型等信息
            }
            if let dataRequest = loadingRequest.dataRequest {
                let didRespondCompletely = respondWithData(for: dataRequest) // 判斷此次請求的數據是否處理完全
                if didRespondCompletely {
                    requestsCompleted.append(loadingRequest) // 如果完整，把此次請求放進 請求完成的數組
                    loadingRequest.finishLoading()
                }
            }
        }
        pendingRequests.removeAll { requestsCompleted.contains($0) } // 在所有請求的數組中移除已經完成的
    }
    
    private func respondWithData(for dataRequest: AVAssetResourceLoadingDataRequest) -> Bool {
        guard let task, let url = task.url else { return false }
        var startOffset = dataRequest.requestedOffset
        if dataRequest.currentOffset != 0 {
            startOffset = dataRequest.currentOffset
        }
        VponConsole.log("[InRead] \(#file), \(#function) 目前播放多少: \(startOffset)")
        if task.offset + task.downLoadingOffset < startOffset {
            VponConsole.log("[InRead] \(#file), \(#function) NO DATA FOR REQUEST")
            return false
        }
        
        VponConsole.log("[InRead] \(#file), \(#function) 任務下載起始點： \(task.offset)")
        VponConsole.log("[InRead] \(#file), \(#function) 目前任務下載多少： \(task.downLoadingOffset)")
        if startOffset < task.offset { return false }
        
        
        videoPath = VpadnVideoAdCache.shared.getSaveFilePath().appending(url.lastPathComponent)
        if let videoPath {
            do {
                let fileData = try Data(contentsOf: URL(fileURLWithPath: videoPath), options: [.mappedIfSafe])
                // This is the total data we have from startOffset to whatever has been downloaded so far
                let unreadBytes = task.downLoadingOffset - Int(startOffset) - task.offset
                VponConsole.log("[InRead] \(#file), \(#function) 還剩下多少可讀：\(unreadBytes)")
                VponConsole.log("[InRead] \(#file), \(#function) 請求長度： \(dataRequest.requestedLength)")
                // Respond with whatever is available if we can't satisfy the request fully yet
                let numberOfBytesToRespondWith = min(dataRequest.requestedLength, unreadBytes)
                if let range = Range(NSMakeRange(Int(startOffset) - task.offset, numberOfBytesToRespondWith)) {
                    dataRequest.respond(with: fileData[range])
                    let endOffset = Int(startOffset) + dataRequest.requestedLength
                    VponConsole.log("[InRead] \(#file), \(#function) endOffset：\(endOffset)")
                    let didRespondFully = (task.offset + task.downLoadingOffset) >= endOffset
                    return didRespondFully
                }
            } catch {}
        }
        return false
    }
}

extension VpadnVideoAdURLSession: AVAssetResourceLoaderDelegate {
    /// ```
    /// 必須返回 true，如果返回 false，則 resourceLoader 將會加載出現故障的數據
    /// 這裡會出現很多個 loadingRequest 請求， 需要為每一次請求作出處理
    /// ```
    /// - Parameters:
    ///   - resourceLoader: 資源管理器
    ///   - loadingRequest: 每一小塊數據的請求
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        pendingRequests.append(loadingRequest)
        dealWithLoadingRequest(loadingRequest)
        VponConsole.log("\(#file), \(#function) ----\(loadingRequest)")
        return true
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        pendingRequests.removeAll{ $0 == loadingRequest }
    }
}

// MARK: - VpadnVideoAdRequestTaskDelegate

extension VpadnVideoAdURLSession: VpadnVideoAdRequestTaskDelegate {
    func task(_ task: VpadnVideoAdRequestTask, didReceiveVideoLength videoLength: Int64, mimeType: String) {
        
    }
    
    func taskDidReceiveVideoDataWithTask(_ task: VpadnVideoAdRequestTask) {
        processPendingRequests()
    }
    
    func taskDidFinishLoading(_ task: VpadnVideoAdRequestTask) {
        delegate?.taskDidFinishLoading(task)
    }
    
    func taskDidFailLoading(_ task: VpadnVideoAdRequestTask, error: Error) {
        delegate?.taskDidFailLoading(task, error: error)
    }
}
