//
//  VpadnAdInline.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/4/28.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

class VpadnAdInline: VpadnAdBase {
    var adTitle: String?
    var categories: [VpadnCategory] = []
    var category: VpadnCategory?
    var surveies: [VpadnSurvey] = []
    var survey: VpadnSurvey?
    var desc: String?
    var advertiser: String?
    
    override init() {
        super.init()
    }
    
    func getMediaFile() -> VpadnMediaFile? {
        var creative: VpadnCreative?
        var linear: VpadnLinear?
        if !creatives.isEmpty {
            for temp in creatives {
                if  !temp.linear.mediaFiles.isEmpty {
                    creative = temp
                    linear = temp.linear
                    break
                } else { continue }
            }
        }
        return linear?.mediaFiles.first
    }
    
    func getAdVerifications() -> [VpadnVerification] {
        for vpExtension in self.extensions {
            if vpExtension.type == "AdVerifications" {
                return vpExtension.adVerifications
            }
        }
        return []
    }
}
