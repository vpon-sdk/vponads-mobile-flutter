//
//  AdPictureHelper.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/3/24.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Photos

struct AdPictureHelper {
    
    typealias PictureCompletion = (_ success: Bool, _ error: Error?) -> Void
    
    /// 儲存圖片
    /// - Parameters:
    ///   - picture: 圖片 參數模型
    ///   - completion: 完成的執行邏輯
    static func store(picture: AdPicture, completion: @escaping PictureCompletion) {
        guard picture.canStore else {
            completion(false, ErrorGenerator.photoUsage())
            return
        }
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                AdPictureHelper.save(picture: picture, completion: completion)
            } else {
                completion(false, ErrorGenerator.photoAuthorization())
            }
        }
    }
    
    static func save(picture: AdPicture, completion: @escaping PictureCompletion) {
        if let url = picture.url {
            do {
                let data = try Data(contentsOf: url)
                guard let img = UIImage(data: data) else {
                    completion(false, ErrorGenerator.photoURLFailed())
                    return
                }
               
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: img)
                }, completionHandler: completion)
            } catch  {
                completion(false, ErrorGenerator.photoURLFailed())
            }
        }
    }
}
