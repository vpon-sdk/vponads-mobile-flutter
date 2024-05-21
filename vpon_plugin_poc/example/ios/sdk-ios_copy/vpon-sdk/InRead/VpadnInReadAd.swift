//
//  VpadnInReadAd.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/5/3.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import UIKit

@objc public enum VpadnInReadAdType: Int {
    case customAd = 0
    case inScroll
    case inTable
    case inTableRepeat
    case inTableCustomAd
}

@objc public protocol VpadnInReadAdDelegate: AnyObject {
    @objc optional func vpadnInReadAd(_ ad: VpadnInReadAd, didFailLoading error: Error)
    @objc optional func vpadnInReadAdWillLoad(_ ad: VpadnInReadAd)
    @objc optional func vpadnInReadAdDidLoad(_ ad: VpadnInReadAd)
    @objc optional func vpadnInReadAdWillStart(_ ad: VpadnInReadAd)
    @objc optional func vpadnInReadAdDidStart(_ ad: VpadnInReadAd)
    @objc optional func vpadnInReadAdWillStop(_ ad: VpadnInReadAd)
    @objc optional func vpadnInReadAdDidStop(_ ad: VpadnInReadAd)
    @objc optional func vpadnInReadAdDidPause(_ ad: VpadnInReadAd)
    @objc optional func vpadnInReadAdDidResume(_ ad: VpadnInReadAd)
    @objc optional func vpadnInReadAdDidMute(_ ad: VpadnInReadAd)
    @objc optional func vpadnInReadAdDidUnmute(_ ad: VpadnInReadAd)
    @objc optional func vpadnInReadAdCanExpand(_ ad: VpadnInReadAd, withRatio ratio: CGFloat)
    @objc optional func vpadnInReadAdWillExpand(_ ad: VpadnInReadAd)
    @objc optional func vpadnInReadAdDidExpand(_ ad: VpadnInReadAd)
    @objc optional func vpadnInReadAdCanCollapse(_ ad: VpadnInReadAd)
    @objc optional func vpadnInReadAdWillCollapse(_ ad: VpadnInReadAd)
    @objc optional func vpadnInReadAdDidCollapse(_ ad: VpadnInReadAd)
    @objc optional func vpadnInReadAdWasClicked(_ ad: VpadnInReadAd)
    @objc optional func vpadnInReadAdDidClickBrowserClose(_ ad: VpadnInReadAd)
    @objc optional func vpadnInReadAdWillTakeOverFullScreen(_ ad: VpadnInReadAd)
    @objc optional func vpadnInReadAdDidTakeOverFullScreen(_ ad: VpadnInReadAd)
    @objc optional func vpadnInReadAdWillDismissFullscreen(_ ad: VpadnInReadAd)
    @objc optional func vpadnInReadAdDidDismissFullscreen(_ ad: VpadnInReadAd)
    @objc optional func vpadnInReadAdSkipButtonTapped(_ ad: VpadnInReadAd)
    @objc optional func vpadnInReadAdSkipButtonDidShow(_ ad: VpadnInReadAd)
    @objc optional func vpadnInReadAdDidReset(_ ad: VpadnInReadAd)
    @objc optional func vpadnInReadAdDidClean(_ ad: VpadnInReadAd)
}

@objcMembers public class VpadnInReadAd: NSObject {
    
    // MARK: - Properties
    
    public var vpadnInReadAdType: VpadnInReadAdType
    public var isLoaded = false
    public var indexPath: IndexPath?
    public weak var delegate: VpadnInReadAdDelegate?
    
    public var videoAdView: VpadnVideoAdView?
    
    /// placementId
    private var placementID: String
    private var adImageView: UIImageView?
    
    /// 廣告要新增在哪個 View 上
    private weak var placeHolder: UIView?
    /// 要置入廣告的 ScrollView
    private weak var loadedScroll: UIScrollView?
    /// 用來調整廣告高度的Constraint
    private weak var heightConstraint: NSLayoutConstraint?
    private weak var ratioConstraint: NSLayoutConstraint?
    
    /// 要置入廣告的 TableView
    private weak var loadedTable: UITableView?
    private var vpadnInReadAds = [Any]()
    /// 廣告要從哪個 IndexPath 開始加入
    private var startIndexPath: IndexPath?
    /// 是否要重複加入
    private var placementRepeat = false
    private var adIndexPaths = [IndexPath]()
    /// 重複的間距
    private var rowStride: Int?
    private var hConstraints = [NSLayoutConstraint]()
    private var vConstraints = [NSLayoutConstraint]()
    private var vpadnInReadAdCellDict: [String: Any] = [:]
    
