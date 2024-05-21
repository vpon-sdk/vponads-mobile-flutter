//
//  NetworkInfo.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/4/14.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation
import CoreTelephony
import SystemConfiguration
import SystemConfiguration.CaptiveNetwork

struct NetworkInfo {
    
    static let shared = NetworkInfo()
    
    private var mobileCountryCode = ""
    private var mobileNetworkCode = ""
    private var carrierName = ""
    private var isoCountryCode = ""
    private var allowsVOIP = false
    
    private init() {
        let info = CTTelephonyNetworkInfo()
        guard let carrier = info.subscriberCellularProvider else { return }
        if let temp = carrier.carrierName { carrierName = temp }
        if let temp = carrier.mobileCountryCode { mobileCountryCode = temp }
        if let temp = carrier.mobileNetworkCode { mobileNetworkCode = temp }
        if let temp = carrier.isoCountryCode { isoCountryCode = temp }
        allowsVOIP = carrier.allowsVOIP
    }
    
    /// 網路型態
    /// - Returns: -1 = unknown, 0 = Wifi, 1 = WWAN
    func getNetworkType() -> String {
        return self.currentReachabilityStatus()
    }
    
    /// Sim 的狀態
    /// - Returns: currentRadioAccessTechnology
    func getNetworkInfoSim() -> String {
        let info = CTTelephonyNetworkInfo()
        if #available(iOS 12.0, *) {
            guard let carrierTypes = info.serviceCurrentRadioAccessTechnology,
                  let key = carrierTypes.keys.first,
                  let carrierType = carrierTypes[key] else { return "" }
            return carrierType
        } else {
            guard let carrierType = info.currentRadioAccessTechnology else { return "" }
            return carrierType
        }
    }
    
    /// 取得 MobileCountryCode(mcc)
    /// - Returns: MobileCountryCode
    func getMobileCountryCode() -> String {
        return mobileCountryCode
    }
    
    /// 取得 MobileNetworkCode(mnc)
    /// - Returns: MobileNetworkCode
    func getMobileNetworkCode() -> String {
        return mobileNetworkCode
    }
    
    /// 取得 carrierName
    func getCarrierName() -> String {
        return carrierName
    }
    
    // MARK: - Wifi
    
    /// 取得 Wifi 資訊 (BSSID, SSID)
    /// - Parameter completion: 成功的執行邏輯
    func getWifiInfo(completion: @escaping (_ ssid: String, _ bssid: String) -> Void) {
        guard let interfaces = CNCopySupportedInterfaces() as NSArray? else { return }
        for interface in interfaces {
            guard let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? else { return }
            guard let ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String,
                  let bssid = interfaceInfo[kCNNetworkInfoKeyBSSID as String] as? String else { return }
            completion(ssid, bssid)
            break
        }
    }
    
    // MARK: - 回傳網路形態
    
    /// 取得網路狀態
    private func currentReachabilityStatus() -> String {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return "-1"
        }

        var flags: SCNetworkReachabilityFlags = []
        let success = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags)
        if !success { return "-1" }
        
        let isNetworkReachable = flags.contains(.reachable) && !flags.contains(.connectionRequired)
        if !isNetworkReachable { return "-1" }
        
        return flags.contains(.isWWAN) ? "1" : "0"
    }
}
