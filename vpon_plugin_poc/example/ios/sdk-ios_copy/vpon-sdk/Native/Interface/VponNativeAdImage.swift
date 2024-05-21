//
//  VponNativeAdImage.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/10/30.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

@objcMembers public final class VponNativeAdImage: NSObject {
    
    public var image: UIImage?
    /// Public for mediation
    public var imageURL: URL // cover_url from NativeAd
    internal var width: Int
    internal var height: Int
    internal var downloadQueue: OperationQueue?
    
    /// init method
    /// - Parameters:
    ///   - url: image's url
    ///   - width: image's width
    ///   - height: image's height
    internal init(url: URL, width: Int, height: Int) {
        self.imageURL = url
        self.width = width
        self.height = height
        super.init()
    }
    
    internal func loadImage(completion: @escaping (Bool) -> Void) {
        guard image == nil else { return }
        
        downloadQueue = OperationQueue()
        let task = URLSession.shared.dataTask(with: imageURL) { [weak self] data, response, error in
            if error == nil {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self,
                          let data = data,
                          let downloadedImage = UIImage(data: data) else {
                        completion(false)
                        return
                    }
                    self.image = downloadedImage
                    self.width = Int(downloadedImage.size.width)
                    self.height = Int(downloadedImage.size.height)
                    completion(true)
                }
            }
        }
        task.resume()
    }
}
