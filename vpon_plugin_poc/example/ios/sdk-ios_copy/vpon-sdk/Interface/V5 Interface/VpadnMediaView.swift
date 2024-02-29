//
//  VpadnMediaView.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/4/20.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import WebKit

@available(*, deprecated, message: "Use VponVideoController and VponVideoControllerDelegate instead.")
@objc public protocol VpadnMediaViewDelegate: AnyObject {
    @objc optional func mediaViewDidLoad(_ mediaView: VpadnMediaView)
    @objc optional func mediaViewDidFail(_ mediaView: VpadnMediaView, error: Error)
}

@available(*, deprecated, message: "Use VponMediaView instead.")
@objcMembers public class VpadnMediaView: UIView {

    // MARK: - Properties

    public weak var delegate: VpadnMediaViewDelegate?
    @objc public weak var nativeAd: VpadnNativeAd? {
        get { return _nativeAd }
        set {
            if _nativeAd != newValue {
                _nativeAd = newValue
                
                // load mediaView
                _nativeAd?.loadMediaView(newMediaView)
            }
        }
    }
    
    private weak var _nativeAd: VpadnNativeAd?

    // MARK: - v5.6 integration
    
    private var newMediaView: VponMediaView

    // MARK: - Initializers

    // Called when init from storyboard / nib
    public required init?(coder: NSCoder) {
        newMediaView = VponMediaView()
        super.init(coder: coder)
        newMediaView.frame = self.frame
        
        addSubview(newMediaView)
        newMediaView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: newMediaView.topAnchor),
            self.bottomAnchor.constraint(equalTo: newMediaView.bottomAnchor),
            self.trailingAnchor.constraint(equalTo: newMediaView.trailingAnchor),
            self.leadingAnchor.constraint(equalTo: newMediaView.leadingAnchor)
        ])
    }

    // MARK: - Deinit

    deinit {
        VponConsole.log("[ARC] VpadnMediaView deinit")
    }
}
