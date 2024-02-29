//
//  InterstitialViewController.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/10/11.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

protocol InterstitialViewControllerDelegate: AnyObject {
    func viewControllerWillDismiss(_ viewController: InterstitialViewController)
    func viewControllerDidDismiss(_ viewController: InterstitialViewController)
}

final class InterstitialViewController: UIViewController {
    
    private var webView: DisplayAdWebView
    weak var rootViewController: UIViewController?
    
    private var initialProperty: InitialProperty
    
    private var closeButton: UIButton?
    private let leftBlackMarginView: UIView = UIView()
    private let rightBlackMarginView: UIView = UIView()
    
    private var oriOrientation: UIInterfaceOrientation = .unknown
    
    weak var delegate: InterstitialViewControllerDelegate?
    
    // MARK: - Init
    
    init(webView: DisplayAdWebView, initialProperty: InitialProperty) {
        self.webView = webView
        self.initialProperty = initialProperty
        
        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .overFullScreen
        view.backgroundColor = .clear
       
        view.addSubview(webView)
        NSLayoutConstraint.vpc_fullScreen(with: webView, to: view)
    }
    
    // Not being used
    required init?(coder: NSCoder) {
        webView = DisplayAdWebView(frame: .zero)
        initialProperty = InitialProperty()
        super.init(coder: coder)
    }
    
    // MARK: - Life cycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addOrientationObserver()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeOrientationObserver()
    }
    
    // MARK: - Load webView content
    
    func loadContent(html: String?, baseURL: URL?) {
        webView.loadContent(html: html, baseURL: baseURL)
    }
    
    // MARK: - App life cycle notification
    
    func addOrientationObserver() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(orientationDidChange(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    func removeOrientationObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func orientationDidChange(_ notification: Notification) {
        adjustUIConstraint()
    }
    
    // MARK: - UI Constraint
    
    func showCloseButton() {
        if closeButton == nil {
            let imageData = Data(imageBytesOfVideoBigCloseButton)
            if let image = UIImage(data: imageData) {
                closeButton = UIButton.vp_btn(image: image, target: self, selector: #selector(dismissVC))
                view.addSubview(closeButton!)
                if let closeButton, let superview = closeButton.superview {
                    NSLayoutConstraint.vpc_leftTop(with: closeButton, addTo: superview, multiplier: 1, constant: 50)
                }
            }
        }
        closeButton?.isHidden = initialProperty.expandProperty.useCustomClose
    }
    
    @objc func dismissVC() {
        returnOriginOrientation()
        
        self.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            self.delegate?.viewControllerDidDismiss(self)
        }
    }
    
    private func adjustUIConstraint() {
        if let webViewSuperView = webView.superview {
            NSLayoutConstraint.vpc_fullScreen(with: self.webView, to: webViewSuperView)
        }
        if let closeButton = closeButton, let closeBtnSuperview = closeButton.superview {
            NSLayoutConstraint.vpc_leftTop(with: closeButton, addTo: closeBtnSuperview, multiplier: 1, constant: CGFloat(Constants.defaultISCloseBtnDistance))
            self.view.bringSubviewToFront(closeButton)
        }
        
        leftBlackMarginView.removeFromSuperview()
        rightBlackMarginView.removeFromSuperview()
        
        // When Lanscape, add blackMarginViews to fill left & right safe area
        // When UpsideDown, bottomAnchor(home indicator) will be on left or right side -> Use same method
        if UIDevice.current.orientation.isLandscape ||
            UIDevice.current.orientation == .portraitUpsideDown {
            leftBlackMarginView.backgroundColor = .black
            self.view.addSubview(leftBlackMarginView)
            NSLayoutConstraint.vpc_leftMargin(with: leftBlackMarginView, to: webView)
            
            rightBlackMarginView.backgroundColor = .black
            self.view.addSubview(rightBlackMarginView)
            NSLayoutConstraint.vpc_rightMargin(with: rightBlackMarginView, to: webView)
        }
    }
    
    // MARK: - 紀錄/還原 初始位置

    func recordOriginOrientation() {
        self.oriOrientation = DeviceInfo.shared.getInterfaceOrientation()
    }

    func returnOriginOrientation() {
        UIDevice.current.setValue(oriOrientation.rawValue, forKey: "orientation")
    }
    
    func updateInitialProperty(with property: InitialProperty) {
        self.initialProperty = property
    }
    
    // MARK: - Orientation
    
    override var shouldAutorotate: Bool { return true }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        guard !initialProperty.orientationProperty.allowOrientationChange else {
            return UIInterfaceOrientationMask.all
        }
        if initialProperty.orientationProperty.forceOrientation == .landscape {
            return UIInterfaceOrientationMask.landscape
        } else {
            return UIInterfaceOrientationMask.portrait
        }
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        if (!initialProperty.orientationProperty.allowOrientationChange) {
            switch initialProperty.orientationProperty.forceOrientation {
            case .landscape:
                return UIInterfaceOrientation.landscapeRight
            default:
                return UIInterfaceOrientation.portrait
            }
        } else {
            guard let preferredOrientation = rootViewController?.preferredInterfaceOrientationForPresentation else {
                return UIInterfaceOrientation.portrait
            }
            switch preferredOrientation {
            case .unknown:
                return UIInterfaceOrientation.portrait
            default:
                return preferredOrientation
            }
        }
    }
    
    func expandForceOrientation() {
        guard !initialProperty.orientationProperty.allowOrientationChange else { return }
        
        let forceOrientation = initialProperty.orientationProperty.forceOrientation
        let interfaceOrientation = DeviceInfo.shared.getInterfaceOrientation()
        
        if forceOrientation == .landscape && interfaceOrientation == .portrait {
            UIDevice.current.setValue(UIDeviceOrientation.landscapeRight.rawValue, forKey: "orientation")
        } else {
            UIDevice.current.setValue(UIDeviceOrientation.portrait.rawValue, forKey: "orientation")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.adjustUIConstraint()
        }
    }
    
    // MARK: - Deinit
    
    deinit {
        VponConsole.log("[ARC] InterstitialViewController deinit")
    }
}
