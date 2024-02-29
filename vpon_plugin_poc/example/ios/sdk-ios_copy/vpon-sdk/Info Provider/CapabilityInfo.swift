//
//  CapabilityInfo.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/3/31.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation
import CoreLocation
import MessageUI

final class CapabilityInfo {
    
    static let shared = CapabilityInfo()
    
    private let device = DeviceInfo.shared
    private let systemVersion: Float
    private var capabilities = ["m2",
                                "a",
                                "vid",
                                "vid2",
                                "vid3",
                                "vid4",
                                "vid5",
                                "crazyAd",
                                "stoPic",
                                "exp",
                                "inv"]
    
    private init() {
        systemVersion = device.getSystemVersion().floatValue
        capabilities = getCapabilities()
    }
    
    private func getCapabilities() -> [String] {
        if supportLocation() {
            capabilities.append("locF")
            capabilities.append("comp")
        }
        if supportTel() {
            capabilities.append("tel")
        }
        if supportCamera() {
            capabilities.append("cam")
        }
        if supportCal() {
            capabilities.append("cal")
        }
        if supportPhotoUsage() {
            capabilities.append("fr")
        }
        if supportPhotoAddUsage() {
            capabilities.append("fw")
        }
        if supportSMS() {
            capabilities.append("sms")
        }
        return capabilities
    }
    
    // This method is not being used.
    func getCapabilitiesToString() -> String {
        capabilities = getCapabilities()
        var combine = ""
        for capability in capabilities {
            if capability == capabilities.first {
                combine = capability
            } else {
                combine = combine.appendingFormat("_%@", capability)
            }
        }
        return combine
    }
    
    /// 是否支援短訊息
    func supportSMS() -> Bool {
        return MFMessageComposeViewController.canSendText()
    }
    
    /// 是否支援電話
    func supportTel() -> Bool {
        if let url = URL(string: "tel:+11111") {
            return UIApplication.shared.canOpenURL(url)
        } else { return false }
    }
    
    /// 是否支援相機
    func supportCamera() -> Bool {
        if let infos = Bundle.main.infoDictionary?.keys {
            if systemVersion < 10 || infos.contains("NSCameraUsageDescription") {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    return true
                }
            }
        }
        return false
    }
    
    /// 是否支援行事曆
    func supportCal() -> Bool {
        if let infos = Bundle.main.infoDictionary?.keys {
            return systemVersion < 10 || infos.contains("NSCalendarsUsageDescription")
        } else { return false }
    }
    
    /// 是否支援地理
    func supportLocation() -> Bool {
        if let infos = Bundle.main.infoDictionary?.keys {
            if systemVersion < 10 ||
                infos.contains("NSLocationUsageDescription") ||
                infos.contains("NSLocationWhenInUseUsageDescription") ||
                infos.contains("NSLocationAlwaysAndWhenInUseUsageDescription") {
                switch CLLocationManager.authorizationStatus() {
                case .authorizedAlways, .authorizedWhenInUse:
                    return true
                default:
                    return false
                }
            } else { return false }
        } else { return false }
    }
    
    /// 是否支援讀取圖片
    func supportPhotoUsage() -> Bool {
        if let infos = Bundle.main.infoDictionary?.keys {
            return systemVersion < 10 || infos.contains("NSPhotoLibraryUsageDescription")
        } else { return false }
    }
    
    /// 是否支援圖片寫入
    func supportPhotoAddUsage() -> Bool {
        if let infos = Bundle.main.infoDictionary?.keys {
            return systemVersion < 10 ||
            (systemVersion < 11 &&
             infos.contains("NSPhotoLibraryUsageDescription") ||
             infos.contains("NSPhotoLibraryAddUsageDescription"))
        } else { return false }
    }
}