    /// 遮蔽偵測 Timer
    private weak var coverTimer: Timer?
    /// 廣告 View
    private var returnView: UIView?
    /// 是否拉取測試廣告
    private var isTestMode = false
    /// 是否 Request 過
    private var isAlreadyRequest = false
    /// 取得到廣告的 Flag
    private var isAdRequest = false
    private var testIdentifiers = [String]()
    private var contentURL: String?
    /// 設置 ContentData
    private var contentDict: [String: Any] = [:]
    /// 排除遮蔽偵測的視圖們
    private var friendlyObstructions = [VponAdObstruction]()
    
    private var targetScrollViewDelegate: UIScrollViewDelegate?
    private var targetTableViewDelegate: UITableViewDelegate?
    private var targetDataSource: UITableViewDataSource?
    
    // MARK: - init (Custom Ad)
    
    public init(placementId: String, delegate: VpadnInReadAdDelegate) {
        vpadnInReadAdType = .customAd
        self.placementID = placementId
        self.delegate = delegate
        super.init()
        isAlreadyRequest = false
        videoAdView = VpadnVideoAdView()
        videoAdView?.delegate = self
        videoAdView?.friendlyObstructions = self.friendlyObstructions
    }
    
    public convenience init(placementId: String, scrollView: UIScrollView, delegate: VpadnInReadAdDelegate) {
        self.init(placementId: placementId, delegate: delegate)
        loadedScroll = scrollView
        if let scrollViewDelegate = scrollView.delegate {
            targetScrollViewDelegate = scrollViewDelegate
        }
    }
    
    // MARK: - init (infeed)
    
    public convenience init(placementId: String, placeholder: UIView, heightConstraint constraint: NSLayoutConstraint, scrollView: UIScrollView, delegate: VpadnInReadAdDelegate) {
        self.init(placementId: placementId, scrollView: scrollView, delegate: delegate)
        vpadnInReadAdType = .inScroll
        self.placeHolder = placeholder
        self.heightConstraint = constraint
    }
    
    public convenience init(placementId: String, insertionIndexPath indexPath: IndexPath, tableView: UITableView, delegate: VpadnInReadAdDelegate) {
        self.init(placementId: placementId, delegate: delegate)
        vpadnInReadAdType = .inTable
        self.startIndexPath = indexPath
        self.adIndexPaths = [indexPath]
        self.placementRepeat = false
        self.loadedTable = tableView
        if let delegate = loadedTable?.delegate {
            targetTableViewDelegate = delegate
        }
        if let dataSource = loadedTable?.dataSource {
            targetDataSource = dataSource
        }
    }
    
    public convenience init(placementId: String, insertionIndexPath indexPath: IndexPath, repeatMode: Bool, tableView: UITableView, delegate: VpadnInReadAdDelegate) {
        self.init(placementId: placementId, insertionIndexPath: indexPath, tableView: tableView, delegate: delegate)
        placementRepeat = true
        vpadnInReadAdType = .inTableRepeat
        rowStride = indexPath.row
    }
    
    
    // MARK: - Common Methods
    
