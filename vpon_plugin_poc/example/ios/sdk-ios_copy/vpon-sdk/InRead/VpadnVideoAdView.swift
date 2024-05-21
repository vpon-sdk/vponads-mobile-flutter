//
//  VpadnVideoAdView.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/5/3.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

protocol VpadnVideoAdViewDelegate: AnyObject {
    func vpadnVideoAdViewDidLayoutSubviews(_ adView: VpadnVideoAdView)
    func vpadnVideoAdView(_ adView: VpadnVideoAdView?, didFailLoading error: Error)
    func vpadnVideoAdViewWillLoad(_ adView: VpadnVideoAdView)
    func vpadnVideoAdViewDidLoad(_ adView: VpadnVideoAdView)
    func vpadnVideoAdViewWillStart(_ adView: VpadnVideoAdView)
    func vpadnVideoAdViewDidStart(_ adView: VpadnVideoAdView)
    func vpadnVideoAdViewWillStop(_ adView: VpadnVideoAdView)
    func vpadnVideoAdViewDidStop(_ adView: VpadnVideoAdView)
    func vpadnVideoAdViewDidPause(_ adView: VpadnVideoAdView)
    func vpadnVideoAdViewDidResume(_ adView: VpadnVideoAdView)
    func vpadnVideoAdViewDidMute(_ adView: VpadnVideoAdView)
    func vpadnVideoAdViewDidUnmute(_ adView: VpadnVideoAdView)
    func vpadnVideoAdViewCanExpand(_ adView: VpadnVideoAdView, ratio: CGFloat)
    func vpadnVideoAdViewWillExpand(_ adView: VpadnVideoAdView)
    func vpadnVideoAdViewDidExpand(_ adView: VpadnVideoAdView)
    func vpadnVideoAdViewCanCollapse(_ adView: VpadnVideoAdView)
    func vpadnVideoAdViewWillCollapse(_ adView: VpadnVideoAdView)
    func vpadnVideoAdViewDidCollapse(_ adView: VpadnVideoAdView)
    func vpadnVideoAdViewWasClicked(_ adView: VpadnVideoAdView)
    func vpadnVideoAdViewDidClickBrowserClose(_ adView: VpadnVideoAdView)
    func vpadnVideoAdViewWillTakeOverFullScreen(_ adView: VpadnVideoAdView)
    func vpadnVideoAdViewDidTakeOverFullScreen(_ adView: VpadnVideoAdView)
    func vpadnVideoAdViewWillDismissFullscreen(_ adView: VpadnVideoAdView)
    func vpadnVideoAdViewDidDismissFullscreen(_ adView: VpadnVideoAdView)
    func vpadnVideoAdViewSkipButtonTapped(_ adView: VpadnVideoAdView)
    func vpadnVideoAdViewSkipButtonDidShow(_ adView: VpadnVideoAdView)
    func vpadnVideoAdViewDidReset(_ adView: VpadnVideoAdView)
    func vpadnVideoAdViewDidClean(_ adView: VpadnVideoAdView)
}

public class VpadnVideoAdView: UIView {
    
    // MARK: - Constants
    
    let VPADNSCHEME = "vpadnscheme"
    let ANIMATIONDURATION: TimeInterval = 0.3
    let kVpadnVideoAdPlayerStateChangedNotification = Notification.Name("kVpadnVideoAdPlayerStateChangedNotification")
    let kVpadnVideoAdPlayerProgressChangedNotification = Notification.Name("kVpadnVideoAdPlayerProgressChangedNotification")
    let kVpadnVideoAdPlayerLoadProgressChangedNotification = Notification.Name("kVpadnVideoAdPlayerLoadProgressChangedNotification")
    
    // MARK: - Properties
    
    /// XML document
    var document: String?
    weak var delegate: VpadnVideoAdViewDelegate?
    private var omManager: OMManager?
    var state: VponPlayerState = .stopped
    /// 緩衝進度 0 ~ 1
    var loadedProgress: Float = 0
    /// 視頻總時間(sec)
    var duration: CGFloat = 0
    /// 當前播放時間(sec)
    var current: CGFloat = 0
    /// 播放進度 0 ~ 1
    var progress: CGFloat = 0
    /// 預設值 = YES
    var stopWhenAppDidEnterBackground = true
    var paused = false
    var alwaysPass = false
    var contentURL: String?
    
    /// 排除遮蔽偵測的視圖們
    var friendlyObstructions: [VponAdObstruction] = []
    
