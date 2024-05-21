//
//  VpadnVideoAdFullscreenView.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/5/5.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import AVFoundation

protocol VpadnVideoAdFullscreenViewDelegate: AnyObject {
    func callForDismiss()
}

class VpadnVideoAdFullscreenView: UIView {
    
    private weak var delegate: VpadnVideoAdFullscreenViewDelegate?
    private weak var functionView: UIView?
    private weak var playerLayer: AVPlayerLayer?
    private var closeButton: UIButton?
    
    private var vConstraints = [NSLayoutConstraint]()
    private var hConstraints = [NSLayoutConstraint]()
    private var closeHeight: NSLayoutConstraint?
    private var closeTop: NSLayoutConstraint?
    private var closeTrail: NSLayoutConstraint?
    private var areaTop: NSLayoutConstraint?
    
    init(withAVPlayerLayer playerLayer: AVPlayerLayer, functionView: UIView, delegate: VpadnVideoAdFullscreenViewDelegate) {
        self.functionView = functionView
        self.playerLayer = playerLayer
        self.delegate = delegate
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let playerLayer else { return }
        playerLayer.frame = self.bounds
        if let sublayers = layer.sublayers {
            if !sublayers.contains(playerLayer) {
                layer.insertSublayer(playerLayer, at: 0)
            }
        }
        updateFuncConstraints()
    }
    
    internal func presentFullScreen() {
        buildUI()
    }
    
    private func dynamicHeight(_ height: CGFloat) -> CGFloat {
        // return playerLayer.videoRect.size.height * height / 180
        return height
    }
    
    private func buildUI() {
        guard let playerLayer, let functionView else { return }
        playerLayer.removeFromSuperlayer()
        functionView.removeFromSuperview()
        
        backgroundColor = .black
        translatesAutoresizingMaskIntoConstraints = false
        
        guard let superView = UIApplication.shared.keyWindow?.rootViewController?.view else { return }
        
        superView.addSubview(self)
        
        let orientation = UIApplication.shared.statusBarOrientation
        var topPadding: CGFloat = orientation == .portrait ? 20 : 0
        var bottomPadding: CGFloat = 0
        
        if let window = SDKHelper.getKeyWindow() {
            topPadding = orientation == .portrait ? UIApplication.shared.statusBarFrame.size.height : 0
            bottomPadding = orientation == .portrait ? window.safeAreaInsets.bottom : 0
        }
        
        vConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(==topPadding)-[self]-(==bottomPadding)-|",
                                                      options: [],
                                                      metrics: ["topPadding": topPadding, "bottomPadding": bottomPadding],
                                                      views: ["self": self])
        superView.addConstraints(vConstraints)
        superView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[self]-0-|",
                                                                options: [],
                                                                metrics: nil,
                                                                views: ["self": self]))
        
        closeButton = UIButton(type: .custom)
        let restoreData = Data(bytes: arrayRestore, count: arrayRestore.count)
        closeButton!.setImage(UIImage(data: restoreData), for: .normal)
        closeButton!.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        closeButton!.translatesAutoresizingMaskIntoConstraints = false
        addSubview(closeButton!)
        
        insertSubview(functionView, belowSubview: closeButton!)
        
        closeTrail = NSLayoutConstraint(item: functionView, attribute: .trailing, relatedBy: .equal, toItem: closeButton, attribute: .trailing, multiplier: 1, constant: dynamicHeight(4))
        addConstraint(closeTrail!)
        
        closeTop = NSLayoutConstraint(item: closeButton!, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: dynamicHeight(4))
        addConstraint(closeTop!)
        
        closeHeight = NSLayoutConstraint(item: closeButton!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: dynamicHeight(20))
        closeButton?.addConstraint(closeHeight!)
        
        closeButton?.addConstraint(NSLayoutConstraint(item: closeButton!, attribute: .height, relatedBy: .equal, toItem: closeButton, attribute: .width, multiplier: 1, constant: 0))
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[functionView]-0-|", options: [], metrics: nil, views: ["functionView": functionView]))
        
        var leftPadding: CGFloat = 0
        var rightPadding: CGFloat = 0
        
        if let window = SDKHelper.getKeyWindow() {
            leftPadding = orientation != .portrait ? window.safeAreaInsets.left : 0
            rightPadding = orientation != .portrait ? window.safeAreaInsets.right : 0
        }
        
        hConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(==leftPadding)-[functionView]-(==rightPadding)-|",
                                                      options: [],
                                                      metrics: ["leftPadding": leftPadding, "rightPadding": rightPadding],
                                                      views: ["functionView": functionView])
        addConstraints(hConstraints)
    }
    
    private func updateFuncConstraints() {
        guard let functionView else { return }
        if let closeHeight {
            closeHeight.constant = dynamicHeight(20)
        }
        if let closeTrail {
            closeTrail.constant = dynamicHeight(4)
        }
        if let closeTop {
            closeTop.constant = dynamicHeight(4)
        }
        
        guard let superView = UIApplication.shared.keyWindow?.rootViewController?.view,
              superView.subviews.contains(self) else { return }
        
        superView.removeConstraints(vConstraints)
        removeConstraints(hConstraints)
        
        let orientation = UIApplication.shared.statusBarOrientation
        var topPadding: CGFloat = orientation == .portrait ? 20 : 0
        var bottomPadding: CGFloat = 0
    
        if let window = SDKHelper.getKeyWindow() {
            topPadding = orientation == .portrait ? UIApplication.shared.statusBarFrame.size.height : 0
            bottomPadding = orientation == .portrait ? window.safeAreaInsets.bottom : 0
        }
        
        vConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(==topPadding)-[self]-(==bottomPadding)-|",
                                                          options: [],
                                                          metrics: ["topPadding": topPadding, "bottomPadding": bottomPadding],
                                                          views: ["self": self])
        superView.addConstraints(vConstraints)
        
        var leftPadding: CGFloat = 0
        var rightPadding: CGFloat = 0
     
        if let window = SDKHelper.getKeyWindow() {
            leftPadding = orientation != .portrait ? window.safeAreaInsets.left : 0
            rightPadding = orientation != .portrait ? window.safeAreaInsets.right : 0
        }
        
        hConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(==leftPadding)-[functionView]-(==rightPadding)-|",
                                                          options: [],
                                                          metrics: ["leftPadding": leftPadding, "rightPadding": rightPadding],
                                                          views: ["functionView": functionView])
        addConstraints(hConstraints)
    }
    
    @objc private func dismiss() {
        playerLayer?.removeFromSuperlayer()
        functionView?.removeFromSuperview()
        delegate?.callForDismiss()
        removeFromSuperview()
    }
}
