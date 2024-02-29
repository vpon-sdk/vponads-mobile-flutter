//
//  VPNativeAd.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/4/10.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

@available(*, deprecated, message: "Use VponNativeAdLoaderDelegate and VponNativeAdDelegate instead.")
@objc public protocol VpadnNativeAdDelegate: AnyObject {

    /// 通知有廣告可供拉取 call back
    @objc optional func onVpadnNativeAdLoaded(_ nativeAd: VpadnNativeAd)

    /// 通知拉取廣告失敗 call back
    @objc optional func onVpadnNativeAd(_ nativeAd: VpadnNativeAd, failedToLoad error: Error)

    @available(*, deprecated, message: "No replacement.")
    @objc optional func onVpadnNativeAdWillLeaveApplication(_ nativeAd: VpadnNativeAd)

    /// 通知廣告已送出曝光事件
    @objc optional func onVpadnNativeAdDidImpression(_ nativeAd: VpadnNativeAd)

    /// 通知廣告已送出點擊事件
    @objc optional func onVpadnNativeAdClicked(_ nativeAd: VpadnNativeAd)
}

@available(*, deprecated, message: "Use VponNativeAdLoader and VponNativeAd instead.")
@objcMembers public final class VpadnNativeAd: NSObject {

    // MARK: - Properties

    /// Delegate token
    public weak var delegate: VpadnNativeAdDelegate?
    
    @available(*, deprecated, message: "No replacement.")
    public var strBannerId: String? // 目前已沒在用
    
    @available(*, deprecated, message: "No replacement.")
    public var platform: String?  // 目前已沒在用
    /// Branding 圖片
    public var icon: VpadnAdImage?
    /// Campaign 圖片
    public var coverImage: VpadnAdImage?
    /// 星數得分
    public var ratingValue: Double = 0.0
    /// 星數範圍
    public var ratingScale: Int = 0
    /// 主標題
    public var title: String?
    /// 內文
    public var body: String?
    /// 點擊鈕文案
    public var callToAction: String?
    /// 副標題
    public var socialContext: String?
    
    // MARK: - v5.6 integration
    
    private var licenseKey: String
    private var adLoader: VponNativeAdLoader?
    private var nativeAd: VponNativeAd?
    internal var mediaContent: VponMediaContent?

    // MARK: - Initializer
    
    /// 初始化方法
    /// @param licenseKey 版位ID (BannerID, PlacementID)
    public init(licenseKey: String) {
        self.licenseKey = licenseKey
        super.init()
        
        adLoader = VponNativeAdLoader(licenseKey: licenseKey, rootViewController: nil)
        adLoader?.delegate = self
    }
    
    // MARK: - Public Methods

    /// 取得廣告
    public func loadRequest(_ request: VpadnAdRequest) {
        initialData()
        let newRequest = request.toNewInterface()
        adLoader?.load(newRequest)
    }

    @available(*, deprecated, message: "No replacement.")
    public func isReady() -> Bool {
        // 目前已沒在用
        return true
    }
    
    /// 向 SDK 註冊 View 為廣告Container，且 View 的所有物件均可被點擊觸發事件。
    /// - Parameters:
    ///   - view: 廣告 Container
    ///   - viewController: 根控制項
    public func registerViewForInteraction(_ view: UIView, withViewController viewController: UIViewController) {
        if view.isKind(of: UITableViewCell.self),
           let cell = view as? UITableViewCell {
            let contentView = cell.contentView
            nativeAd?.registerAdView(contentView)
        } else {
            nativeAd?.registerAdView(view)
        }
    }

    /// 向 SDK 取消註冊的 Container 及所有能被點擊的元件。
    public func unregisterView() {
        nativeAd?.unregisterView()
    }

    // MARK: - Internal Methods
    
    internal func loadMediaView(_ mediaView: VponMediaView) {
        mediaView.mediaContent = nativeAd?.mediaContent
        nativeAd?.loadMediaView(mediaView)
    }

    private func initialData() {
        body = nil
        callToAction = nil
        coverImage = nil
        icon = nil
        ratingScale = 0
        ratingValue = 0.0
        socialContext = nil
        title = nil
    }

    // MARK: - Deinit

    deinit {
        unregisterView()
        VponConsole.log("[ARC] VpadnNativeAd deinit")
    }
}

// MARK: - v5.6 integration

extension VpadnNativeAd: VponNativeAdLoaderDelegate {
    
    public func adLoader(_ adLoader: VponNativeAdLoader, didReceive nativeAd: VponNativeAd) {
        nativeAd.delegate = self
        self.nativeAd = nativeAd
        self.mediaContent = nativeAd.mediaContent
        
        self.title = nativeAd.headline
        self.body = nativeAd.body
        self.callToAction = nativeAd.callToAction
        self.socialContext = nativeAd.socialContext
        self.ratingScale = nativeAd.ratingScale
        self.ratingValue = nativeAd.ratingValue
        
        if let coverImage = nativeAd.coverImage {
            let image = VpadnAdImage(url: coverImage.imageURL,
                                     width: coverImage.width,
                                     height: coverImage.height)
            self.coverImage = image
        }
       
        if let icon = nativeAd.icon {
            let image = VpadnAdImage(url: icon.imageURL,
                                     width: icon.width,
                                     height: icon.height)
            self.icon = image
        }
        
        delegate?.onVpadnNativeAdLoaded?(self)
    }
    
    public func adLoader(_ adLoader: VponNativeAdLoader, didFailToReceiveAdWithError error: Error) {
        delegate?.onVpadnNativeAd?(self, failedToLoad: error)
    }
}

extension VpadnNativeAd: VponNativeAdDelegate {
    
    public func nativeAdDidRecordImpression(_ nativeAd: VponNativeAd) {
        delegate?.onVpadnNativeAdDidImpression?(self)
    }
    
    public func nativeAdDidRecordClick(_ nativeAd: VponNativeAd) {
        delegate?.onVpadnNativeAdClicked?(self)
    }
}

// MARK: - VpadnAdImage

@available(*, deprecated, message: "Use VponAdImage instead.")
@objcMembers public final class VpadnAdImage: NSObject {

    /// image's url
    public var url: URL
    /// image's weight
    internal var width: Int
    /// image's height
    internal var height: Int

    internal var image: UIImage?
    internal var downloadQueue: OperationQueue?


    /// init method
    /// - Parameters:
    ///   - url: image's url
    ///   - width: image's width
    ///   - height: image's height
    internal init(url: URL, width: Int, height: Int) {
        self.url = url
        self.width = width
        self.height = height
        super.init()
    }

    /// load image method
    /// - Parameter block: 成功執行的邏輯
    public func loadImageAsync(withBlock block: @escaping (UIImage?) -> Void) {
        if let image {
            block(image)
        } else {
            downloadQueue = OperationQueue()

            let session = URLSession.shared
            let task = session.dataTask(with: url) { [weak self] data, response, error in
                if error == nil {
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        if let data {
                            self.image = UIImage(data: data)
                        }
                        self.width = Int(self.image?.size.width ?? 0)
                        self.height = Int(self.image?.size.height ?? 0)
                        block((self.image)!)
                    }
                }
            }
            task.resume()
        }
    }

    #warning("Not being called")
    func stopImageLoading() {
        if let downloadQueue, downloadQueue.operations.count > 0 {
            let lastOperation = downloadQueue.operations.last
            lastOperation?.cancel()
        }
    }
    
    // MARK: - Deinit
    
    deinit {
        VponConsole.log("[ARC] VpadnAdImage deinit")
    }
}
