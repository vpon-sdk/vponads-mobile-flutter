//
//  ViewabilityDetector.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/10/3.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

protocol ViewabilityDetectorDelegate: AnyObject {
    /// 執行完遮蔽偵測的 callback
    func viewabilityDetector(_ detector: ViewabilityDetector, didExecuteDetectionWithResult result: Bool)
    /// 通知該傳送 exposureChange 給 JS
    func viewabilityDetectorShouldSendExposureChange(_ detector: ViewabilityDetector)
}

final class ViewabilityDetector: AdLifeCycleObserver {
    
    var adLifeCycleManager: AdLifeCycleManager?
    
    weak var delegate: ViewabilityDetectorDelegate?
    
    var licenseKey: String?
    
    /// 偵測 native ad webView 用
    var nativeAdWebView: NativeAdWebView?
    
    /// 判斷是不是 Banner
    var bannerFlags = false
    
    /// 已完成遮蔽偵測
    var didFinishDetection = false
    
    /// 是否已經顯示在畫面了
    var hasBeenShown = false
    
    /// 前次曝光比例
    var lastVisiblePercent: Float = 0
    
    /// 最大曝光比例
    var maxVisiblePercent: Float = 0
    
    /// 遮蔽偵測的 Timer
    private var detectionTimer: Timer?
    
    /// 下次送曝光的 Timer
    private var exposureTimer: Timer?
    
    /// 需要排除的
    private var friendlyObstructions: [VponAdObstruction]?
    
    /// 前次遮蔽 Overlap 的情況
    private var lastOverlaps = [[String: Any]]()
    
    /// 前次遮蔽 Overlap 的 Obstructions
    private var lastOverlapObstructions: [[String: Any]]?
    
    /// 確定排除的
    private var certainObstructions: [VponAdObstruction]?
    
    /// 需不需要 Log
    private var needLog = true
    
    /// 前次拋出的警告訊息
    private var lastMessage: String = ""
    
    /// 視圖所在的 Window
    private let window: UIWindow
    
    /// 廣告 View 之於 Screen 顯示的範圍（原始）
    private let adRect: CGRect = .null
    
    /// 廣告 View 之於 Screen 顯示的範圍（檢查）
    private var actualRect: CGRect?
    
    /// 被偵測的廣告 View (adContainer)
    unowned let adView: UIView
    
    /// 通過比例
    private var fViewableRate: Float = 0
    
    /// 是否回報過錯誤
    private var isReceived = false
    
    /// 紀錄遞迴父層過程中是否有 ScrollView
    private var isScrollExist = false
    
    init(adView: UIView, in window: UIWindow, friendlyObstructions: [VponAdObstruction]? = nil, adLifeCycleManager: AdLifeCycleManager) {
        self.window = window
        self.adView = adView
        self.friendlyObstructions = friendlyObstructions
        self.adLifeCycleManager = adLifeCycleManager
    }
    
    // MARK: - 啟動 / 結束遮蔽偵測
    
    /// 啟動遮蔽偵測
    func startDetection() {
        if adView.superview == nil {
            VponConsole.log("[AD VIEWABILITY] SuperView is null")
            return
        }
        
        if didFinishDetection {
            VponConsole.log("[AD VIEWABILITY] Detect covered is finished")
            return
        }
        
        VponConsole.log("[AD VIEWABILITY] Detection invoked")
        startDetectionTimer(interval: 0.2)
    }
    