    private var asset: AVAsset?
    private var urlAsset: AVURLAsset?
    private var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }
    private var playerItem: AVPlayerItem?
    private var playerLayer: AVPlayerLayer {
        if Thread.isMainThread {
            return layer as! AVPlayerLayer
        } else {
            var mainThreadPlayerLayer: AVPlayerLayer?
            DispatchQueue.main.sync {
                mainThreadPlayerLayer = self.layer as? AVPlayerLayer
            }
            return mainThreadPlayerLayer!
        }
    }

    
    private var superLayer: CALayer?
    private var resourceLoader: VpadnVideoAdURLSession?
    /// 是否被使用者暫停
    private var isPauseByUser = false
    /// 是否播放本地影片
    private var isLocalVideo = false
    /// 是否完成下載
    private var didFinishLoading = false
    /// 是否全屏
    private var isFullscreen = false
    
    private var playBreaksTimeObserver: Any?
    private var parser: VpadnAdParser?
    private var cacheManager: VpadnVideoAdCache = VpadnVideoAdCache.shared
    
    private var videoBarHeight: NSLayoutConstraint?
    private var skipTrail: NSLayoutConstraint?
    private var learnMoreHeight: NSLayoutConstraint?
    private var replayHeight: NSLayoutConstraint?
    private var logoHeight: NSLayoutConstraint?
    private var muteHeight: NSLayoutConstraint?
    private var muteLeading: NSLayoutConstraint?
    private var muteBottom: NSLayoutConstraint?
    private var moreTop: NSLayoutConstraint?
    private var moreLeading: NSLayoutConstraint?
    private var moreImageHeight: NSLayoutConstraint?
    private var currentProgressHeight: NSLayoutConstraint?
    private var loadProgressHeight: NSLayoutConstraint?
    
    private var breaksQueue: [Any] = []
    
    // UI
    private var functionView: UIView?
    private var controlView: UIView?
    private var postRollView: UIView?
    private var currentLabel: UILabel?
    private var divLabel: UILabel?
    private var totalLabel: UILabel?
    private var moreView: UIView?
    private var moreLabel: UILabel?
    private var moreImageView: UIImageView?
    private var moreButton: UIButton?
    private var logoImageView: UIImageView?
    private var playButton: UIButton?
    private var muteButton: UIButton?
    private var skipButton: UIButton?
    private var currentProgressView: UIProgressView?
    private var loadedProgressView: UIProgressView?
    private var replayView: UIView?
    private var replayLabel: UILabel?
    private var replayImageView: UIImageView?
    private var learnMoreView: UIView?
    private var learnMoreLabel: UILabel?
    private var learnMoreImageView: UIImageView?
    private var learnMoreButton: UIButton?
    private var replayButton: UIButton?
    
    private var beforeExpandRect: CGRect = .zero
    
    private var fullScreenView: VpadnVideoAdFullscreenView?
    
    private var playTimer: Timer?
    private var skipTimer: Timer?
    private var moreTimer: Timer?
    
    private var tapGestureRecognizer: UITapGestureRecognizer?
    
    /// 記錄已送出的 progress
    private var sendedProgress: [VpadnTracking] = []
    
    private var start = false
    private var impression = false
    private var click = false
    private var firstQuartile = false
    private var midPoint = false
    private var thirdQuartile = false
    private var isComplete = false
    private var isLoad = false
    private var currentAdVast: VpadnAdVast?
    private var currentInline: VpadnAdInline?
    
    private lazy var isBuffering: Bool = false
    
    private var adLifeCycleManager = AdLifeCycleManager()
    private var videoStateManager = VideoStateManager()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = true
    }
    
    public override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    public override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        updateFuncConstraints()
        delegate?.vpadnVideoAdViewDidLayoutSubviews(self)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Methods
    
    func loadData() {
        delegate?.vpadnVideoAdViewWillLoad(self)
        parser = VpadnAdParser()
        DispatchQueue.global().async { [weak self] in
            guard let self else { return }
            if let document = self.document {
                self.parser?.parserVast(withXml: document, delegate: self)
            }
        }
    }
    
    func releasePlayer() {
        if let playTimer, playTimer.isValid {
            playTimer.invalidate()
            self.playTimer = nil
        }
        guard let playerItem else { return }
        NotificationCenter.default.removeObserver(self)
        playerItem.removeObserver(self, forKeyPath: "status")
        playerItem.removeObserver(self, forKeyPath: "loadedTimeRanges")
        playerItem.removeObserver(self, forKeyPath: "playbackBufferEmpty")
        playerItem.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        if let playBreaksTimeObserver {
            player?.removeTimeObserver(playBreaksTimeObserver)
        }
        playBreaksTimeObserver = nil
        self.playerItem = nil
    }
    
    private func resetPlayer() {
        isLoad = false
        isPauseByUser = false
        loadedProgress = 0
        duration = 0
        current = 0
        impression = false
        click = false
        firstQuartile = false
        midPoint = false
        thirdQuartile = false
    }
    
    private func resetPlayerForReplay() {
        state = .stopped
        isPauseByUser = false
        loadedProgress = 0
        duration = 0
        current = 0
    }
    
    private func playVideoAd() {
        guard let mediaFile = currentInline?.getMediaFile(),
              let url = mediaFile.url else {
            sendErrorTracking(code: 401)
            stop()
            return
        }
        guard mediaFile.apiFramework != "VPAID" else {
            sendErrorTracking(code: 901)
            stop()
            return
        }
        
        if omManager == nil {
            let factory = OMSimpleFactory()
            let data = currentInline?.getAdVerifications().map({ $0.toDictionary() }) ?? []
            let verifications = parseVerifications(data)
            omManager = factory.createNativeAdOMManager(adLifeCycleManager, self, verifications, true, videoStateManager)
            omManager?.setFriendlyObstructions(friendlyObstructions)
            
            adLifeCycleManager.notify(.onAdLoaded)
        }
        playerItem = AVPlayerItem(url: url)
        if let player {
            player.replaceCurrentItem(with: playerItem)
        } else {
            player = AVPlayer(playerItem: playerItem)
            player?.isMuted = true
        }
        
        playerLayer.player = player
        
        isLocalVideo = false
        addObserver()
        
        // 如果已經在 VpadnPlayerStateBuffering，則直接發狀態改變通知，否則設置狀態
        if state == .buffering {
            NotificationCenter.default.post(name: kVpadnVideoAdPlayerStateChangedNotification, object: nil)
        } else {
            state = .buffering
        }
        videoStateManager.notify(.onVideoBufferStart)
        NotificationCenter.default.post(name: kVpadnVideoAdPlayerProgressChangedNotification, object: nil)
    }
    
    // MARK: - Player UI
    
    private func displayEndView(_ flag: Bool) {
        postRollView?.isHidden = !flag
        controlView?.isHidden = flag
        UIView.animate(withDuration: ANIMATIONDURATION) {
            self.postRollView?.alpha = flag ? 1 : 0
            self.controlView?.alpha = !flag ? 1 : 0
        }
    }
    
    private func dynamicHeight(_ height: CGFloat) -> CGFloat {
        //        if let layer = playerLayer {
        //            let result = layer.videoRect.size.height * height / 180
        //        }
        return height
    }
    
    private func buildFunctionView() {
        guard functionView?.superview == nil else { return }
        var superView: UIView?
        
        functionView = UIView()
        guard let functionView else { return }
        functionView.backgroundColor = .clear
        functionView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(functionView)
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[functionView]-0-|", options: [], metrics: nil, views: ["functionView": functionView]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[functionView]-0-|", options: [], metrics: nil, views: ["functionView": functionView]))
        
        /**************************/
        /*                        */
        /*    Player Ctrl View    */
        /*                        */
        /**************************/
        
        controlView = UIView()
        guard let controlView else { return }
        controlView.backgroundColor = .clear
        controlView.translatesAutoresizingMaskIntoConstraints = false
        controlView.isUserInteractionEnabled = true
        functionView.addSubview(controlView)
        functionView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[controlView]-0-|", options: [], metrics: nil, views: ["controlView": controlView]))
        functionView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[controlView]-0-|", options: [], metrics: nil, views: ["controlView": controlView]))
        
        superView = controlView
        
        // moreView
        moreView = UIView()
        moreView?.backgroundColor = colorWithHex(0x000000, alpha: 0.5)
        moreView?.layer.borderColor = UIColor.white.cgColor
        moreView?.layer.borderWidth = 1
        moreView?.layer.cornerRadius = 4
        moreView?.clipsToBounds = true
        moreView?.alpha = 0
        moreView?.translatesAutoresizingMaskIntoConstraints = false
        superView!.addSubview(moreView!)
        
        // moreLabel
        moreLabel = UILabel()
        moreLabel?.text = VpadnVideoAdView.localizedDesc("Learn More")
        moreLabel?.textColor = .white
        moreLabel?.font = UIFont.systemFont(ofSize: 12)
        moreLabel?.translatesAutoresizingMaskIntoConstraints = false
        moreView?.addSubview(moreLabel!)
        
        // moreImageView
        let moreImageData = Data(bytes: arrayMore, count: arrayMore.count)
        moreImageView = UIImageView(image: UIImage(data: moreImageData))
        moreImageView?.contentMode = .scaleAspectFit
        moreImageView?.translatesAutoresizingMaskIntoConstraints = false
        moreView?.addSubview(moreImageView!)
        
        
        // moreButton
        moreButton = UIButton(type: .custom)
        moreButton?.backgroundColor = .clear
        moreButton?.addTarget(self, action: #selector(moreButtonClicked), for: .touchUpInside)
        moreButton?.translatesAutoresizingMaskIntoConstraints = false
        moreView?.addSubview(moreButton!)
        
        // muteButton
        muteButton = UIButton(type: .custom)
        let unmuteImageData = Data(bytes: arrayUnmute, count: arrayUnmute.count)
        muteButton?.setImage(UIImage(data: unmuteImageData), for: .normal)
        let muteImageData = Data(bytes: arrayMute, count: arrayMute.count)
        muteButton?.setImage(UIImage(data: muteImageData), for: .selected)
        
        muteButton?.imageView?.contentMode = .scaleAspectFit
        muteButton?.addTarget(self, action: #selector(muteButtonClicked), for: .touchUpInside)
        muteButton?.translatesAutoresizingMaskIntoConstraints = false
        if let player {
            muteButton?.isSelected = player.isMuted
        }
        superView?.addSubview(muteButton!)
        
        // currentProgressView
        currentProgressView = UIProgressView()
        currentProgressView?.progress = 0
        currentProgressView?.trackTintColor = .clear
        currentProgressView?.tintColor = colorWithHex(0xFF9500, alpha: 1)
        currentProgressView?.translatesAutoresizingMaskIntoConstraints = false
        superView?.addSubview(currentProgressView!)
        
        moreView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[moreButton]-0-|", options: [], metrics: nil, views: ["moreButton": moreButton!]))
        moreView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[moreButton]-0-|", options: [], metrics: nil, views: ["moreButton": moreButton!]))
        moreView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[moreLabel]-0-|", options: [], metrics: nil, views: ["moreLabel": moreLabel!]))
        moreView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[moreImageView]-0-|", options: [], metrics: nil, views: ["moreImageView": moreImageView!]))
        moreView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[moreLabel]-0-[moreImageView]-0-|", options: [], metrics: nil, views: ["moreLabel": moreLabel!, "moreImageView": moreImageView!]))
        
        moreImageHeight = NSLayoutConstraint(item: moreImageView!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: dynamicHeight(20))
        moreImageView?.addConstraint(moreImageHeight!)
        
        moreImageView?.addConstraint(NSLayoutConstraint(item: moreImageView!, attribute: .height, relatedBy: .equal, toItem: moreImageView, attribute: .width, multiplier: 1, constant: 0))
        
        moreLeading = NSLayoutConstraint(item: moreView!, attribute: .leading, relatedBy: .equal, toItem: superView, attribute: .leading, multiplier: 1, constant: dynamicHeight(4))
        superView?.addConstraint(moreLeading!)
        
        moreTop = NSLayoutConstraint(item: moreView!, attribute: .top, relatedBy: .equal, toItem: superView, attribute: .top, multiplier: 1, constant: dynamicHeight(4))
        superView?.addConstraint(moreTop!)
        
        muteBottom = NSLayoutConstraint(item: currentProgressView!, attribute: .top, relatedBy: .equal, toItem: muteButton, attribute: .bottom, multiplier: 1, constant: dynamicHeight(4))
        superView?.addConstraint(muteBottom!)
        
        muteHeight = NSLayoutConstraint(item: muteButton!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: dynamicHeight(20))
        muteButton?.addConstraint(muteHeight!)
        
        muteButton?.addConstraint(NSLayoutConstraint(item: muteButton!, attribute: .width, relatedBy: .equal, toItem: muteButton, attribute: .height, multiplier: 1, constant: 0))
        
        muteLeading = NSLayoutConstraint(item: muteButton!, attribute: .leading, relatedBy: .equal, toItem: superView, attribute: .leading, multiplier: 1, constant: dynamicHeight(4))
        superView?.addConstraint(muteLeading!)
        
        currentProgressHeight = NSLayoutConstraint(item: currentProgressView!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: dynamicHeight(3))
        currentProgressView?.addConstraint(currentProgressHeight!)
        
        superView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[currentProgressView]-0-|", options: [], metrics: nil, views: ["currentProgressView": currentProgressView!]))
        superView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[currentProgressView]-0-|", options: [], metrics: nil, views: ["currentProgressView": currentProgressView!]))
        
        /**************************/
        /*                        */
        /*      Post Roll View    */
        /*                        */
        /**************************/
        
        postRollView = UIView()
        postRollView?.backgroundColor = colorWithHex(0x000000, alpha: 0.7)
        postRollView?.translatesAutoresizingMaskIntoConstraints = false
        functionView.addSubview(postRollView!)

        functionView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[postRollView]-0-|", options: [], metrics: nil, views: ["postRollView": postRollView!]))
        functionView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[postRollView]-0-|", options: [], metrics: nil, views: ["postRollView": postRollView!]))
        
        superView = postRollView
        
        // learnMoreView
        learnMoreView = UIView()
        learnMoreView?.backgroundColor = .clear
        learnMoreView?.clipsToBounds = true
        learnMoreView?.translatesAutoresizingMaskIntoConstraints = false
        superView?.addSubview(learnMoreView!)
        
        // learnMoreLabel
        learnMoreLabel = UILabel()
        learnMoreLabel?.text = VpadnVideoAdView.localizedDesc("Learn More")
        learnMoreLabel?.textColor = .white
        learnMoreLabel?.font = UIFont.systemFont(ofSize: 12)
        learnMoreLabel?.translatesAutoresizingMaskIntoConstraints = false
        learnMoreView?.addSubview(learnMoreLabel!)
        
        // learnMoreImageView
        let learnMoreImageData = Data(bytes: arrayLearnMore, count: arrayLearnMore.count)
        learnMoreImageView = UIImageView(image: UIImage(data: learnMoreImageData))
        learnMoreImageView?.contentMode = .scaleAspectFit
        learnMoreImageView?.translatesAutoresizingMaskIntoConstraints = false
        learnMoreView?.addSubview(learnMoreImageView!)
        
        // learnMoreButton
        learnMoreButton = UIButton(type: .custom)
        learnMoreButton?.backgroundColor = .clear
        learnMoreButton?.addTarget(self, action: #selector(moreButtonClicked), for: .touchUpInside)
        learnMoreButton?.translatesAutoresizingMaskIntoConstraints = false
        learnMoreView?.addSubview(learnMoreButton!)
        
        let div = UIView()
        div.backgroundColor = .clear
        div.translatesAutoresizingMaskIntoConstraints = false
        superView?.addSubview(div)
        
        // replayView
        replayView = UIView()
        replayView?.backgroundColor = .clear
        replayView?.clipsToBounds = true
        replayView?.translatesAutoresizingMaskIntoConstraints = false
        superView?.addSubview(replayView!)
        
        // replayLabel
        replayLabel = UILabel()
        replayLabel?.text = VpadnVideoAdView.localizedDesc("Replay")
        replayLabel?.textColor = .white
        replayLabel?.font = UIFont.systemFont(ofSize: 12)
        replayLabel?.translatesAutoresizingMaskIntoConstraints = false
        replayView?.addSubview(replayLabel!)
        
        // replayImageView
        let replayImageData = Data(bytes: arrayReplay, count: arrayReplay.count)
        replayImageView = UIImageView(image: UIImage(data: replayImageData))
        replayImageView?.contentMode = .scaleAspectFit
        replayImageView?.translatesAutoresizingMaskIntoConstraints = false
        replayView?.addSubview(replayImageView!)
        
        // replayButton
        replayButton = UIButton(type: .custom)
        replayButton?.backgroundColor = .clear
        replayButton?.addTarget(self, action: #selector(replay), for: .touchUpInside)
        replayButton?.translatesAutoresizingMaskIntoConstraints = false
        replayView?.addSubview(replayButton!)
        
        superView?.addConstraint(NSLayoutConstraint(item: superView!, attribute: .centerY, relatedBy: .equal, toItem: div, attribute: .centerY, multiplier: 1, constant: 0))
        superView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[div]-|", options: [], metrics: nil, views: ["div": div]))
        superView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[replayView]-[div(==1)]-[learnMoreView]", options: [], metrics: nil, views: ["replayView": replayView!, "div": div, "learnMoreView": learnMoreView!]))

        learnMoreView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[learnMoreImageView]-12-[learnMoreLabel]-0-|", options: [], metrics: nil, views: ["learnMoreImageView": learnMoreImageView!, "learnMoreLabel": learnMoreLabel!]))
        learnMoreImageView?.addConstraint(NSLayoutConstraint(item: learnMoreImageView!, attribute: .width, relatedBy: .equal, toItem: learnMoreImageView, attribute: .height, multiplier: 1, constant: 0))
        learnMoreHeight = NSLayoutConstraint(item: learnMoreImageView!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: dynamicHeight(40))
        learnMoreImageView?.addConstraint(learnMoreHeight!)

        superView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[learnMoreImageView]-0-|", options: [], metrics: nil, views: ["learnMoreImageView": learnMoreImageView!]))
        superView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[learnMoreLabel]-0-|", options: [], metrics: nil, views: ["learnMoreLabel": learnMoreLabel!]))

        superView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[learnMoreButton]-0-|", options: [], metrics: nil, views: ["learnMoreButton": learnMoreButton!]))
        superView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[learnMoreButton]-0-|", options: [], metrics: nil, views: ["learnMoreButton": learnMoreButton!]))

        replayView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[replayImageView]-12-[replayLabel]-0-|", options: [], metrics: nil, views: ["replayImageView": replayImageView!, "replayLabel": replayLabel!]))
        replayImageView?.addConstraint(NSLayoutConstraint(item: replayImageView!, attribute: .width, relatedBy: .equal, toItem: replayImageView, attribute: .height, multiplier: 1, constant: 0))
        replayHeight = NSLayoutConstraint(item: replayImageView!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: dynamicHeight(40))
        replayImageView?.addConstraint(replayHeight!)
        
        superView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[replayImageView]-0-|", options: [], metrics: nil, views: ["replayImageView": replayImageView!]))
        superView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[replayLabel]-0-|", options: [], metrics: nil, views: ["replayLabel": replayLabel!]))

        superView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[replayButton]-0-|", options: [], metrics: nil, views: ["replayButton": replayButton!]))
        superView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[replayButton]-0-|", options: [], metrics: nil, views: ["replayButton": replayButton!]))

        superView?.addConstraint(NSLayoutConstraint(item: superView!, attribute: .centerX, relatedBy: .equal, toItem: learnMoreView, attribute: .centerX, multiplier: 1, constant: 0))
        superView?.addConstraint(NSLayoutConstraint(item: learnMoreView!, attribute: .leading, relatedBy: .equal, toItem: replayView, attribute: .leading, multiplier: 1, constant: 0))
        
        /**************************/
        /*                        */
        /*    Logo Image View     */
        /*                        */
        /**************************/
        
        let logoImageData = Data(bytes: arrayLogo, count: arrayLogo.count)
        logoImageView = UIImageView(image: UIImage(data: logoImageData))
        logoImageView?.contentMode = .scaleAspectFit
        logoImageView?.translatesAutoresizingMaskIntoConstraints = false
        functionView.addSubview(logoImageView!)
        
        logoHeight = NSLayoutConstraint(item: logoImageView!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: dynamicHeight(20))
        logoImageView?.addConstraint(logoHeight!)
        
        logoImageView?.addConstraint(NSLayoutConstraint(item: logoImageView!, attribute: .width, relatedBy: .equal, toItem: logoImageView, attribute: .height, multiplier: 19/15, constant: 0))
        
        functionView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[_logoImageView]-8-|", options: [], metrics: nil, views: ["_logoImageView": logoImageView!]))

        functionView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[_logoImageView]-0-|", options: [], metrics: nil, views: ["_logoImageView": logoImageView!]))
        
        addTapGesture()
    }
    
    private func updateFuncConstraints() {
        if let muteHeight {
            muteHeight.constant = dynamicHeight(20)
        }
        
        if let muteBottom {
            muteBottom.constant = dynamicHeight(4)
        }
        
        if let muteLeading {
            muteLeading.constant = dynamicHeight(4)
        }
        
        if let loadProgressHeight {
            loadProgressHeight.constant = dynamicHeight(3)
        }
        
        if let currentProgressHeight {
            currentProgressHeight.constant = dynamicHeight(3)
        }
        
        if let moreTop {
            moreTop.constant = dynamicHeight(4)
        }
        
        if let moreLeading {
            moreLeading.constant = dynamicHeight(4)
        }
        
        if let moreImageHeight {
            moreImageHeight.constant = dynamicHeight(20)
        }
        
        if let logoHeight {
            logoHeight.constant = dynamicHeight(15)
        }
        
        if let learnMoreHeight {
            learnMoreHeight.constant = dynamicHeight(40)
        }
        
        if let replayHeight {
            replayHeight.constant = dynamicHeight(40)
        }
    }
    
    // MARK: - Control Unit
    
    // Not being called
    private func updatePlayButtonState() {
        DispatchQueue.main.async {
            switch self.state {
            case .playing:
                self.playButton?.isSelected = true
                self.playButton?.isEnabled = true
            case .pause:
                self.playButton?.isSelected = false
                self.playButton?.isEnabled = false
            default:
                self.playButton?.isEnabled = false
            }
        }
    }
    
    private func updateMuteButtonState() {
        DispatchQueue.main.async { [weak self] in
            guard let self,
                  let player = self.player,
                  let currentInline = self.currentInline else { return }
            
            if player.isMuted {
                self.currentAdVast?.sendTracking(by: "unmute", currentInline: currentInline)
                self.delegate?.vpadnVideoAdViewDidUnmute(self)
            } else {
                self.currentAdVast?.sendTracking(by: "mute", currentInline: currentInline)
                self.delegate?.vpadnVideoAdViewDidMute(self)
            }
            self.muteButton?.isSelected = player.isMuted
          
            let data = ["volume": self.playerVolume()]
            self.videoStateManager.notify(.onVideoVolumeChange, data: data)
        }
    }
    
    private func updateCurrentProgressViewValue(_ progress: Float) {
        currentProgressView?.setProgress(progress, animated: false)
    }
    
    private func updateMoreTimer() {
        if let moreTimer, moreTimer.isValid {
            moreTimer.invalidate()
            self.moreTimer = nil
        }
        moreTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(displayMoreButton), userInfo: nil, repeats: false)
    }
    
    private func hideMoreButton() {
        UIView.animate(withDuration: ANIMATIONDURATION) {
            self.moreView?.alpha = 0
        }
    }
    
    @objc private func displayMoreButton() {
        UIView.animate(withDuration: ANIMATIONDURATION) {
            self.moreView?.alpha = 1
        }
    }
    
    private func updateSkipTimer() {
        if let skipTimer, skipTimer.isValid {
            skipTimer.invalidate()
            self.skipTimer = nil
        }
        skipTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(displaySkipButton), userInfo: nil, repeats: false)
    }
    
    private func hideSkipButton() {
        skipTrail?.constant = -64
        UIView.animate(withDuration: ANIMATIONDURATION) {
            self.functionView?.layoutIfNeeded()
        }
    }
    
    @objc private func displaySkipButton() {
        skipTrail?.constant = 4
        UIView.animate(withDuration: ANIMATIONDURATION) {
            self.functionView?.layoutIfNeeded()
        } completion: { finished in
            if finished {
                self.delegate?.vpadnVideoAdViewSkipButtonDidShow(self)
            }
        }
    }
    
    private func addTapGesture() {
        if let functionView, let tapGestureRecognizer, let recognizers = functionView.gestureRecognizers {
            if recognizers.contains(tapGestureRecognizer) {
                functionView.removeGestureRecognizer(tapGestureRecognizer)
            }
        }
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapBehavior(_:)))
        functionView?.addGestureRecognizer(tapGestureRecognizer!)
    }
    
    @objc private func tapBehavior(_ recognizer: UIGestureRecognizer) {
        if let functionView, self.subviews.contains(functionView) {
            expandScreen()
        }
    }
    
    // MARK: - Observer
    
    private func addObserver() {
        playerItem?.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        playerItem?.addObserver(self, forKeyPath: "loadedTimeRanges", options: .new, context: nil)
        playerItem?.addObserver(self, forKeyPath: "playbackBufferEmpty", options: .new, context: nil)
        playerItem?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterPlayGround), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidPlayToEnd(_:)), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemPlaybackStalled(_:)), name: .AVPlayerItemPlaybackStalled, object: playerItem)
    }
    
    @objc private func appDidEnterBackground() {
        if stopWhenAppDidEnterBackground {
            pauseBySystem()
        }
    }
    
    @objc private func appDidEnterPlayGround() {
        if !isPauseByUser {
            state = .pause
            resume()
        }
    }
    
    @objc private func playerItemDidPlayToEnd(_ notification: Notification) {
        isComplete = true
        guard let currentAdVast, let currentInline else { return }
        let progressTracking = currentAdVast.getTracking(by: "progress", currentInline: currentInline)
        for tracking in progressTracking {
            if !sendedProgress.contains(tracking) {
                currentAdVast.sendTracking(tracking)
                sendedProgress.append(tracking)
            }
        }
        currentAdVast.sendTracking(by: "complete", currentInline: currentInline)
        videoStateManager.notify(.onVideoComplete)
        stop()
    }
    
    // 在監聽播放器狀態中處理比較準確
    @objc private func playerItemPlaybackStalled(_ notification: Notification) {
        //        網絡不好的時候就會進入，不做處理，會在playbackBufferEmpty裡面緩存之後重新播放
        //        NSLog(@"buffing-----buffing")
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let playerItem = object as? AVPlayerItem else { return }
        if keyPath == "status" {
            if playerItem.status == .readyToPlay {
                videoStateManager.notify(.onVideoBufferFinish)
                DispatchQueue.main.async {
                    self.buildFunctionView()
                    self.displayEndView(false)
                }
                
                isLoad = true
                delegate?.vpadnVideoAdViewDidLoad(self)
                
                playTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(monitoringPlayback(_:)), userInfo: playerItem, repeats: false)
            } else if playerItem.status == .failed || playerItem.status == .unknown {
                sendErrorTracking(code: 405)
                stop()
            }
        } else if keyPath == "loadedTimeRanges" {
            // 監聽播放器的下載進度
            calculateDownloadProgress(playerItem)
        } else if keyPath == "playbackBufferEmpty" {
            // 監聽播放器在緩衝數據的狀態
            if playerItem.isPlaybackBufferEmpty {
                state = .buffering
                bufferingSomeSecond()
            }
        }
    }
    
    @objc private func monitoringPlayback(_ timer: Timer) {
        guard let playerItem = timer.userInfo as? AVPlayerItem else { return }
        
        if let functionView, subviews.contains(functionView) || isFullscreen {
            playback(playerItem)
        } else {
            playTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(monitoringPlayback(_:)), userInfo: playerItem, repeats: false)
        }
    }
    
    private func playback(_ playerItem: AVPlayerItem) {
        delegate?.vpadnVideoAdViewWillStart(self)
        
        self.duration = CGFloat(playerItem.duration.value) / CGFloat(playerItem.duration.timescale) //视频总时间
        //[self updateSkipTimer]
        updateMoreTimer()
        play()
        
        self.sendedProgress = []
        
        
        self.playBreaksTimeObserver = self.player?.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 100), queue: nil) { [weak self] (time) in
            guard let self = self else { return }
            
            let current = CGFloat(playerItem.currentTime().value) / CGFloat(playerItem.currentTime().timescale)
            let percent = current / self.duration
            self.updateCurrentProgressViewValue(Float(percent))
            if self.isPauseByUser == false {
                self.state = .playing
            }
            
            // 不相等的时候才更新，并发通知，否则seek时会继续跳动
            if self.current != current {
                self.current = current
                if self.current > self.duration {
                    self.duration = self.current
                }
                NotificationCenter.default.post(name: Notification.Name(self.kVpadnVideoAdPlayerProgressChangedNotification.rawValue), object: nil)
            }
            
            guard let currentAdVast = self.currentAdVast,
                  let currentInline = self.currentInline else { return }
            
            let progressTracking = currentAdVast.getTracking(by: "progress", currentInline: currentInline)
            for tracking in progressTracking {
                if current >= tracking.offset ?? 0 && !self.sendedProgress.contains(where: { $0 === tracking }) {
                    currentAdVast.sendTracking(tracking)
                    self.sendedProgress.append(tracking)
                }
            }
            
            if current >= 0 && !self.impression {
                if let window = self.window {
                    var viewabilityDetector: ViewabilityDetector
                    
                    
              
                    if let fullScreenView = self.fullScreenView {
                        viewabilityDetector = ViewabilityDetector(adView: self.isFullscreen ? fullScreenView : self,
                                                                  in: window,
                                                                  friendlyObstructions: friendlyObstructions,
                                                                  adLifeCycleManager: adLifeCycleManager)
                     
                    } else {
                        viewabilityDetector = ViewabilityDetector(adView: self,
                                                                  in: window,
                                                                  friendlyObstructions: friendlyObstructions,
                                                                  adLifeCycleManager: adLifeCycleManager)
                       
                    }
                    viewabilityDetector.bannerFlags = true
                    
                    if viewabilityDetector.checkViewCovered() {
                        self.impression = true
                        currentAdVast.sendTracking(by: "impression", currentInline: currentInline)
                        adLifeCycleManager.notify(.onAdImpression)
                    }
                }
            }
            
            if current >= 0 && !self.start {
                self.start = true
                currentAdVast.sendTracking(by: "start", currentInline: currentInline)
                let data = ["duration": duration, "volume": playerVolume()]
                videoStateManager.notify(.onVideoStart, data: data)
            }
            
            if percent >= 0.25 && !self.firstQuartile {
                self.firstQuartile = true
                currentAdVast.sendTracking(by: "firstQuartile", currentInline: currentInline)
                videoStateManager.notify(.onVideoFirstQuartile)
            }
            
            if percent >= 0.5 && !self.midPoint {
                self.midPoint = true
                currentAdVast.sendTracking(by: "midpoint", currentInline: currentInline)
                videoStateManager.notify(.onVideoMidPoint)
            }
            
            if percent >= 0.75 && !self.thirdQuartile {
                self.thirdQuartile = true
                currentAdVast.sendTracking(by: "thirdQuartile", currentInline: currentInline)
                videoStateManager.notify(.onVideoThirdQuartile)
            }
        }
    }
    
    private func calculateDownloadProgress(_ playerItem: AVPlayerItem) {
        guard let timeRange = playerItem.loadedTimeRanges.first?.timeRangeValue else { return } // 获取缓冲区域
        let startSeconds = CMTimeGetSeconds(timeRange.start)
        let durationSeconds = CMTimeGetSeconds(timeRange.duration)
        let timeInterval = startSeconds + durationSeconds // 计算缓冲总进度
        let totalDuration = CMTimeGetSeconds(playerItem.duration)
        loadedProgress = Float(timeInterval / totalDuration)
        loadedProgressView?.setProgress(loadedProgress, animated: true)
    }
    
    private func bufferingSomeSecond() {
        // playbackBufferEmpty 會反復進入，因此在 bufferingOneSecond 延時播放執行完之前再調用 bufferingSomeSecond 都忽略
        
        if isBuffering { return }
        isBuffering = true
        
        // 需要先暂停一小会之后再播放，否则网络状况不好的时候时间在走，声音播放不出来
        player?.pause()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            
            // 如果此时用户已经暂停了，则不再需要开启播放了
            if self.isPauseByUser {
                self.isBuffering = false
                return
            }
            
            self.player?.play()
            // 如果执行了 play 还是没有播放则说明还没有缓存好，则再次缓存一段时间
            self.isBuffering = false
            if let playerItem = self.playerItem,
               !playerItem.isPlaybackLikelyToKeepUp {
                self.bufferingSomeSecond()
            }
        }
    }
    
    
    // MARK: - Player Control
    
    private func expandScreen() {
        guard !isComplete,
              let functionView,
              let currentInline else { return }
        if subviews.contains(functionView) {
            delegate?.vpadnVideoAdViewWillTakeOverFullScreen(self)
            isFullscreen = true
            logoImageView?.isHidden = true
            superLayer = playerLayer.superlayer
            beforeExpandRect = playerLayer.frame
            
            fullScreenView = VpadnVideoAdFullscreenView(withAVPlayerLayer: playerLayer, functionView: functionView, delegate: self)
            fullScreenView?.presentFullScreen()
            currentAdVast?.sendTracking(by: "fullscreen", currentInline: currentInline)
            videoStateManager.notify(.onChangeToFullScreen)
            delegate?.vpadnVideoAdViewDidTakeOverFullScreen(self)
        }
    }
        
    private func shrinkScreen() {
        guard let functionView,
              let currentInline else { return }
        if !subviews.contains(functionView) {
            delegate?.vpadnVideoAdViewWillDismissFullscreen(self)
            isFullscreen = false
            logoImageView?.isHidden = false
            playerLayer.frame = beforeExpandRect
            superLayer?.insertSublayer(playerLayer, at: 0)
            addSubview(functionView)
            self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[functionView]-0-|", options: [], metrics: nil, views: ["functionView": functionView]))

            self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[functionView]-0-|", options: [], metrics: nil, views: ["functionView": functionView]))
            
            videoStateManager.notify(.onChangeToNormal)
            currentAdVast?.sendTracking(by: "exitFullscreen", currentInline: currentInline)
            delegate?.vpadnVideoAdViewDidDismissFullscreen(self)
        }
    }
    
    @objc private func muteButtonClicked() {
        if playerItem == nil { return }
        player?.isMuted.toggle()
        updateMuteButtonState()
    }
    
    func coveredDetect() {
        guard let window = self.window else { return }
        let viewabilityDetector = ViewabilityDetector(adView: self,
                                                      in: window,
                                                      friendlyObstructions: friendlyObstructions,
                                                      adLifeCycleManager: adLifeCycleManager)
        
        let result = viewabilityDetector.checkViewCovered()
        let isPass = isFullscreen || result
        if let playTimer, playTimer.isValid {
            playTimer.invalidate()
            self.playTimer = nil
        }
        if isPass && state == .buffering, let playerItem {
            playback(playerItem)
        } else if isPass && state == .pause {
            resume()
        } else if !isPass && state == .playing {
            pauseBySystem()
        }
    }
    
    // Not being called
    /// user manually
    private func resumeOrPause() {
        if state == .playing {
            pauseByUser()
        } else if state == .pause {
            resume()
        }
    }
    
    /// system automatic
    private func play() {
        guard playerItem != nil,
              state != .stopped,
              state != .playing else { return }
        player?.play()
        state = .playing
        isPauseByUser = false
        delegate?.vpadnVideoAdViewDidStart(self)
    }
    
    /// system automatic
    @objc private func replay() {
        videoStateManager.notify(.onVideoResume)
        currentInline = currentAdVast?.adInlines.first
        state = .stopped
        releasePlayer()
        resetPlayerForReplay()
        playVideoAd()
    }
    
    /// system automatic / user manually
    private func resume() {
        guard playerItem != nil,
              state != .stopped,
              state != .playing,
              let currentInline else { return }
        player?.play()
        state = .playing
        isPauseByUser = false
        currentAdVast?.sendTracking(by: "resume", currentInline: currentInline)
        videoStateManager.notify(.onVideoResume)
        delegate?.vpadnVideoAdViewDidResume(self)
    }
    
    private func pause() {
        guard playerItem != nil,
              state == .playing,
              let currentInline else { return }
        state = .pause
        player?.pause()
        currentAdVast?.sendTracking(by: "pause", currentInline: currentInline)
        videoStateManager.notify(.onVideoPause)
        delegate?.vpadnVideoAdViewDidPause(self)
    }
    
    /// user manually
    private func pauseBySystem() {
        pause()
        isPauseByUser = false
    }
    
    /// user manually
    private func pauseByUser() {
        pause()
        isPauseByUser = true
    }
    
    /// system automatic
    private func stop() {
        guard playerItem != nil,
              let currentAdVast,
              var currentInline else { return }
        delegate?.vpadnVideoAdViewWillStop(self)
        state = .stopped
        player?.pause()
        releasePlayer()
        NotificationCenter.default.post(name: kVpadnVideoAdPlayerProgressChangedNotification, object: nil)
        if let index = currentAdVast.adInlines.firstIndex(where: { $0 === currentInline }) {
            
            if index + 1 < currentAdVast.adInlines.count {
                currentInline = currentAdVast.adInlines[index]
                resetPlayer()
                playVideoAd()
            } else {
                displayEndView(true)
            }
        }
        hideSkipButton()
        hideMoreButton()
        delegate?.vpadnVideoAdViewDidStop(self)
    }
    
    private func skip() {
        guard let currentInline else { return }
        stop()
        currentAdVast?.sendTracking(by: "skip", currentInline: currentInline)
        delegate?.vpadnVideoAdViewSkipButtonTapped(self)
    }
    
    private func seekToTime(seconds: CGFloat) {
        guard state != .stopped else { return }
        var modifiedSeconds = max(0, seconds)
        modifiedSeconds = min(seconds, duration)
        
        player?.pause()
        player?.seek(to: CMTimeMakeWithSeconds(Float64(modifiedSeconds), preferredTimescale: Int32(NSEC_PER_SEC))) { finished in
            self.isPauseByUser = false
            self.player?.play()
            
            if let playerItem = self.playerItem, !playerItem.isPlaybackLikelyToKeepUp {
                self.state = .buffering
            }
        }
    }
    
    private func playerVolume() -> CGFloat {
        guard let player else { return 0 }
        if player.isMuted { return 0 }
        return CGFloat(player.volume)
    }
    
    // MARK: - Bahavior
    
    @objc private func moreButtonClicked() {
        guard let currentInline, let clickThroughURL = currentInline.clickThroughURL else { return }
        
        UIApplication.shared.open(clickThroughURL, options: [:]) { [weak self] success in
            guard let self else { return }
            if success {
                self.currentAdVast?.sendTracking(by: "clickTracking", currentInline: currentInline)
                self.adLifeCycleManager.notify(.onAdClicked)
                self.delegate?.vpadnVideoAdViewWasClicked(self)
            } else {
                self.sendErrorTracking(code: 900)
            }
        }
    }
    
    // MARK: - Tracking
    
    
    private func sendErrorTracking(code errorCode: Int) {
        guard let currentAdVast else { return }
        sendErrorTracking(code: errorCode, adVast: currentAdVast, adInline: currentInline)
    }
    
    private func sendErrorTracking(code errorCode: Int, adVast: VpadnAdVast, adInline: VpadnAdInline?) {
        guard let adInline else { return }
        adVast.sendTracking(by: "error", currentInline: adInline, marco: ["[ERRORCODE]": errorCode])
        
        var reason = ""
        var code = errorCode
        switch errorCode {
        case 300:
            reason = "general wrapper error."
        case 301:
            reason = "Timeout of VAST URI provided in Wrapper element or a subsequent Wrapper element"
        case 302:
            reason = "Wrapper limit reached"
        case 303:
            reason = "no VAST response after one or more Wrappers"
        case 400:
            reason = "general linear error"
        case 401:
            reason = "file not found. Unable to find Linear/MediaFile from URI"
        case 402:
            reason = "timeout of MediaFile URI"
        case 405:
            reason = "Problem displaying MediaFile"
        default:
            reason = "General VPAID error \(errorCode)"
            code = 901
        }
        
        let userInfo = [NSLocalizedDescriptionKey: reason,
                 NSLocalizedFailureReasonErrorKey: reason,
            NSLocalizedRecoverySuggestionErrorKey: "Contact vpon"]
        
        let error = NSError(domain: "com.vpon.vpadnad.errordomain", code: code, userInfo: userInfo)
        delegate?.vpadnVideoAdView(self, didFailLoading: error)
    }
    
    // MARK: - Helper
    
    private func parseVerifications(_ verifications: [[String: Any]]) -> [Verification] {
        var allVerifications = [Verification]()
        for data in verifications {
            if let vendor = data[Constants.OM.ADNKey.vendor] as? String,
               let params = data[Constants.OM.ADNKey.verificationParams] as? String,
               let jsResources = data[Constants.OM.ADNKey.javaScriptResources] as? [[String: Any]] {
                let vponResources = jsResources.map { attributes -> VpadnResource in
                    let attributesDict = attributes.reduce(into: [String: Any]()) { result, element in
                        result[element.key] = element.value
                    }
                    return VpadnResource(attributes: attributesDict)
                }
                
                var urls = [String]()
                for vponResource in vponResources {
                    if let url = vponResource.url {
                        urls.append(url.absoluteString)
                    }
                }
                let verification = Verification(vendorKey: vendor, verificationParams: params, verificationResources: urls)
                allVerifications.append(verification)
            }
        }
        return allVerifications
    }
    
    class func localizedDesc(_ desc: String) -> String {
        let descs = [
            "Learn More": ["en": "Learn More", "zh-Hant-TW": "了解更多"],
            "Replay": ["en": "Replay", "zh-Hant-TW": "再看一次"]
        ]
        
        guard let enums = descs[desc] else { return desc }
        
        let language = Locale.preferredLanguages.first ?? "en"
        guard let localizedText = enums[language] else { return desc }
        
        return localizedText
    }
    
    
    // MARK: - Color
    
    private func colorWithHex(_ hex: Int, alpha: CGFloat) -> UIColor {
        return UIColor(red: CGFloat((hex & 0xFF0000) >> 16) / 255.0,
                       green: CGFloat((hex & 0xFF00) >> 8) / 255.0,
                       blue: CGFloat(hex & 0xFF) / 255.0,
                       alpha: alpha)
    }
    
    // MARK: - Deinit
    
    deinit {
        adLifeCycleManager.notify(.onAdDestroyed)
        omManager?.unregisterAllEvents()
        
        if playTimer != nil, playTimer!.isValid {
            playTimer?.invalidate()
            playTimer = nil
        }
        if moreTimer != nil, moreTimer!.isValid {
            moreTimer?.invalidate()
            moreTimer = nil
        }
        if skipTimer != nil, skipTimer!.isValid {
            skipTimer?.invalidate()
            skipTimer = nil
        }
        if player != nil {
            player = nil
        }
        if playerItem != nil {
            playerItem = nil
        }
        if currentInline != nil {
            currentInline = nil
        }
        if currentAdVast != nil {
            currentAdVast = nil
        }
        VponConsole.log("[ARC] VpadnVideoAdView deinit")
    }
}

