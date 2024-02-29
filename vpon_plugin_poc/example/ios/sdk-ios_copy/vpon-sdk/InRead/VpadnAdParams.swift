//
//  VPAdParams.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/4/28.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

let VAST_REQUEST_KEY_FORMAT = "format"
let VAST_REQUEST_KEY_IP = "ip"
let VAST_REQUEST_KEY_LANGUAGE = "language"
let VAST_REQUEST_KEY_ST = "st"
let VAST_REQUEST_KEY_SDK = "sdk"
let VAST_REQUEST_KEY_SDKV = "sdkv"
let VAST_REQUEST_KEY_OS = "os"
let VAST_REQUEST_KEY_OSV = "osv"
let VAST_REQUEST_KEY_ORIENTATION = "orientation"
let VAST_REQUEST_KEY_MAKE = "devmake"
let VAST_REQUEST_KEY_MODEL = "devmodel"
let VAST_REQUEST_KEY_TIME = "devtime"
let VAST_REQUEST_KEY_ZONE = "devtz"
let VAST_REQUEST_KEY_RATIO = "pxratio"
let VAST_REQUEST_KEY_TRACK = "dnt"
let VAST_REQUEST_KEY_CONETTYPE = "connection_type"
let VAST_REQUEST_KEY_SSID = "wifi_ssid"
let VAST_REQUEST_KEY_BSSID = "wifi_bssid"
let VAST_REQUEST_KEY_NETWORKINFOSIM = "nis"
let VAST_REQUEST_KEY_MCC = "mcc"
let VAST_REQUEST_KEY_MNC = "mnc"
let VAST_REQUEST_KEY_APPID = "appid"
let VAST_REQUEST_KEY_RDIDTYPE = "rdidtype"
let VAST_REQUEST_KEY_RDID = "rdid"
let VAST_REQUEST_KEY_IDFA = "idfa"
let VAST_REQUEST_KEY_LOC = "loc"
let VAST_REQUEST_KEY_LOCAGE = "loc_age"
let VAST_REQUEST_KEY_LOCPREC = "loc_prec"
let VAST_REQUEST_KEY_MAC = "mac"
let VAST_REQUEST_KEY_SCREENWIDTH = "s_w"
let VAST_REQUEST_KEY_SCREENHEIGHT = "s_h"
let VAST_REQUEST_KEY_GENDER = "gender"

class VpadnAdParams {
    
    /// 設置 ContentURL
    var contentURL: String?
    /// 設置 ContentData
    var contentDict: [String: Any] = [:]
    
    private let device = DeviceInfo.shared
    private let network = NetworkInfo.shared
    private let sdk = SDKHelper.shared
    private let location = VponAdLocationManager.shared
    
    static let shared = VpadnAdParams()
    
    private init() {}
    
    func getVastURL(with external: [String: Any]) -> String {
        var dictBuildAdReqURL = [String: Any]()
        if !external.isEmpty {
            dictBuildAdReqURL.append(external)
        }
        // Request
        dictBuildAdReqURL[VAST_REQUEST_KEY_FORMAT] = "json" //e.g. vast3 or json
        dictBuildAdReqURL[VAST_REQUEST_KEY_IP] = device.getIPAddress() ?? ""
        dictBuildAdReqURL[VAST_REQUEST_KEY_LANGUAGE] = device.getAppleLanguage() //e.g. it, ita
        dictBuildAdReqURL[VAST_REQUEST_KEY_ST] = "mobile_app" //e.g. mobile_app
        dictBuildAdReqURL[VAST_REQUEST_KEY_SDK] = "vpadn-sdk-i"
        dictBuildAdReqURL[VAST_REQUEST_KEY_SDKV] = sdk.getSDKVersion() //e.g. vpadn-sdk-i-v4.9.1
        
        // Device
        dictBuildAdReqURL[VAST_REQUEST_KEY_OS] = "iOS" //e.g. iOS
        dictBuildAdReqURL[VAST_REQUEST_KEY_OSV] = device.getSystemVersion() //e.g. 11.2
        let orientation = UIApplication.shared.statusBarOrientation
        let strCurrentOrientation = orientation == .portrait ? "v" : "h"
        dictBuildAdReqURL[VAST_REQUEST_KEY_ORIENTATION] = strCurrentOrientation //e.g. v or h
        dictBuildAdReqURL[VAST_REQUEST_KEY_MAKE] = "Apple" //e.g. Apple
        dictBuildAdReqURL[VAST_REQUEST_KEY_MODEL] = device.getDeviceModel() //e.g. iPhone9.1
        dictBuildAdReqURL[VAST_REQUEST_KEY_TIME] = device.getDeviceTime() //e.g. timestamp
        dictBuildAdReqURL[VAST_REQUEST_KEY_ZONE] = device.getTimeZoneName()
        dictBuildAdReqURL[VAST_REQUEST_KEY_RATIO] = device.getScreenScale() //e.g. 3.0
        let mac = device.getMacAddress()?.replacingOccurrences(of: ":", with: "")
        dictBuildAdReqURL[VAST_REQUEST_KEY_MAC] = mac
        dictBuildAdReqURL["dnt"] = device.advertisingTrackingEnabled() ? "1" : "0"
        
        if let contentURL {
            dictBuildAdReqURL[AdRequestKey.contentURL.rawValue] = contentURL
        }
        
        if !contentDict.keys.isEmpty {
            do {
                let data = try JSONSerialization.data(withJSONObject: contentDict)
                if var contentData = String(data: data, encoding: .utf8) {
                    contentData = contentData.replacingOccurrences(of: "\\", with: "")
                    if let safeData = contentData.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlUserAllowed) {
                        dictBuildAdReqURL[AdRequestKey.contentData.rawValue] = safeData
                    }
                }
            } catch {
                
            }
        }
        