    public func loadAdWithTestIdentifiers(_ testIdentifiers: [String]) {
        if !VponAdConfiguration.shared.isInitSDK() {
            vpadnVideoAdView(nil, didFailLoading: ErrorGenerator.initSDKFailed())
            return
        }
        if isAlreadyRequest {
            VponConsole.log("Ad already request, please new one.", .error)
        } else if vpadnInReadAdType == .inTableRepeat {
            VponConsole.note()
            self.testIdentifiers = testIdentifiers
            checkTestMode()
            loadedTable?.dataSource = self
            loadedTable?.delegate = self
            loadedTable?.reloadData()
        } else {
            VponConsole.note()
            self.testIdentifiers = testIdentifiers
            checkTestMode()
            isAlreadyRequest = true
            VponConsole.log("Request Ad", .note)
            
            VpadnAdParams.shared.contentURL = contentURL
            VpadnAdParams.shared.contentDict = contentDict
            
            let strURL = VpadnAdParams.shared.getVastURL(with: ["id": placementID])
            guard let url = URL(string: strURL) else { return }
            
            VponConsole.log("request Url: \(strURL)")
            
            connectToServer(with: url, success: { [weak self] (data, response) in
                guard let coveredData = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] else { return }
//                let jsonString = String(data: data, encoding: .utf8)
//                VPSDKHelper.log("json string: \(String(describing: jsonString))")
                
                if coveredData["status"] as? String == "ok" {
                    if let ads = coveredData["ads"] as? [[String: Any]], ads.count > 0,
                       let document = ads.first,
                       let content = document["content"] as? String {
                        self?.readData(content)
                    } else {
                        self?.parserError()
                    }
                } else {
                    self?.parserError()
                }
            }, failure: { [weak self] (error) in
                self?.parserError()
            })
        }
    }
    
    private func parserError() {
        let error = NSError(domain: NSURLErrorDomain, code: 2, userInfo: [
            NSLocalizedDescriptionKey: NSLocalizedString("Vast parser error fail", comment: ""),
            NSLocalizedFailureReasonErrorKey: NSLocalizedString("Vast parser error", comment: ""),
            NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Contact vpon fae", comment: "")
        ])
        delegate?.vpadnInReadAd?(self, didFailLoading: error)
    }
    
    private func readData(_ document: String) {
        videoAdView?.document = document
        if vpadnInReadAdType == .inTableCustomAd {
            videoAdView?.alwaysPass = true
        }
        videoAdView?.contentURL = self.contentURL
        videoAdView?.loadData()
        VponConsole.log(document)
    }
    
    private func connectToServer(with url: URL, success: @escaping (_ data: Data, _ response: URLResponse) -> Void, failure: @escaping (_ error: Error) -> Void) {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        request.addValue(DeviceInfo.shared.getUserAgent() ?? "", forHTTPHeaderField: "User-Agent")
        request.httpMethod = "GET"
        VponConsole.log("Request: \(String(describing: request.allHTTPHeaderFields))")
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
        session.dataTask(with: request) { data, response, error in
            if let error {
                failure(error)
            } else if let data, let response {
                success(data, response)
            }
        }.resume()
        session.finishTasksAndInvalidate()
    }
    
    // MARK: - Methods for Custom Ad
    
    private func addAdvertisement(_ videoView: VpadnVideoAdView) -> UIView {
        if let returnView { return returnView }
        
        let view = UIView()
        view.backgroundColor = UIColor.clear
        view.clipsToBounds = true
        returnView = view
        
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.clear
        let imageData = Data(bytes: arrayAd, count: arrayAd.count)
        imageView.image = UIImage(data: imageData)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        adImageView = imageView
        
        videoView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(videoView)
        
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 15.0 / 320.0).isActive = true
        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
        
        if vpadnInReadAdType == .inScroll ||
            vpadnInReadAdType == .inTable ||
            vpadnInReadAdType == .inTableCustomAd {
            videoView.addConstraint(NSLayoutConstraint(item: videoView, attribute: .height, relatedBy: .equal, toItem: videoView, attribute: .width, multiplier: 9.0 / 16.0, constant: 0))
        }
        
        addVideoViewConstraints()
        return returnView!
    }
    
    public func videoView() -> UIView? {
        if let videoAdView {
            return addAdvertisement(videoAdView)
        } else {
            return nil
        }
    }
    
    private func addVideoViewConstraints() {
        guard let returnView, let videoAdView, let adImageView else { return }
        
        returnView.removeConstraints(hConstraints)
        returnView.removeConstraints(vConstraints)
        
        hConstraints = [
            videoAdView.leadingAnchor.constraint(equalTo: returnView.leadingAnchor, constant: 0),
            videoAdView.trailingAnchor.constraint(equalTo: returnView.trailingAnchor, constant: 0)
        ]
        returnView.addConstraints(hConstraints)

        vConstraints = [
            adImageView.topAnchor.constraint(equalTo: returnView.topAnchor, constant: 0),
            videoAdView.topAnchor.constraint(equalTo: adImageView.bottomAnchor, constant: 0),
            videoAdView.bottomAnchor.constraint(equalTo: returnView.bottomAnchor, constant: 0)
        ]
        returnView.addConstraints(vConstraints)
    }
    
    private func removeVideoViewConstraints() {
        guard let returnView else { return }
        
        returnView.removeConstraints(hConstraints)
        returnView.removeConstraints(vConstraints)
    }
    
    private func addConstraint(to videoView: UIView, width: Float) {
        guard let superview = videoView.superview else { return }
        videoView.translatesAutoresizingMaskIntoConstraints = false
        let height = width * 195 / 320
        heightConstraint?.constant = CGFloat(height)
        
        superview.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[videoView]-0-|", options: [], metrics: nil, views: ["videoView": videoView]))
        superview.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[videoView]-0-|", options: [], metrics: nil, views: ["videoView": videoView]))
    }
    
    // MARK: - 檢查是否為測試手機
    
    private func checkTestMode() {
        isTestMode = false
        let id = DeviceInfo.shared.getAdvertisingIdentifier()
        for identifier in testIdentifiers {
            if identifier == id {
                isTestMode = true
                break
            }
        }
    }
    
    /// 設置 ContentURL
    /// - Parameter contentURL: 內容網址
    public func setContentUrl(_ contentURL: String) {
        let url = contentURL.addingPercentEncoding(withAllowedCharacters: .urlUserAllowed)
        self.contentURL = url
    }
    
    /// 設置 ContentData
    /// - Parameter contentData: 內容
    public func setContentData(_ contentData: [String: Any]) {
        self.contentDict = contentData
    }
    
    /// 新增 ContentData
    /// - Parameters:
    ///   - key: 鍵
    ///   - value: 值
    public func addContentData(key: String, value: String) {
        contentDict[key] = value
    }
    
    // MARK: - Friendly Obstruction
    
    /// 排除遮蔽偵測的視圖
    public func addFriendlyObstruction(_ obstructView: UIView, purpose: VponFriendlyObstructionType, description: String) {
        let obstruction = VponAdObstruction()
        obstruction.view = obstructView
        obstruction.purpose = purpose
        obstruction.desc = description
        friendlyObstructions.append(obstruction)
        videoAdView?.friendlyObstructions = self.friendlyObstructions
    }
    
    // MARK: - Calculate Video Ad Tab Cell

    public func isVideoAd(_ indexPath: IndexPath, stride: Int) -> Bool {
        switch vpadnInReadAdType {
        case .inTable:
            return indexPath == startIndexPath
        case .inTableRepeat:
            return indexPath.row % (stride + 1) == stride
        default:
            return false
        }
    }
    
    private func currentVpadnInReadAdCell(_ indexPath: IndexPath) -> VpadnVideoAdTableCell? {
        let key = "\(indexPath.row)_\(indexPath.section)"
        if vpadnInReadAdCellDict.keys.contains(key),
           let cell = vpadnInReadAdCellDict[key] as? VpadnVideoAdTableCell {
            return cell
        }
        return nil
    }
    
    private func isVideoAd(_ indexPath: IndexPath) -> Bool {
        if let rowStride {
            return isVideoAd(indexPath, stride: rowStride)
        } else { return false }
    }
    
    private func currentIndexPath(_ indexPath: IndexPath) -> IndexPath {
        switch vpadnInReadAdType {
        case .inTable:
            guard let startIndexPath else { return indexPath }
            if indexPath.section == startIndexPath.section && indexPath.row > startIndexPath.row {
                return IndexPath(row: indexPath.row - 1, section: indexPath.section)
            } else {
                return indexPath
            }
        case .inTableRepeat:
            guard let rowStride else { return indexPath }
            let row = indexPath.row - indexPath.row / (rowStride + 1)
            return IndexPath(row: row, section: indexPath.section)
        default:
            return indexPath
        }
    }
    
    // MARK: - Deinit
    
    deinit {
        if videoAdView?.state == .playing {
            videoAdView?.releasePlayer()
        }
        if coverTimer != nil {
            coverTimer?.invalidate()
            coverTimer = nil
        }
        VponConsole.log("VpadnInRead deinit")
    }
}

