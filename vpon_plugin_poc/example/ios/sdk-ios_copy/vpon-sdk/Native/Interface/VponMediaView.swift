//
//  VponMediaView.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/10/27.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

@objcMembers public final class VponMediaView: UIView, VideoStateObserver {
    
    public var mediaContent: VponMediaContent? {
        didSet { // by publisher
            unregisterAllEvents() // Clean up for next load
        }
    }
    
    internal var videoStateManager: VideoStateManager?
    
    internal func setupVideoStateManager(_ videoStateManager: VideoStateManager?) {
        self.videoStateManager = videoStateManager
        videoStateManager?.register(self, .onVideoResume)
        videoStateManager?.register(self, .onVideoPause)
        videoStateManager?.register(self, .onVideoComplete)
        videoStateManager?.register(self, .onVideoVolumeChange)
    }
    
    /// Public for mediation
    public func unregisterAllEvents() {
        videoStateManager?.unregisterAllEvents(self)
    }
    
    // MARK: - Load
    
    internal func load() {
        guard let mediaContent else {
            VponConsole.log("[VponMediaView] mediaContent is nil!", .error)
            return
        }
        
        mediaContent.load { [weak self] image in
            guard let self, let image else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.showImage(image)
            }
        }
        
        mediaContent.webViewDidLoadFinished = { [weak self] webView in
            guard let self else { return }
            self.showWebView(webView)
        }
        
        mediaContent.webViewDidChangeToNormal = { [weak self] webView in
            guard let self else { return }
            self.showWebView(webView)
        }
    }
    
    private func showImage(_ image: UIImage) {
        // add imageView
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = image
        
        self.addSubview(imageView)
        NSLayoutConstraint.vpc_bounds(with: imageView, to: self)
    }
    
    private func showWebView(_ webView: WKWebView) {
        webView.removeFromSuperview()
        VponConsole.log("[MediaView] Finish loading resource", .info)
        addSubview(webView)
        VponConsole.log("[MediaView] Container is ready", .info)
        NSLayoutConstraint.vpc_bounds(with: webView, to: self)
    }
    
    // MARK: - VideoStateObserver
    
    func receive(_ event: VideoState, data: [String : Any]?) {
        switch event {
        case .onVideoPause:
            mediaContent?.notifyVideoDidPause()
            
        case .onVideoResume:
            mediaContent?.notifyVideoDidPlay()
            
        case .onVideoComplete:
            mediaContent?.notifyVideoDidEndVideoPlayback()
            
        case .onVideoVolumeChange:
            if let volume = data?["volume"] as? CGFloat {
                
                if volume == 0 {
                    mediaContent?.notifyVideoDidMute()
                }
                
                if volume == 1 {
                    mediaContent?.notifyVideoDidUnmute()
                }
            }
            
        default:
            return
        }
    }
    
    // MARK: - Deinit
    
    deinit {
        VponConsole.log("[ARC] VponMediaView deinit")
    }
}
