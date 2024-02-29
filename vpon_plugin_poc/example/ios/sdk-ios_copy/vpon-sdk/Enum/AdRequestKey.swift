//
//  AdRequestKey.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/9/28.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

enum AdRequestKey: String, CaseIterable {
    
    // 註解：有宣告但未實作的欄位
    
    case sdkVersion = "sdk"
    case buildNumer = "build"
//    case visible = "ad_v"
    
    case ms = "ms"
//    case fakeData = "fake_data"
    
    case isTest = "adtest"
    case format = "format"
    case licenseKey = "bid"
    case apiFramework = "af"
    
    case networkType = "ni"
    case networkInfoSim = "nis"
    case mobileContryCode = "mcc"
    case mobileNetworkCode = "mnc"
    case appName = "app_name"
//    case isTrack = "track"
//    case isSimulator = "simulator"
    
    case screenScale = "u_sd"
    case screenWidth = "s_w"
    case screenHeight = "s_h"
//    case nativeScale = "n_scale"
//    case nativeWidth = "n_w"
//    case nativeHeight = "n_h"
    case deviceOrientation = "u_o"
//    case interfaceOrientation = "i_o"
    case appLanguage = "lang"
    case ucbConsentStatus = "u_cb"
    
    case deviceName = "dev_fname"
    case systemVersion = "os_v"
    
    case sessionID = "sid"
    case sequenceNumber = "seq"
    
    case maxAdContentRating = "macr"
    case underAgeOfConsent = "uac"
    case childDirectedTreatment = "cdt"
    case contentURL = "content_url"
    case contentData = "content_data"
    case keywords = "kw"
    
    case timezone = "tz"
  
    case deviceManufacturer = "dev_man"
    case deviceModel = "dev_mod"
}


enum AdRequestMSKey: String, CaseIterable {
    
    case locLatitude = "u_lat"
    case locLongitude = "u_lon"
    case locAge = "latlon_age"
    case locCountryCode = "loc_cc"
    case locAdmin = "loc_adm"
    case locSubAdmin = "loc_sadm"
    case locLocality = "loc_loc"
    case locPostalCode = "loc_pc"
    case locAccuracy = "loc_acc"
    
    case limitAdTracking = "limit_ad_tracking"
    case advertisingID = "adv_id"
    case identifierForVendor = "idfv"
    case ctid = "Ctid"
    case macAddress = "mac"
    
    case wifiSSID = "wifi_ssid"
    case wifiBSSID = "wifi_bssid"
    
    case gender = "gender"
    case birthday = "bday"
}