// MARK: - URLSessionDelegate

extension VpadnInReadAd: URLSessionDelegate {
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let allowHost = ["api-ssp.vpadn.com", "static-ad.vpadn.com"]
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              allowHost.contains(challenge.protectionSpace.host),
              let trust = challenge.protectionSpace.serverTrust else { return }
        
        let credential = URLCredential(trust: trust)
        var disposition: URLSession.AuthChallengeDisposition = .performDefaultHandling
        disposition = .useCredential
        completionHandler(disposition, credential)
    }
}

// MARK: - VpadnVideoAdViewDelegate

extension VpadnInReadAd: VpadnVideoAdViewDelegate {
    func vpadnVideoAdViewDidLayoutSubviews(_ adView: VpadnVideoAdView) {
//        VponConsole.log("\(#file), \(#function)")
        if vpadnInReadAdType == .inScroll && adView.superview != nil, let placeHolder {
            heightConstraint?.constant = placeHolder.frame.size.width * 195 / 320
        }
        videoView()?.setNeedsLayout()
    }
    
    func vpadnVideoAdView(_ adView: VpadnVideoAdView?, didFailLoading error: Error) {
//        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAd?(self, didFailLoading: error)
    }
    
    func vpadnVideoAdViewWillLoad(_ adView: VpadnVideoAdView) {
//        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdWillLoad?(self)
    }
    