        // Connection
        let networkType = network.getNetworkType()
        if networkType == "0" {
            dictBuildAdReqURL[VAST_REQUEST_KEY_CONETTYPE] = "wifi"
            network.getWifiInfo { ssid, bssid in
                if !ssid.isEmpty {
                    dictBuildAdReqURL[VAST_REQUEST_KEY_SSID] = ssid
                }
                if !bssid.isEmpty {
                    dictBuildAdReqURL[VAST_REQUEST_KEY_BSSID] = bssid
                }
            }
        } else {
            dictBuildAdReqURL[VAST_REQUEST_KEY_CONETTYPE] = "wan"
            dictBuildAdReqURL[VAST_REQUEST_KEY_NETWORKINFOSIM] = network.getNetworkInfoSim()
        }
        
        dictBuildAdReqURL[VAST_REQUEST_KEY_MCC] = network.getMobileCountryCode()
        dictBuildAdReqURL[VAST_REQUEST_KEY_MNC] = network.getMobileNetworkCode()
        
        // App
        dictBuildAdReqURL[VAST_REQUEST_KEY_APPID] = sdk.getAppID()
        
        // User sensitive
        dictBuildAdReqURL[VAST_REQUEST_KEY_RDIDTYPE] = "idfa"
        dictBuildAdReqURL[VAST_REQUEST_KEY_RDID] = device.getAdvertisingIdentifier()
        dictBuildAdReqURL[VAST_REQUEST_KEY_IDFA] = device.getAdvertisingIdentifier()
        
        location.updateLocation { manager, locAge in
            if let location = manager.location {
                if location.coordinate.latitude != 0.0 && location.coordinate.longitude != 0.0 {
                    let strLoc = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
                    dictBuildAdReqURL[VAST_REQUEST_KEY_LOC] = strLoc
                    dictBuildAdReqURL[VAST_REQUEST_KEY_LOCAGE] = String(locAge)
                }
                if location.horizontalAccuracy >= 0.0 {
                    dictBuildAdReqURL[VAST_REQUEST_KEY_LOCPREC] = String(location.horizontalAccuracy)
                }
            }
        } failure: { error in }
        
        dictBuildAdReqURL[VAST_REQUEST_KEY_SCREENWIDTH] = String(describing: device.getScreenWidth())
        dictBuildAdReqURL[VAST_REQUEST_KEY_SCREENHEIGHT] = String(describing: device.getScreenHeight())
        
        if device.haveGender && device.gender != .unknown {
            dictBuildAdReqURL[VAST_REQUEST_KEY_GENDER] = device.gender.rawValue
        }
        
        #if DEBUG
        var adURL = "https://static-ad.vpadn.com" // for test
        #else
        var adURL = "https://api-ssp.vpadn.com/mob"
        #endif
        
        if let dataBuildAdReqUrl = try? JSONSerialization.data(withJSONObject: dictBuildAdReqURL), var strJsonBuildAdReqUrl = String(data: dataBuildAdReqUrl, encoding: .utf8) {
            strJsonBuildAdReqUrl = strJsonBuildAdReqUrl.replacingOccurrences(of: #"{""#, with: "?")
            strJsonBuildAdReqUrl = strJsonBuildAdReqUrl.replacingOccurrences(of: "{", with: "?")
            strJsonBuildAdReqUrl = strJsonBuildAdReqUrl.replacingOccurrences(of: "\"}", with: "")
            strJsonBuildAdReqUrl = strJsonBuildAdReqUrl.replacingOccurrences(of: "}", with: "")
            strJsonBuildAdReqUrl = strJsonBuildAdReqUrl.replacingOccurrences(of: "\":\"", with: "=")
            strJsonBuildAdReqUrl = strJsonBuildAdReqUrl.replacingOccurrences(of: "\":", with: "=")
            strJsonBuildAdReqUrl = strJsonBuildAdReqUrl.replacingOccurrences(of: "\",\"", with: "&")
            strJsonBuildAdReqUrl = strJsonBuildAdReqUrl.replacingOccurrences(of: ",\"", with: "&")
            strJsonBuildAdReqUrl = strJsonBuildAdReqUrl.replacingOccurrences(of: "\\/", with: "/")
            
            adURL += strJsonBuildAdReqUrl
            
        } else {
            adURL += "{}"
        }
        return adURL
    }
}
