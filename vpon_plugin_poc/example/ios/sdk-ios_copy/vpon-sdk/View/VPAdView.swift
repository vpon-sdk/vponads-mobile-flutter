//
//  VPAdView.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/3/13.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

protocol VPAdViewDelegate: AnyObject {
    /// 視圖從畫面移除時 call back
    func vponAdViewDidMoveToNilWindow()
    /// 視圖被顯示在畫面 call back
    func vponAdViewDidMoveToOneWindow()
}

class VPAdView: UIView {
    
    weak var phoneGapVC: VPPhoneGapViewController?
    weak var webView: VPWebView?
    weak var delegate: VPAdViewDelegate?
    var observer = false
    var boundObserver = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = true
        self.translatesAutoresizingMaskIntoConstraints = false
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        phoneGapVC?.sendExposureChange()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if let superview = self.superview,
           let phoneGapVC = phoneGapVC,
           let principal = phoneGapVC.principal,
           let size = principal.materialSize {
            self.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.vpc_aspectFit(with: self, to: superview, materialSize: size)
            addObserverToSuperviews()
        }
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview == nil {
            // Should removeAllObserver when adView still have superview
            // It will be too late to removeAllObserver in deinit because at that moment the superview is nil, making it impossible to remove the observer attached to it.
            removeAllObserver()
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        let visible = self.superview != nil && self.window != nil
        if visible {
            webView?.observer = true
            delegate?.vponAdViewDidMoveToOneWindow()
        } else {
            delegate?.vponAdViewDidMoveToNilWindow()
            webView?.observer = false
        }
    }
    
    private func addObserverToSuperviews() {
        if !boundObserver {
            boundObserver = true
            self.superview?.addObserver(self, forKeyPath: "bounds", context: nil)
        }
    }
    
    private func removeAllObserver() {
        if boundObserver {
            boundObserver = false
            self.superview?.removeObserver(self, forKeyPath: "bounds")
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let superview,
              let object, let objectView = object as? UIView else { return }
        
        if objectView == superview && keyPath == "bounds" {
            guard let phoneGapVC, let principal = phoneGapVC.principal, let size = principal.materialSize else { return }
            
            self.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.vpc_aspectFit(with: self, to: superview, materialSize: size)
        }
    }
    
    deinit {
        VPSDKHelper.log("VponAdView deinit")
    }
}
