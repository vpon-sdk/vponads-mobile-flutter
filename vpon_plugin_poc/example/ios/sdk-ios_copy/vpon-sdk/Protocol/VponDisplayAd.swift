//
//  VponDisplayAd.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/9/25.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import AVKit

protocol VponDisplayAd: WebViewHandlerDelegate {
    
    var webView: DisplayAdWebView { get }
    var webViewHandler: DisplayAdWebViewHandler? { get }
    
    var initialProperty: InitialProperty { get }
    var pendingInitialProperties: [WKScriptMessage] { get set }
    
    var rootViewController: UIViewController? { get }
    
    /// WebView 載入內容
    func loadContent(html: String?, baseURL: URL?)
    
    // ------ App life cycle notification ------
    
    func addAppLifeCycleObserver()
    func removeAppLifeCycleObserver()
    
    /// App 將變更成停止通知
    func applicationWillResignActive(_ notification: Notification)
    
    /// App 已變更成 Active 通知
    func applicationDidBecomeActive(_ notification: Notification)
    
    /// 已進入背景通知
    func applicationDidEnterBackground(_ notification: Notification)
    
    /// 將進入前景通知
    func applicationWillEnterForeground(_ notification:  Notification)
    
    // ------ Called by javascript ------
    
    func setInitialProperties(_ message: WKScriptMessage)
    
    func updateInitialProperty()
    
    /// 把 creative 傳來的 url 另外用 Safari 打開
    /// - Parameter scheme: url scheme 參數模型
    func openBrowser(_ scheme: AdScheme)
    
    /// 關閉廣告
    func close(_ message: WKScriptMessage)
    
    /// 當廣告無法呈現時，可以刪除或換新廣告
    func unload(_ message: WKScriptMessage)
    
    /// 讓 container 擴展
    func expand(_ scheme: AdScheme)
    
    /// 讓 container 適應新的廣告大小
    func resize(_ message: WKScriptMessage)
    
    /// 開啟系統影音播放器
    /// - Parameter scheme: url scheme 參數模型
    func playVideo(_ scheme: AdScheme)
    
    /// 儲存圖片
    /// - Parameter picture: 圖片 參數模型
    func storePicture(_ picture: AdPicture)
    
    /// 新增行事曆事件
    /// - Parameter calendar: 行事曆 參數模型
    func createCalendarEvent(_ calendar: AdCalendar)
}

// MARK: - Handle webView calls

extension VponDisplayAd {
    
    func setInitialProperties(_ message: WKScriptMessage) {
        pendingInitialProperties.append(message)
    }
    
    func createCalendarEvent(_ calendar: AdCalendar) {
        guard let vc = UIApplication.topViewController() else { return }
        AdCalendarHelper.addCalendar(calendar: calendar) {
            UIAlertController.show("Success", rootVC: vc)
        } failure: { error in
            UIAlertController.show("Failed", rootVC: vc)
        }
    }
    
    func storePicture(_ picture: AdPicture) {
        guard let vc = UIApplication.topViewController() else { return }
        AdPictureHelper.store(picture: picture) { success, error in
            if success {
                UIAlertController.show("Success", rootVC: vc)
            } else {
                if picture.canOpen, let url = picture.url {
                    UIApplication.shared.open(url)
                } else {
                    UIAlertController.show("Failed", rootVC: vc)
                }
            }
        }
    }
    
    func resize(_ message: WKScriptMessage) { /* Currently unused */ }
    
    func playVideo(_ scheme: AdScheme) {
        guard let vc = UIApplication.topViewController() else { return }
        let playerVC = AVPlayerViewController()
        if let url = scheme.url {
            playerVC.player = AVPlayer(url: url)
            vc.present(playerVC, animated: true) {
                playerVC.player?.play()
            }
        }
    }
    
    func executeHandler<T>(_ jsHandler: T, message: WKScriptMessage) where T : JavaScriptFunc {
        
        switch jsHandler {
            
        case let displayAdJSFunc as DisplayAdJavaScriptFunc:
            
            switch displayAdJSFunc {
                
            case .setInitialProperties:
                setInitialProperties(message)
                
            case .mraid_open:
                let scheme = AdScheme(message: message)
                openBrowser(scheme)
                
            case .mraid_close:
                close(message)
                
            case .mraid_unload:
                unload(message)
                
            case .mraid_expand:
                let scheme = AdScheme(message: message)
                expand(scheme)
                
            case .mraid_resize:
                resize(message)
                
            case .mraid_playVideo:
                let scheme = AdScheme(message: message)
                playVideo(scheme)
                
            case .mraid_storePicture:
                let picture = AdPicture(message: message)
                storePicture(picture)
                
            case .mraid_createCalendarEvent:
                let calendar = AdCalendar(message: message)
                createCalendarEvent(calendar)
                
            default:
                // Should already be handled in WebViewHandler
                break
            }
        default:
            break
        }
    }
}

// MARK: - App life cycle

extension VponDisplayAd {
    // 目前沒有執行任何動作
    func applicationDidEnterBackground(_ notification: Notification) {}
    func applicationWillEnterForeground(_ notification:  Notification) {}
}