    /// 幾秒後啟動遮蔽偵測 Timer
    /// - Parameter interval: 秒數
    func startDetectionTimer(interval: TimeInterval) {
        stopViewabilityDetection()
        guard !didFinishDetection else {
            VponConsole.log("[AD VIEWABILITY] Detection is finished")
            return
        }
        detectionTimer = Timer(timeInterval: interval, target: self, selector: #selector(detectViewability), userInfo: nil, repeats: false)
        RunLoop.main.add(detectionTimer!, forMode: .common)
    }
    
    @objc private func detectViewability() {
        let result = checkViewCovered()
        if lastVisiblePercent > 0 && !hasBeenShown {
            hasBeenShown = true
            adLifeCycleManager?.notify(.onAdShow)
        }
        delegate?.viewabilityDetector(self, didExecuteDetectionWithResult: result)
    }
    
    /// 停止遮蔽遮測
    func stopViewabilityDetection() {
        guard let detectionTimer else { return }
        if detectionTimer.isValid {
            detectionTimer.invalidate()
            self.detectionTimer = nil
        }
    }
    
    func startExposureTimer() {
        if let exposureTimer, exposureTimer.isValid { return }
        stopExposureTimer()
        exposureTimer = Timer(timeInterval: 0.2, target: self, selector: #selector(sendExposureChange), userInfo: nil, repeats: true)
        RunLoop.main.add(exposureTimer!, forMode: .common)
    }
    
    /// 計算 mediaView.webView 露出比例，傳給 JS
    @objc private func sendExposureChange() {
        delegate?.viewabilityDetectorShouldSendExposureChange(self)
    }
    
    func getExposureWithPercent(_ percent: Float) -> (message: String, onScreenRect: [String: Double], adViewRect: [String: Double]) {
        guard let adWebView = nativeAdWebView else { return ("", [:], [:]) }
        
        var onScreen = [String: Double]()
        let onScreenRect = onScreenRect(view: adWebView)
        onScreen["x"] = onScreenRect.origin.x
        onScreen["y"] = onScreenRect.origin.y
        onScreen["width"] = onScreenRect.size.width
        onScreen["height"] = onScreenRect.size.height
        
        var ad = [String: Double]()
        let adViewRect = adViewRect(view: adWebView)
        ad["x"] = adViewRect.origin.x
        ad["y"] = adViewRect.origin.y
        ad["width"] = adViewRect.size.width
        ad["height"] = adViewRect.size.height
        
        let message = String(format: "%.4f,'%@', null, '%@'", percent, JsonParseHelper.dictionaryToJson(with: onScreen, prettyPrinted: false), JsonParseHelper.dictionaryToJson(with: ad, prettyPrinted: false))
        
        return (message, onScreen, ad)
    }
    
    /// 關閉送曝光防呆
    func stopExposureTimer() {
        guard let exposureTimer else { return }
        if exposureTimer.isValid {
            exposureTimer.invalidate()
            self.exposureTimer = nil
        }
    }
    
    // MARK: - Interface
    
    func checkViewCovered() -> Bool {
        return checkViewCovered(with: Float(Constants.ViewableDetection.viewableRate))
    }
    
    func checkViewCovered(with viewableRate: Float) -> Bool {
        fViewableRate = viewableRate
        certainObstructions = []
        return checkViewCovered(by: adView)
    }
    
    /// 計算特定 view 的露出比例（預設為 adView）
    /// - Parameter view: 要計算的 view（預設為 adView）
    /// - Returns: 露出比例
    func exposedPercent(of view: UIView? = nil) -> Float {
        if let view {
            return viewableInPercent(adView: view)
        } else {
            return viewableInPercent(adView: adView)
        }
    }
    
    func onScreenRect(view: UIView) -> CGRect {
        return actualRect ?? CGRect(x: 0, y: 0, width: 0, height: 0)
    }
    
    /// 將指定 view 的 frame 從 superview 的坐標系統轉換為 window 的坐標系統
    func adViewRect(view: UIView) -> CGRect {
        return window.convert(view.frame, from: view.superview)
    }
    
    // MARK: - 計算 view percent
    
    // This method is not being used.
    func videoViewPercent(adRect: CGRect, videoRect: CGRect) -> Float {
        let visibleRect = adViewRect(view: adView)
        let onScreenRect = onScreenRect(view: adView)
        let scale = visibleRect.size.width / adRect.size.width
        let currentVideoRect = CGRect(origin: CGPoint(x: visibleRect.origin.x, y: visibleRect.origin.y), size: CGSize(width: videoRect.size.width * scale, height: videoRect.size.height * scale))
        
        let intersectionRect = CGRectIntersection(currentVideoRect, onScreenRect)
        let intersectionSize = intersectionRect.size.width * intersectionRect.size.height
        let currentVideoSize = currentVideoRect.size.width * currentVideoRect.size.height
        return Float(intersectionSize / currentVideoSize * 100)
    }
    
    private func viewableInPercent(adView: UIView) -> Float {
        needLog = true
        
        // --- Step 0 : 檢查 DisplayView 是否已經 Add 在 SuperView 上
        var visibleInPercent = isDisplaying(adView: adView)
        if visibleInPercent < 1 {
            return 0
        }
        
        actualRect = actualRect(by: adView)
        
        // --- Step 1 : 檢查 DisplayView 在螢幕範圍中的顯示部分
        let onScreen = onScreenPercent(view: adView)
        visibleInPercent = onScreen
        
        // --- Step 2 : 檢查 DisplayView 之上的 view 的遮蔽
        lastOverlaps = overlapArray(view: adView)
        
        var maxOverlap: Float = 0
        
        if !lastOverlaps.isEmpty {
            for index in 0...lastOverlaps.count - 1 {
                let overlap = lastOverlaps[index]
                let ob = overlap["ob"]
                
                guard let value = overlap["value"] as? Double else { continue }
                if visibleInPercent - Float(value) < fViewableRate {
                    if let ob = ob as? [String: Any] {
                        lastOverlapObstructions?.append(ob)
                    }
                }
                maxOverlap = max(Float(value), maxOverlap)
            }
        }
        visibleInPercent = visibleInPercent < maxOverlap ? 0 : visibleInPercent - maxOverlap
        lastVisiblePercent = visibleInPercent * 100
        maxVisiblePercent = max(visibleInPercent * 100, lastVisiblePercent)
        
        return visibleInPercent * 100
    }
    
    private func checkViewCovered(by view: UIView) -> Bool {
        needLog = true
        
        // --- Step 0 : 檢查 DisplayView 是否已經 Add 在 SuperView 上
        var visibleInPercent = isDisplaying(adView: adView)
        if visibleInPercent < fViewableRate {
            return false
        }
        
        actualRect = actualRect(by: adView)
        
        // --- Step 1 : 檢查 DisplayView 在螢幕範圍中的顯示部分
        let onScreen = onScreenPercent(view: adView)
        visibleInPercent = onScreen
        if visibleInPercent < fViewableRate {
            let ratio = String(format: "%.2f%", onScreen * 100)
            log("OnScreen ratio (\(ratio)%) is not reached.")
        }
        
        // --- Step 2 : 檢查 DisplayView 之上的 view 的遮蔽
        lastOverlaps = overlapArray(view: adView)
        lastOverlapObstructions = []
        
        var maxOverlap: Float = 0
        var message = " Because: \n{"
        
        if !lastOverlaps.isEmpty {
            for index in 0...lastOverlaps.count - 1 {
                let overlap = lastOverlaps[index]
                let ob = overlap["ob"]
                let reason = overlap["reason"]
                guard let value = overlap["value"] as? Double else { continue }
                if visibleInPercent - Float(value) < fViewableRate {
                    message = message.appending("\n OnScreen(\(onScreen * 100)%) - Overlap(\(value * 100)%, \(reason ?? "") = \(value * 100)%,")
                    if let ob = ob as? [String: Any] {
                        lastOverlapObstructions?.append(ob)
                    }
                }
                maxOverlap = max(Float(value), maxOverlap)
            }
        }
        
        visibleInPercent = visibleInPercent < maxOverlap ? 0 : visibleInPercent - maxOverlap
        lastVisiblePercent = visibleInPercent * 100
        maxVisiblePercent = max(visibleInPercent * 100, lastVisiblePercent)
        
        if visibleInPercent < fViewableRate {
            log("Visible ratio (\(visibleInPercent * 100)%) is not reached. \(message)\n}")
            return false
        }
        return true
    }
    
    // MARK: - 檢查顯示
    
    private func isDisplaying(adView: UIView) -> Float {
        if window.frame.size == .zero {
            log("There is no window's width * hight by default.Need setFrame for window object.")
            needLog = true
        }
        if adView.window == nil {
            log("Adview Window not exists")
            return 0
        }
        if bannerFlags && adView.superview?.superview == nil {
            log("Superview not exists")
            return 0
        } else if adView.superview == nil {
            log("Superview not exists")
            return 0
        }
        if adView.frame.size == .zero {
            log("AdView size is 0x0")
            return 0
        }
        if bannerFlags {
            if adView.superview?.alpha ?? 1 < 1 || adView.alpha < 1 {
                log("Superview or adView alpha < 1")
                return 0
            }
            if adView.superview?.superview?.alpha ?? 1 < 1 {
                log("Superview or adView alpha < 1")
                return 0
            }
        }
        if UIApplication.shared.applicationState != .active {
            log("Application not active")
            return 0
        }
        return 1
    }
    
    
    // MARK: - 檢查可見部分
    
    private func onScreenPercent(view: UIView) -> Float {
        let expectedSize = view.frame.size.width * view.frame.size.height
        if let actualRect {
            let actualSize = actualRect.size.width * actualRect.size.height
            let exposedRatio = actualSize.isNaN ? 0 : actualSize / expectedSize
            return Float(exposedRatio)
        } else {
            return 0.0
        }
    }
    
    /// 取得 view 在螢幕上的實際可見範圍，而非只相對於原本的 superview
    private func actualRect(by view: UIView) -> CGRect {
        var scrollExists = false
        let originRect = window.convert(view.frame, from: view.superview)
        var actualRect = CGRect.null
        actualRect = self.actualRect(by: view, originRect: originRect, actualRect: &actualRect, scrollExists: &scrollExists)
        
        return actualRect
    }
    
    /// 考量 view 可能在 scrollView 裡面，無法代表 view 在螢幕上實際顯示範圍，反覆計算出實際矩形大小
    /// - Parameters:
    ///   - view: 欲計算實際矩形的 view
    ///   - originRect: 原始 view 的矩形範圍
    ///   - actualRect: 計算出的實際矩形
    ///   - scrollExists: 標記所處 view 是否為 UIScrollView
    /// - Returns: view 實際在螢幕上的矩形
    private func actualRect(by view: UIView?, originRect: CGRect, actualRect: inout CGRect, scrollExists: inout Bool) -> CGRect {
        // 檢查 view 是否為 scrollView，如果是，則更新 scrollExists 並計算實際矩形
        if let view, view is UIScrollView {
            scrollExists = true
            let scrollRect = window.convert(view.frame, from: view.superview)
            actualRect = scrollRect.intersection(originRect)
        }
        
        if view?.superview is UIWindow || view == nil {
            // 如果沒有 scrollView，則計算實際矩形並考慮 window 和 safe area 的大小
            if !scrollExists {
                actualRect = view?.superview?.frame.intersection(originRect) ?? .null
            }
            
            // 如果 view.superview 不是 keyWindow，將實際矩形設置為空
            if view?.superview != UIApplication.shared.keyWindow {
                actualRect = .zero.intersection(originRect)
            }
            
            // 如果實際矩形的最大 Y 值超過了螢幕高度 - safe area 的高度，則將其高度調整為該值減去原始 Y 值
            if actualRect.maxY > (window.frame.height - window.safeAreaInsets.bottom) {
                actualRect.size.height = (window.frame.height - window.safeAreaInsets.bottom) - actualRect.origin.y
            }
            var result = actualRect
            if actualRect.origin.x.isInfinite {
                result.origin.x = 0
            }
            if actualRect.origin.y.isInfinite {
                result.origin.y = 0
            }
            if actualRect.size.width.isInfinite {
                result.size.width = 0
            }
            if actualRect.size.height.isInfinite {
                result.size.height = 0
            }
            return result
        } else {
            // 如果 view.superview 不是 window，則遞歸計算其實際矩形
            return self.actualRect(by: view?.superview, originRect: originRect, actualRect: &actualRect, scrollExists: &scrollExists)
        }
    }

    
    // MARK: - Check Coverage func
    
    private func overlapArray(view: UIView) -> [[String: Any]] {
        var overlaps = [[String: Any]]()
        checkOtherCovered(by: view, overlaps: &overlaps)
        return overlaps
    }
    
    private func checkOtherCovered(by view: UIView, overlaps: inout [[String: Any]]) {
        if let subviews = view.superview?.subviews {
            let viewIndex = subviews.firstIndex(of: view) ?? 0
            
            for i in (viewIndex + 1)..<subviews.count {
                let otherView = subviews[i]
                var exclude = false
                
                guard let friendlyObstructions else { continue }
                for obstruction in friendlyObstructions {
                    if (obstruction.view != nil) && otherView == obstruction.view {
                        exclude = true
                        certainObstructions?.append(obstruction)
                    } else { continue }
                }
                if !exclude {
                    checkCovered(by: otherView, overlaps: &overlaps)
                }
            }
            if let superview = findSuperview(view: view) {
                if checkVisible(view: superview) == false {
                    overlaps.append(["value": 1.0, "reason": "superview not visible, because \(view)"])
                } else if !(superview is UIWindow), let vSuperview = view.superview {
                    checkOtherCovered(by: vSuperview, overlaps: &overlaps)
                }
            } else {
                overlaps.append(["value": 1.0, "reason": "superview not exist, because \(view)"])
            }
        }
    }
    
    private func checkCovered(by view: UIView, overlaps: inout [[String: Any]]) {
        // 防呆不對廣告自己做檢查
        guard view != adView else { return }
        // 代表不可見
        guard checkVisible(view: view) else { return }
        
        let viewRect = actualRect(by: view) // view 之於 Screen 顯示的範圍
        let overlapRect = CGRectIntersection(viewRect, actualRect ?? CGRect(x: 0, y: 0, width: 0, height: 0)) // viewRect 與 checkRect 交集的區域
        
        if overlapRect.origin.x.isInfinite ||
            overlapRect.origin.y.isInfinite ||
            overlapRect.origin.x.isNaN ||
            overlapRect.origin.y.isNaN ||
            CGRect.null.origin.x == overlapRect.origin.x ||
            CGRect.null.origin.y == overlapRect.origin.y { // 代表完全沒有交集
            // Do nothing
        } else {
            let expectedSize = adView.frame.size.width * adView.frame.size.height // 預期顯示大小
            let overlapSize = overlapRect.size.width * overlapRect.size.height // 實際遮蓋大小
            let coveredRatio = Double(overlapSize / expectedSize) // 實際遮蓋 / 預期顯示
            overlaps.append(["value": coveredRatio,
                             "reason": String(format: "%@", view),
                             "ob": [
                                "alpha": view.alpha,
                                "visibility": view.isHidden ? 1 : 0,
                                "class": NSStringFromClass(view.classForCoder),
                                "rect": getRectString(rect: adViewRect(view: view))
                             ] as [String : Any]])
        }
        
        // 如果 view 切齊 Bounds 就不需要檢查 subViews
        if !view.clipsToBounds {
            for subView in view.subviews {
                var scrollExist = false
                let originRect = window.convert(subView.frame, from: view.superview)
                var subViewRect = CGRect.null
                subViewRect = actualRect(by: view, originRect: originRect, actualRect: &subViewRect, scrollExists: &scrollExist)
               
                let unionRect = CGRectUnion(subViewRect, viewRect)
                if CGRectEqualToRect(unionRect, viewRect) == false {
                    checkCovered(by: subView, overlaps: &overlaps)
                }
            }
        }
    }
    
    /// 檢查 view 是否可視
    /// - Parameter view: 被檢查的View (不一定是 AdView)
    /// - Returns: YES = 可視 / NO = 不可視
    private func checkVisible(view: UIView) -> Bool {
        if view.isHidden || view.alpha < 0.1 {
            return false
        } else {
            return true
        }
    }
    
    /// 尋找父層
    /// - Parameter view: 被檢查的 View（不一定是 AdView）
    private func findSuperview(view: UIView) -> UIView? {
        return view.superview
    }
    
    private func getRectString(rect: CGRect) -> String {
        return "[\(rect.origin.x),\(rect.origin.y)][\(rect.size.width),\(rect.size.height)]"
    }
    
    private func log(_ message: String) {
        if needLog && lastMessage != message {
            var tmpLicenseKey = " "
            if let licenseKey = self.licenseKey, !licenseKey.isEmpty {
                tmpLicenseKey = tmpLicenseKey.appendingFormat("%@: ", licenseKey)
            }
            VponConsole.log("[AD VIEWABILITY] \(tmpLicenseKey)\(message)", .error)
            lastMessage = message
        }
        needLog = false
    }
    
    // MARK: - AdLifeCycleObserver
    
    func receive(_ event: AdLifeCycle, data: [String : Any]?) {
        // 這個 class 目前沒有監聽的事件
    }
    
    // MARK: - Deinit
    
    deinit {
        adLifeCycleManager?.unregisterAllEvents(self)
        VponConsole.log("[ARC] ViewabilityDetector deinit")
    }
}