    func vpadnVideoAdViewDidLoad(_ adView: VpadnVideoAdView) {
//        VponConsole.log("\(#file), \(#function)")
        if vpadnInReadAdType == .inScroll, let placeHolder {
            loadedScroll?.delegate = self
            let view = addAdvertisement(adView)
            placeHolder.addSubview(view)
            addConstraint(to: view, width: Float(placeHolder.bounds.size.width))
        } else if vpadnInReadAdType == .inTable {
            loadedTable?.dataSource = self
            loadedTable?.delegate = self
            loadedTable?.reloadData()
        }
        delegate?.vpadnInReadAdDidLoad?(self)
    }
    
    func vpadnVideoAdViewWillStart(_ adView: VpadnVideoAdView) {
//        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdWillStart?(self)
    }
    
    func vpadnVideoAdViewDidStart(_ adView: VpadnVideoAdView) {
//        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdDidStart?(self)
    }
    
    func vpadnVideoAdViewWillStop(_ adView: VpadnVideoAdView) {
//        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdWillStop?(self)
    }
    
    func vpadnVideoAdViewDidStop(_ adView: VpadnVideoAdView) {
//        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdDidStop?(self)
    }
    
    func vpadnVideoAdViewDidPause(_ adView: VpadnVideoAdView) {
//        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdDidPause?(self)
    }
    
    func vpadnVideoAdViewDidResume(_ adView: VpadnVideoAdView) {
//        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdDidResume?(self)
    }
    
    func vpadnVideoAdViewDidMute(_ adView: VpadnVideoAdView) {
//        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdDidMute?(self)
    }
    
    func vpadnVideoAdViewDidUnmute(_ adView: VpadnVideoAdView) {
//        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdDidUnmute?(self)
    }
    
    func vpadnVideoAdViewCanExpand(_ adView: VpadnVideoAdView, ratio: CGFloat) {
//        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdCanExpand?(self, withRatio: ratio)
    }
    
    func vpadnVideoAdViewWillExpand(_ adView: VpadnVideoAdView) {
//        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdWillExpand?(self)
    }
    
    func vpadnVideoAdViewDidExpand(_ adView: VpadnVideoAdView) {
//        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdDidExpand?(self)
    }
    
    func vpadnVideoAdViewCanCollapse(_ adView: VpadnVideoAdView) {
//        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdCanCollapse?(self)
    }
    
    func vpadnVideoAdViewWillCollapse(_ adView: VpadnVideoAdView) {
//        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdWillCollapse?(self)
    }
    
    func vpadnVideoAdViewDidCollapse(_ adView: VpadnVideoAdView) {
//        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdDidCollapse?(self)
    }
    
    func vpadnVideoAdViewWasClicked(_ adView: VpadnVideoAdView) {
//        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdWasClicked?(self)
    }
    
    func vpadnVideoAdViewDidClickBrowserClose(_ adView: VpadnVideoAdView) {
//        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdDidClickBrowserClose?(self)
    }
    
    func vpadnVideoAdViewWillTakeOverFullScreen(_ adView: VpadnVideoAdView) {
//        VponConsole.log("\(#file), \(#function)")
        removeVideoViewConstraints()
        delegate?.vpadnInReadAdWillTakeOverFullScreen?(self)
    }
    
    func vpadnVideoAdViewDidTakeOverFullScreen(_ adView: VpadnVideoAdView) {
//        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdDidTakeOverFullScreen?(self)
    }
    
    func vpadnVideoAdViewWillDismissFullscreen(_ adView: VpadnVideoAdView) {
//        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdWillDismissFullscreen?(self)
    }
    
    func vpadnVideoAdViewDidDismissFullscreen(_ adView: VpadnVideoAdView) {
//        VponConsole.log("\(#file), \(#function)")
        addVideoViewConstraints()
        delegate?.vpadnInReadAdDidDismissFullscreen?(self)
    }
    
    func vpadnVideoAdViewSkipButtonTapped(_ adView: VpadnVideoAdView) {
//        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdSkipButtonTapped?(self)
    }
    