// MARK: - VpadnAdParserDelegate

extension VpadnVideoAdView: VpadnAdParserDelegate {
    func vpadnAdParserDidFinish(ad: VpadnAdVast) {
        if ad.adWrappers.count != 0 && ad.adInlines.count <= 0 {
            // No VAST response after one or more Wrappers
            sendErrorTracking(code: 303)
        } else {
            currentAdVast = ad
            currentInline = ad.adInlines.first
            resetPlayer()
            DispatchQueue.main.async {
                self.playVideoAd()
            }
        }
    }
    
    func vpadnAdGetWrapperDidError(ad: VpadnAdVast) {
        sendErrorTracking(code: 300, adVast: ad, adInline: nil)
    }
    
    func vpadnAdGetWrapperDidTimeOut(ad: VpadnAdVast) {
        sendErrorTracking(code: 301, adVast: ad, adInline: nil)
    }
    
    func vpadnAdOverWrapperLimit(ad: VpadnAdVast) {
        sendErrorTracking(code: 300, adVast: ad, adInline: nil)
    }
}

// MARK: - VpadnVideoAdURLSessionDelegate

extension VpadnVideoAdView: VpadnVideoAdURLSessionDelegate {
    func taskDidFinishLoading(_ task: VpadnVideoAdRequestTask) {
        didFinishLoading = task.didFinishLoading
    }
    
    func taskDidFailLoading(_ task: VpadnVideoAdRequestTask, error: Error) {
        if (error as NSError).code == -1001 {
            sendErrorTracking(code: 402)
        } else {
            sendErrorTracking(code: 400)
        }
        stop()
    }
}

// MARK: - VpadnVideoAdFullscreenViewDelegate

extension VpadnVideoAdView: VpadnVideoAdFullscreenViewDelegate {
    func callForDismiss() {
        shrinkScreen()
    }
}
