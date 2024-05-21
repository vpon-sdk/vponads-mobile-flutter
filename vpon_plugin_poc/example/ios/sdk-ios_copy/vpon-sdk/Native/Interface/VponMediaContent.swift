//
//  VponMediaContent.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/10/31.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

@objcMembers public final class VponMediaContent: NSObject {
    
    /// cover_url from ad url
    internal var contentURL: URL
    /// 目前只有 Native video 有 webView
    private weak var webView: NativeAdWebView?
    private var isMp4Video: Bool
    
    /// Indicates whether the media content has video content.
    public var hasVideoContent: Bool
    
    /// Controls the media content’s video.
    public var videoController: VponVideoController?
    
    /// The main image to be displayed when the media content doesn’t contain video. Only available to native ads.
    public var mainImage: UIImage?
    
    internal var webViewDidLoadFinished: ((WKWebView) -> Void)?
    internal var webViewDidChangeToNormal: ((WKWebView) -> Void)?
    
    internal init(hasVideoContent: Bool, contentURL: URL, webView: NativeAdWebView?, isMp4Video: Bool) {
        self.hasVideoContent = hasVideoContent
        self.contentURL = contentURL
        self.webView = webView
        self.isMp4Video = isMp4Video
        
        if hasVideoContent {
            videoController = VponVideoController()
        }
    }
    
    /// 根據 hasVideoContent 讀取 image 或 webView
    /// - Parameter completion: 讀取好的 image（Native display 才有）
    internal func load(completion: @escaping (UIImage?) -> Void) {
        if hasVideoContent {
            // load webView
            guard let webView else { return }
            
            // cover_url is mp4
            if isMp4Video {
                webView.loadContentHTML()
                completion(nil)
            } else {
                // gif
                webView.loadURL(contentURL)
                completion(nil)
            }
        } else {
            // load image
            loadImage(url: contentURL, completion: completion)
        }
    }
    
    private func loadImage(url: URL, completion: @escaping (UIImage?) -> Void) {
        let session = URLSession.shared
        let task = session.dataTask(with: url) { (data, response, error) in
            guard let data, error == nil else {
                VponConsole.log("[VponMediaContent] Load image error: \(error?.localizedDescription ?? "n/a")", .error)
                completion(nil)
                return
            }
          
            self.mainImage = UIImage(data: data)
            completion(self.mainImage)
        }
        task.resume()
    }
    
    // MARK: - Notify video event
    
    internal func notifyVideoDidPlay() {
        videoController?.notifyVideoDidPlay()
    }
    
    internal func notifyVideoDidPause() {
        videoController?.notifyVideoDidPause()
    }
    
    internal func notifyVideoDidEndVideoPlayback() {
        videoController?.notifyVideoDidEndVideoPlayback()
    }
    
    internal func notifyVideoDidMute() {
        videoController?.notifyVideoDidMute()
    }
    
    internal func notifyVideoDidUnmute() {
        videoController?.notifyVideoDidUnmute()
    }
    
    // MARK: - Deinit
    
    deinit {
        VponConsole.log("[ARC] VponMediaContent deinit")
    }
}
