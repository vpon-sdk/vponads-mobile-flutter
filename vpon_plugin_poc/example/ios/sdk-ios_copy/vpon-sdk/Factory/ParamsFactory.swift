//
//  ParamsFactory.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/9/28.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import CoreLocation

struct ParamsFactory {
    
    private var request: VponAdRequest
    private var sdk = SDKHelper.shared
    private var locationManager = VponAdLocationManager.shared
    private var device = DeviceInfo.shared
    private var network = NetworkInfo.shared
    private var config = VponAdRequestConfiguration.shared
    
    init(request: VponAdRequest) {
        self.request = request
    }
    
    func getRequestParam(for key: AdRequestKey) -> String? {
        switch key {

            // MARK: - Device
            
        case .screenScale:
            return String(format: "%.0f", device.getScreenScale())
            
        case .timezone:
            return device.getTimeZoneAbbreviation()
            
        case .deviceOrientation:
            return String(device.getDeviceOrientation().rawValue)
            
        case .appLanguage:
            return device.getAppleLanguage()
            
        case .ucbConsentStatus:
            return device.getUCBConsent()
            
        case .deviceName:
            return device.getDeviceName()
            
        case .systemVersion:
            return device.getSystemVersion() as String
            
        case .screenWidth:
            return String(format: "%.0f", device.getScreenWidth())
            
        case .screenHeight:
            return String(format: "%.0f", device.getScreenHeight())
            
        case .deviceManufacturer:
            return device.getDeviceManufacturer()
            
        case .deviceModel:
            return device.getDeviceModel()
            
            // MARK: - SDK
            
        case .sdkVersion:
            return sdk.getSDKVersion()
            
        case .buildNumer:
            return sdk.getBuildNumber()
            
        case .appName:
            return sdk.getAppName()
            
        case .apiFramework:
            return sdk.getApiFramework()
            
        case .sessionID:
            return String(request.getSessionID())
            
        case .sequenceNumber:
            return String(request.getSequenceNumber())
            
            // MARK: - Network
            
        case .mobileContryCode:
            return network.getMobileCountryCode()
            
        case .networkType:
            return network.getNetworkType()
            
        case .networkInfoSim:
            if network.getNetworkType() != "0" {
                return network.getNetworkInfoSim()
            } else {
                return nil
            }
            
        case .mobileNetworkCode:
            return network.getMobileNetworkCode()
            
            // MARK: - MS
            
        case .ms:
            let info = getPrivateInfo()
            VponConsole.log("MS: \(info as AnyObject)")
            return encrypt(data: info)
        
        // MARK: - Request
            
        case .format:
            return request.format
            
        case .contentURL:
            return request.contentURL ?? ""
            
        case .contentData:
            guard request.contentDict.count > 0 else { return ""}
            
            if let data = try? JSONSerialization.data(withJSONObject: request.contentDict),
               var contentDataString = String(data: data, encoding: .utf8) {
                contentDataString = contentDataString.replacingOccurrences(of: "\\", with: "")
                return contentDataString
            } else { return "" }
            
        case .keywords:
            if request.keywords.count > 0 {
                var keywordString = ""
                for keyword in request.keywords {
                    if keyword == request.keywords.first {
                        keywordString = keyword
                    } else {
                        keywordString = keywordString.appendingFormat("%%7c%@", keyword)
                    }
                }
                return keywordString
            } else { return nil }
            
        case .isTest:
            return config.isTestAd
            
        case .maxAdContentRating:
            return String(config.maxAdContentRating.rawValue)
            
        case .underAgeOfConsent:
            return String(describing: config.tagForUnderAgeOfConsent.rawValue)
            
        case .childDirectedTreatment:
            return String(describing: config.tagForChildDirectedTreatment.rawValue)
            
        default:
            return nil
        }
    }
    
    // MARK: - Private(MS) info
    
    private func getPrivateInfo() -> [String: Any] {
        var info: [String: Any] = [:]
        
        var ssid: String?
        var bssid: String?
        if locationManager.isEnable && network.getNetworkType() == "0" {
            network.getWifiInfo { _ssid, _bssid in
                ssid = _ssid
                bssid = _bssid
            }
        }
        
        var location: CLLocation?
        var locationAge: Int?
        var placemark: CLPlacemark?
        locationManager.updateLocation { manager, locAge in
            location = manager.location
            locationAge = locAge
            placemark = self.locationManager.placemark
        } failure: { error in }

        
        for key in AdRequestMSKey.allCases {
            switch key {
                
            case .locLatitude:
                if let location {
                    info[key.rawValue] = String(location.coordinate.latitude)
                }
                
            case .locLongitude:
                if let location {
                    info[key.rawValue] = String(location.coordinate.longitude)
                }
                
            case .locAge:
                if let locationAge {
                    info[key.rawValue] = String(locationAge)
                }
                
            case .locCountryCode:
                info[key.rawValue] = placemark?.isoCountryCode ?? ""
                
            case .locAdmin:
                info[key.rawValue] = placemark?.administrativeArea ?? ""
                
            case .locSubAdmin:
                info[key.rawValue] = placemark?.subAdministrativeArea ?? ""
                
            case .locLocality:
                info[key.rawValue] = placemark?.locality ?? ""
                
            case .locPostalCode:
                info[key.rawValue] = placemark?.postalCode ?? ""
                
            case .locAccuracy:
                if let location, location.horizontalAccuracy >= 0.0 {
                    info[key.rawValue] = String(location.horizontalAccuracy)
                }
                
            case .limitAdTracking:
                info[key.rawValue] = device.advertisingTrackingEnabled() ? "true": "false"
                
            case .advertisingID:
                info[key.rawValue] = device.getAdvertisingIdentifier()
                
            case .identifierForVendor:
                info[key.rawValue] = device.getIdentifierFoVendor()
                
            case .ctid:
                info[key.rawValue] = device.getCTID()
                
            case .macAddress:
                var macAddress = MacAddress.shared.getMacAddress()
                if !macAddress.isEmpty {
                    macAddress = macAddress.replacingOccurrences(of: ":", with: "")
                    info[key.rawValue] = macAddress
                }
                
            case .wifiSSID:
                if let ssid {
                    info[key.rawValue] = ssid
                }
                
            case .wifiBSSID:
                if let bssid {
                    info[key.rawValue] = bssid
                }
                
            case .gender:
                if device.gender != .unspecified {
                    info[key.rawValue] = device.gender.rawValue
                }
                
            case .birthday:
                if device.haveBirth, let birthday = device.birthday {
                    let dateString = Date.dateString(birthday, format: "yyyy-MM-dd")
                    info[key.rawValue] = dateString
                }
            }
        }
        
        return info
    }
    
    private func encrypt(data: [String: Any]) -> String? {
        var strJson = ""
        if let dataJson = try? JSONSerialization.data(withJSONObject: data) {
            strJson = String(data: dataJson, encoding: .utf8) ?? ""
            if var strAESEncryption = VponAESEncryption.encryptAES(strJson) {
                strAESEncryption = strAESEncryption.replacingOccurrences(of: "/", with: "%2F")
                strAESEncryption = strAESEncryption.replacingOccurrences(of: "+", with: "%2B")
                strAESEncryption = strAESEncryption.replacingOccurrences(of: "=", with: "%3D")
                return strAESEncryption
            }
            return nil
        } else {
            return nil
        }
    }
}