    func vpadnVideoAdViewSkipButtonDidShow(_ adView: VpadnVideoAdView) {
//        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdSkipButtonDidShow?(self)
    }
    
    func vpadnVideoAdViewDidReset(_ adView: VpadnVideoAdView) {
//        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdDidReset?(self)
    }
    
    func vpadnVideoAdViewDidClean(_ adView: VpadnVideoAdView) {
//        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdDidClean?(self)
    }
}

// MARK: - UIScrollViewDelegate

extension VpadnInReadAd: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if vpadnInReadAdType == .inTable || vpadnInReadAdType == .inScroll {
            videoAdView?.coveredDetect()
        } else if vpadnInReadAdType == .inTableRepeat, let loadedTable {
            for cell in loadedTable.visibleCells {
                if let vponCell = cell as? VpadnVideoAdTableCell {
                    vponCell.vpadnInReadAd?.videoAdView?.coveredDetect()
                }
            }
        }
        targetScrollViewDelegate?.scrollViewDidScroll?(scrollView)
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        targetScrollViewDelegate?.scrollViewDidZoom?(scrollView)
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        targetScrollViewDelegate?.scrollViewWillBeginDragging?(scrollView)
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        targetScrollViewDelegate?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        targetScrollViewDelegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }
    
    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        targetScrollViewDelegate?.scrollViewWillBeginDecelerating?(scrollView)
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        targetScrollViewDelegate?.scrollViewDidEndDecelerating?(scrollView)
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        targetScrollViewDelegate?.scrollViewDidEndScrollingAnimation?(scrollView)
    }
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return targetScrollViewDelegate?.viewForZooming?(in: scrollView)
    }
    
    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        targetScrollViewDelegate?.scrollViewWillBeginZooming?(scrollView, with: view)
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        targetScrollViewDelegate?.scrollViewDidEndZooming?(scrollView, with: view, atScale: scale)
    }
    
    public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return targetScrollViewDelegate?.scrollViewShouldScrollToTop?(scrollView) ?? false
    }
    
    public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        targetScrollViewDelegate?.scrollViewDidScrollToTop?(scrollView)
    }
    
    public func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        targetScrollViewDelegate?.scrollViewDidChangeAdjustedContentInset?(scrollView)
    }
}


// MARK: - UITableViewDataSource

extension VpadnInReadAd: UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let targetDataSource else { return 0 }
        if vpadnInReadAdType == .inTableRepeat {
            var index = targetDataSource.tableView(tableView, numberOfRowsInSection: section)
            index = index + index / (rowStride ?? 1)
            return index
        } else {
            let adCount = startIndexPath?.section == section ? adIndexPaths.count : 0
            let index = targetDataSource.tableView(tableView, numberOfRowsInSection: section) + adCount
            return index
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isVideoAd(indexPath) {
            if let cell = currentVpadnInReadAdCell(indexPath) {
                return cell
            } else {
                let cell = VpadnVideoAdTableCell(style: .default, reuseIdentifier: "VpadnVideoAdTableCell")
                cell.selectionStyle = .none
                cell.mainTable = tableView
                if vpadnInReadAdType == .inTableRepeat {
                    let vpadnInReadAd = cell.loadWithPid(placementID, identifiers: testIdentifiers, indexPath: indexPath, delegate: delegate)
                    let key = "\(indexPath.row)_\(indexPath.section)"
                    vpadnInReadAdCellDict[key] = cell
                    vpadnInReadAds.append(vpadnInReadAd)
                } else if let videoAdView {
                    let view = addAdvertisement(videoAdView)
                    cell.contentView.addSubview(view)
                    addConstraint(to: view, width: Float(UIScreen.main.bounds.size.width))
                }
                return cell
            }
        } else {
            return targetDataSource?.tableView(tableView, cellForRowAt: currentIndexPath(indexPath)) ?? UITableViewCell()
        }
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return targetDataSource?.numberOfSections?(in: tableView) ?? 0
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return targetDataSource?.tableView?(tableView, titleForHeaderInSection: section)
    }
    
    public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return targetDataSource?.tableView?(tableView, titleForFooterInSection: section)
    }
    
    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return (targetDataSource?.tableView?(tableView, canEditRowAt: currentIndexPath(indexPath))) ?? false
    }
    
    public func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return (targetDataSource?.tableView?(tableView, canMoveRowAt: currentIndexPath(indexPath))) ?? false
    }
    
    public func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return targetDataSource?.sectionIndexTitles?(for: tableView)
    }
    
    public func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return targetDataSource?.tableView?(tableView, sectionForSectionIndexTitle: title, at: index) ?? 0
    }
    
    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if !isVideoAd(indexPath) {
            targetDataSource?.tableView?(tableView, commit: editingStyle, forRowAt: currentIndexPath(indexPath))
        }
    }
    
    public func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if !isVideoAd(sourceIndexPath) && !isVideoAd(destinationIndexPath) {
            targetDataSource?.tableView?(tableView, moveRowAt: sourceIndexPath, to: destinationIndexPath)
        }
    }
}

