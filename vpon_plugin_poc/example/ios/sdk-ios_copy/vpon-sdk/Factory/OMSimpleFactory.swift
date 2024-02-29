//
//  OMSimpleFactory.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/10/20.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

struct OMInfo {
    var creativeType: OMIDCreativeType
    var impressionType: OMIDImpressionType
    var impressionOwner: OMIDOwner
    var mediaEventOwner: OMIDOwner
    var verifications: [Verification]?
}

struct OMSimpleFactory {
    
    func createOMManager(adLifeCycleManager: AdLifeCycleManager,
                         vponAdVerification: AdVerification?,
                         adView: UIView,
                         videoStateManager: VideoStateManager? = nil) -> OMManager? {
        
        switch vponAdVerification?.adType {
            // t = d
        case Constants.OM.ADNAdType.display:
            return createDisplayAdOMManager(adLifeCycleManager, adView, false)
            
            // t = dv
        case Constants.OM.ADNAdType.displayVideo:
            return createDisplayAdOMManager(adLifeCycleManager, adView, true)
            
            // t = n
        case Constants.OM.ADNAdType.native:
            return createNativeAdOMManager(adLifeCycleManager, adView, vponAdVerification?.verifications, false, videoStateManager)
            
            // t = nv, t = v
        case Constants.OM.ADNAdType.nativeAdVideo, Constants.OM.ADNAdType.nativeVideo:
            return createNativeAdOMManager(adLifeCycleManager, adView, vponAdVerification?.verifications, true, videoStateManager)
            
        default:
            return nil
        }
    }
    
    func createDisplayAdOMManager(_ adLifeCycleManager: AdLifeCycleManager, 
                                  _ adView: UIView,
                                  _ isVideoAd: Bool) -> OMManager {
        let impressionType: OMIDImpressionType = .unspecified
        let creativeType: OMIDCreativeType = isVideoAd ? .definedByJavaScript : .htmlDisplay
        let impressionOwner: OMIDOwner = isVideoAd ? .javaScriptOwner : .nativeOwner
        let mediaEventOwner: OMIDOwner = isVideoAd ? .javaScriptOwner : .noneOwner
        let info = OMInfo(creativeType: creativeType, impressionType: impressionType, impressionOwner: impressionOwner, mediaEventOwner: mediaEventOwner)
        let omManager = OMManager(adLifeCycleManager: adLifeCycleManager, info: info, adView: adView)
        
        return omManager
    }
    
    func createNativeAdOMManager(_ adLifeCycleManager: AdLifeCycleManager,
                                 _ adView: UIView,
                                 _ verifications: [Verification]?,
                                 _ isVideoAd: Bool,
                                 _ videoStateManager: VideoStateManager?) -> OMManager {
        let impressionType: OMIDImpressionType = .unspecified
        let creativeType: OMIDCreativeType = isVideoAd ? .video : .nativeDisplay
        let impressionOwner: OMIDOwner = .nativeOwner
        let mediaEventOwner: OMIDOwner = isVideoAd ? .nativeOwner : .noneOwner
        let info = OMInfo(creativeType: creativeType, impressionType: impressionType, impressionOwner: impressionOwner, mediaEventOwner: mediaEventOwner, verifications: verifications)
        let omManager = OMManager(adLifeCycleManager: adLifeCycleManager, info: info, adView: adView, videoStateManager: videoStateManager)
        
        return omManager
    }
}
