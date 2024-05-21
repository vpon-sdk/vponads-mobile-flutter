//
//  AdChoicesView.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/11/10.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

final class AdChoicesView: UIImageView {
    
    internal var position: String
    private var link: URL
    private var requestID: String
    
    private var tap: UITapGestureRecognizer?
    
    internal var onTap: (() -> Void)?
    
    // MARK: - Init
    
    init(position: String, link: URL, requestID: String, frame: CGRect) {
        self.position = position
        self.link = link
        self.requestID = requestID
        super.init(frame: frame)
        self.isUserInteractionEnabled = true
        self.contentMode = .scaleAspectFit
        loadImage()
    }
    
    required init?(coder: NSCoder) {
        // No need to implement
        self.position = Constants.AdChoicesPosition.upperRight
        self.link = URL(fileURLWithPath: "")
        self.requestID = ""
        super.init(coder: coder)
    }
    
    private func loadImage() {
        // Read ad choice image from local
        let bundle = Bundle(for: type(of: self))
        if let filePath = bundle.path(forResource: "AdChoicesIcon", ofType: "png"),
           let image = UIImage(contentsOfFile: filePath) {
            self.image = image
        } else {
            VponConsole.log("[Ad Choices] Failed to read Ad Choice image!")
        }
    }
    
    // MARK: - Handle tap gesture
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        if tap == nil {
            tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
            tap?.numberOfTapsRequired = 1
            self.addGestureRecognizer(tap!)
            tap?.delegate = self
        }
    }
    
    @objc private func imageTapped() {
        UIApplication.shared.open(link) { [weak self] result in
            VponConsole.log("[Ad Choices] Image tapped. Open link result: \(result)")
            self?.onTap?()
        }
    }
}

extension AdChoicesView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
}