// MARK: - UITableViewDelegate

extension VpadnInReadAd: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if !isVideoAd(indexPath) {
            targetTableViewDelegate?.tableView?(tableView, willDisplay: cell, forRowAt: currentIndexPath(indexPath))
        }
    }
    
    public func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        targetTableViewDelegate?.tableView?(tableView, willDisplayHeaderView: view, forSection: section)
    }
    
    public func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        targetTableViewDelegate?.tableView?(tableView, willDisplayFooterView: view, forSection: section)
    }
    
    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if !isVideoAd(indexPath) {
            targetTableViewDelegate?.tableView?(tableView, didEndDisplaying: cell, forRowAt: currentIndexPath(indexPath))
        }
    }
    
    public func tableView(_ tableView: UITableView, didEndDisplayingHeaderView view: UIView, forSection section: Int) {
        targetTableViewDelegate?.tableView?(tableView, didEndDisplayingHeaderView: view, forSection: section)
    }
    
    public func tableView(_ tableView: UITableView, didEndDisplayingFooterView view: UIView, forSection section: Int) {
        targetTableViewDelegate?.tableView?(tableView, didEndDisplayingFooterView: view, forSection: section)
    }
    
    // 會Crash
    //    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    //        if !isVideoAd(indexPath) {
    //            return targetTableViewDelegate?.tableView?(tableView, heightForRowAt: currentIndexPath(indexPath))
    //        } else {
    //            return UITableView.automaticDimension
    //        }
    //    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return targetTableViewDelegate?.tableView?(tableView, heightForHeaderInSection: section) ?? 0
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return targetTableViewDelegate?.tableView?(tableView, heightForFooterInSection: section) ?? 0
    }
    
    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if !isVideoAd(indexPath) {
            return targetTableViewDelegate?.tableView?(tableView, estimatedHeightForRowAt: indexPath) ?? 44
        } else {
            return 44
        }
    }
    
    public func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return targetTableViewDelegate?.tableView?(tableView, estimatedHeightForHeaderInSection: section) ?? 0
    }
    
    public func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        return targetTableViewDelegate?.tableView?(tableView, estimatedHeightForFooterInSection: section) ?? 0
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return targetTableViewDelegate?.tableView?(tableView, viewForHeaderInSection: section)
    }
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return targetTableViewDelegate?.tableView?(tableView, viewForFooterInSection: section)
    }
    
    public func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        targetTableViewDelegate?.tableView?(tableView, accessoryButtonTappedForRowWith: currentIndexPath(indexPath))
    }
    
    // reason: https://www.jianshu.com/p/10da4e388858
    public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    public func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if !isVideoAd(indexPath) {
            targetTableViewDelegate?.tableView?(tableView, didHighlightRowAt: indexPath)
        }
    }
    
    public func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if !isVideoAd(indexPath) {
            targetTableViewDelegate?.tableView?(tableView, didUnhighlightRowAt: indexPath)
        }
    }
    
    public func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if !isVideoAd(indexPath) {
            return targetTableViewDelegate?.tableView?(tableView, willSelectRowAt: currentIndexPath(indexPath))
        } else {
            return indexPath
        }
    }
    
    public func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        if !isVideoAd(indexPath) {
            return  targetTableViewDelegate?.tableView?(tableView, willDeselectRowAt: currentIndexPath(indexPath))
        } else {
            return indexPath
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !isVideoAd(indexPath) {
            targetTableViewDelegate?.tableView?(tableView, didSelectRowAt: currentIndexPath(indexPath))
        }
    }
    
    public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if !isVideoAd(indexPath) {
            targetTableViewDelegate?.tableView?(tableView, didDeselectRowAt: currentIndexPath(indexPath))
        }
    }
    
    public func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if !isVideoAd(indexPath) {
            return (targetTableViewDelegate?.tableView?(tableView, editingStyleForRowAt: currentIndexPath(indexPath))) ?? .none
        } else {
            return .none
        }
    }
    
    public func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        if !isVideoAd(indexPath) {
            return targetTableViewDelegate?.tableView?(tableView, titleForDeleteConfirmationButtonForRowAt: currentIndexPath(indexPath))
        } else {
            return nil
        }
    }
    
    public func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if !isVideoAd(indexPath) {
            return targetTableViewDelegate?.tableView?(tableView, editActionsForRowAt: currentIndexPath(indexPath))
        } else {
            return nil
        }
    }
    
    public func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if !isVideoAd(indexPath) {
            return targetTableViewDelegate?.tableView?(tableView, leadingSwipeActionsConfigurationForRowAt: indexPath)
        } else {
            return nil
        }
    }
    
    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if !isVideoAd(indexPath) {
            return targetTableViewDelegate?.tableView?(tableView, trailingSwipeActionsConfigurationForRowAt: currentIndexPath(indexPath))
        } else {
            return nil
        }
    }
    
    public func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        if !isVideoAd(indexPath) {
            return (targetTableViewDelegate?.tableView?(tableView, shouldIndentWhileEditingRowAt: currentIndexPath(indexPath))) ?? false
        } else {
            return false
        }
    }
    
    public func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        if !isVideoAd(indexPath) {
            targetTableViewDelegate?.tableView?(tableView, willBeginEditingRowAt: currentIndexPath(indexPath))
        }
    }
    
    public func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        guard let indexPath else { return }
        if !isVideoAd(indexPath) {
            targetTableViewDelegate?.tableView?(tableView, didEndEditingRowAt: currentIndexPath(indexPath))
        }
    }
    
    public func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if !isVideoAd(sourceIndexPath) && !isVideoAd(proposedDestinationIndexPath) {
            return targetTableViewDelegate?.tableView?(tableView, targetIndexPathForMoveFromRowAt: sourceIndexPath, toProposedIndexPath: proposedDestinationIndexPath) ?? proposedDestinationIndexPath
        } else {
            return proposedDestinationIndexPath
        }
    }
    
    public func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
        if !isVideoAd(indexPath) {
            return targetTableViewDelegate?.tableView?(tableView, indentationLevelForRowAt: currentIndexPath(indexPath)) ?? 0
        } else {
            return 0
        }
    }
    
    public func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        if !isVideoAd(indexPath) {
            return (targetTableViewDelegate?.tableView?(tableView, shouldShowMenuForRowAt: currentIndexPath(indexPath))) ?? false
        } else {
            return false
        }
    }
    
    public func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        if !isVideoAd(indexPath) {
            return (targetTableViewDelegate?.tableView?(tableView, canPerformAction: action, forRowAt: currentIndexPath(indexPath), withSender: sender)) ?? false
        } else {
            return false
        }
    }
    
    public func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
        if !isVideoAd(indexPath) {
            targetTableViewDelegate?.tableView?(tableView, performAction: action, forRowAt: currentIndexPath(indexPath), withSender: sender)
        }
    }
    
    public func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool {
        if !isVideoAd(indexPath) {
            return (targetTableViewDelegate?.tableView?(tableView, canFocusRowAt: currentIndexPath(indexPath))) ?? false
        } else {
            return false
        }
    }
    
    public func tableView(_ tableView: UITableView, shouldUpdateFocusIn context: UITableViewFocusUpdateContext) -> Bool {
        return targetTableViewDelegate?.tableView?(tableView, shouldUpdateFocusIn: context) ?? false
    }
    
    public func tableView(_ tableView: UITableView, didUpdateFocusIn context: UITableViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        targetTableViewDelegate?.tableView?(tableView, didUpdateFocusIn: context, with: coordinator)
    }
    
    public func indexPathForPreferredFocusedView(in tableView: UITableView) -> IndexPath? {
        return targetTableViewDelegate?.indexPathForPreferredFocusedView?(in: tableView)
    }
    
    public func tableView(_ tableView: UITableView, shouldSpringLoadRowAt indexPath: IndexPath, with context: UISpringLoadedInteractionContext) -> Bool {
        if !isVideoAd(indexPath) {
            return (targetTableViewDelegate?.tableView?(tableView, shouldSpringLoadRowAt: currentIndexPath(indexPath), with: context)) ?? false
        } else {
            return false
        }
    }
}
