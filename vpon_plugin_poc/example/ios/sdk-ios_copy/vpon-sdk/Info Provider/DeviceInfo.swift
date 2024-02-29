//
//  DeviceInfo.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/3/30.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import AdSupport
import AppTrackingTransparency
import WebKit

final class DeviceInfo {
    
    // MARK: - Property
    
    /// 是否有設置年齡
    var haveAge = false
    var age: Int = 0 {
        didSet { haveAge = true }
    }
    
    /// 是否有設置生日
    var haveBirth = false
    var birthday: Date? {
        didSet { haveBirth = true }
    }
    
    /// 是否有設置性別
    var haveGender = false
    var gender: VponUserGender = .unspecified {
        didSet { haveGender = true }
    }
    
    private var userAgent: String?
    
    private var localInfo = LocalStorageInfo.shared
    
    static let shared = DeviceInfo()
    
    // MARK: - Method
    
    private init() {}
    
    class func setUserAgent() {
        if let cachedUserAgent = UserDefaults.standard.string(forKey: Constants.UserDefaults.userAgent), !cachedUserAgent.isEmpty {
            DeviceInfo.shared.userAgent = cachedUserAgent
        } else {
            let systemVersion = UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "_")
            let deviceType = UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
            DeviceInfo.shared.userAgent = "Mozilla/5.0 (\(deviceType); CPU \(deviceType) OS \(systemVersion) like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"
        }
        DispatchQueue.main.async {
            let tmpWebView = WKWebView()
            tmpWebView.evaluateJavaScript("navigator.userAgent") { result, error in
                if error == nil, let result = result as? String {
                    DeviceInfo.shared.userAgent = result
                    UserDefaults.standard.set(result, forKey: Constants.UserDefaults.userAgent)
                }
            }
        }
    }
    
    func setBirthday(year: Int, month: Int, day: Int) {
        let dateString = String(format: "%04ld-%02ld-%02ld", year, month, day)
        let oneDay = Date.parseDate(with: dateString)
        if let oneDay {
            self.birthday = oneDay
        }
    }
    
    /// 是否為手機
    /// - Returns: UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone
    class func isPhone() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
    
    /// 是否為模擬器
    /// ```
    /// 1 = 模擬器 / 0 = 正式機
    /// ```
    /// - Returns: [NSNumber numberWithBool:[deviceName isEqualToString:@"i386"] || [deviceName isEqualToString:@"x86_64"]]
    func isSimulator() -> NSNumber {
        let deviceName = getDeviceName()
        return NSNumber(value: deviceName == "i386" || deviceName == "x86_64")
    }
    
    class func isTestDevice(testIDFA: [String]) -> Bool {
        let currentIDFA = DeviceInfo.shared.getAdvertisingIdentifier()
        return testIDFA.contains(currentIDFA)
    }
    
    /// 是否可以追蹤
    /// ```
    /// 1 = 可以 / 0 = 關閉
    /// ```
    /// - Returns: [ASIdentifierManager sharedManager].advertisingTrackingEnabled
    func advertisingTrackingEnabled() -> Bool {
        if #available(iOS 14, *) {
            switch ATTrackingManager.trackingAuthorizationStatus {
            case .authorized:
                return true
            default:
                return false
            }
        } else {
            // Fallback on earlier versions
            return ASIdentifierManager.shared().isAdvertisingTrackingEnabled
        }
    }
    
    /// 屏幕Scale
    /// ```
    /// 1.0 / 2.0 / 3.0
    /// ```
    /// - Returns: [UIScreen mainScreen].scale
    func getScreenScale() -> CGFloat {
        return UIScreen.main.scale
    }
    
    /// Native Scale. Document: iOS Device Display Summary
    /// - Returns: [UIScreen mainScreen].nativeScale
    func getNativeScale() -> CGFloat {
        return UIScreen.main.nativeScale
    }
    
    /// 屏幕的寬
    /// ```
    /// 320
    /// ```
    /// - Returns: [UIScrren mainScreen].size.width
    func getScreenWidth() -> CGFloat {
        return UIScreen.main.bounds.size.width
    }
    
    /// 屏幕的高
    /// ```
    /// 568
    /// ```
    /// - Returns: [UIScrren mainScreen].size.height
    func getScreenHeight() -> CGFloat {
        return UIScreen.main.bounds.size.height
    }
    
    /// 屏幕的DP寬
    /// ```
    /// 568
    /// ```
    /// - Returns: [UIScrren mainScreen].size.height / [UIScreen mainScreen].nativeScale
    func getNativeWidth() -> CGFloat {
        return UIScreen.main.bounds.size.width
    }
    
    /// 屏幕的DP高
    /// ```
    /// 568
    /// ```
    /// - Returns: [UIScrren mainScreen].size.height / [UIScreen mainScreen].nativeScale
    func getNativeHeight() -> CGFloat {
        return UIScreen.main.bounds.size.height
    }
    
    /// 取得系統版本
    /// - Returns: [UIDevice currentDevice].systemVersion
    func getSystemVersion() -> NSString {
        return NSString(string: UIDevice.current.systemVersion)
    }
    
    /// Device full name
    func getDeviceName() -> String {
        return getPlatformString()
    }
    
    /// Device model
    func getDeviceModel() -> String {
        return UIDevice.current.model
    }
    
    /// Device manufacturer
    /// - Returns: "Apple"
    func getDeviceManufacturer() -> String {
        return "Apple"
    }
    
    /// 取得廣告ID (IDFA)
    func getAdvertisingIdentifier() -> String {
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
    
    /// 取得 IDFV
    func getIdentifierFoVendor() -> String? {
        return UIDevice.current.identifierForVendor?.uuidString
    }
    
    /// 取得CTID
    func getCTID() -> String {
        let userDefault = UserDefaults.standard
        var ctid = ""
        if let savedCtid = userDefault.string(forKey: Constants.UserDefaults.ctid) {
            // 1) Read from UserDefault & Update local
            ctid = savedCtid
            if !localInfo.isExists(key: Constants.UserDefaults.ctid) {
                localInfo.update(key: Constants.UserDefaults.ctid, value: ctid)
            }
        } else if localInfo.isExists(key: Constants.UserDefaults.ctid) {
            // 2) Read from local & Set UserDefault
            ctid = localInfo.read(key: Constants.UserDefaults.ctid)
            userDefault.set(ctid, forKey: Constants.UserDefaults.ctid)
        } else {
            // 3) Can't find ctid -> Create new and save
            let date = (Date().timeIntervalSince1970) * 1000
            let dateString = String(format: "%.0f", date)
            let uuidString = UUID().uuidString
            ctid = "\(Constants.UserDefaults.ctidVersion)_\(uuidString).\(dateString)"
            userDefault.set(ctid, forKey: Constants.UserDefaults.ctid)
            localInfo.update(key: Constants.UserDefaults.ctid, value: ctid)
        }
        return ctid
    }
    
    /// 取得 UCB Consent
    func getUCBConsent() -> String {
        if let data = UserDefaults.standard.object(forKey: Constants.UserDefaults.consent) as? Data,
           let decodedData = Data(base64Encoded: data, options: Data.Base64DecodingOptions(rawValue: 0)),
           let decodedString = String(data: decodedData, encoding: .utf8) {
            return decodedString
        } else {
            return "-1"
        }
    }
    
    /// 裝置的語系
    /// en
    /// - Returns: UserDefaults.standard.object(forKey: "AppleLanguages")[0]
    func getAppleLanguage() -> String {
        if let languages = UserDefaults.standard.object(forKey: "AppleLanguages") as? [String], !languages.isEmpty {
            return languages[0]
        } else {
            return ""
        }
    }
    
    /// 裝置時間
    /// - Returns: Timestamp String
    func getDeviceTime() -> String {
        return String(format: "%.0f", Date().timeIntervalSince1970)
    }
    
    /// Time Zone
    /// - Returns: UTC+8
    func getTimeZoneName() -> String {
        return TimeZone.current.identifier
    }
    
    /// 裝置時區
    /// - Returns: Zone
    func getTimeZoneAbbreviation() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "ZZZZ"
        var gmtTZ = dateFormatter.string(from: Date())
        return gmtTZ
    }
    
    /// 裝置面向
    func getDeviceOrientation() -> UIDeviceOrientation {
        return UIDevice.current.orientation
    }
    
    /// 狀態列方向
    func getInterfaceOrientation() -> UIInterfaceOrientation {
        return UIApplication.shared.statusBarOrientation
    }
    
    /// User-Agent
    func getUserAgent() -> String? {
        return userAgent
    }
    
    /// IP 地址
    /// - Returns: IP address of WiFi interface (en0) as a String, or `nil`
    func getIPAddress() -> String? {
        var address: String?
        
        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }
        
        // For each interface ...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            
            // Check for IPv4 or IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                
                // Check interface name:
                let name = String(cString: interface.ifa_name)
                if  name == "en0" {
                    
                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)
        
        return address
    }
    
    /// 設備的 mac 地址
    func getMacAddress() -> String? {
        let index  = Int32(if_nametoindex("en0"))
        let bsdData = "en0".data(using: .utf8)!
        var mib : [Int32] = [CTL_NET,AF_ROUTE,0,AF_LINK,NET_RT_IFLIST,index]
        var len = 0;
        if sysctl(&mib,UInt32(mib.count), nil, &len,nil,0) < 0 {
            return nil
        }
        var buffer = [CChar].init(repeating: 0, count: len)
        if sysctl(&mib, UInt32(mib.count), &buffer, &len, nil, 0) < 0 {
            return nil
        }
        let infoData = NSData(bytes: buffer, length: len)
        var interfaceMsgStruct = if_msghdr()
        infoData.getBytes(&interfaceMsgStruct, length: MemoryLayout.size(ofValue: if_msghdr()))
        let socketStructStart = MemoryLayout.size(ofValue: if_msghdr()) + 1
        let socketStructData = infoData.subdata(with: NSMakeRange(socketStructStart, len - socketStructStart))
        let rangeOfToken = socketStructData.range(of: bsdData, options: NSData.SearchOptions(rawValue: 0), in: Range.init(uncheckedBounds: (0, socketStructData.count)))
        let start = rangeOfToken?.count ?? 0 + 3
        let end = start + 6
        let range1 = start..<end
        var macAddressData = socketStructData.subdata(in: range1)
        let macAddressDataBytes: [UInt8] = [UInt8](repeating: 0, count: 6)
        macAddressData.append(macAddressDataBytes, count: 6)
        let macaddress = String(format: "%02X:%02X:%02X:%02X:%02X:%02X", macAddressData[0], macAddressData[1], macAddressData[2],
                                macAddressData[3], macAddressData[4], macAddressData[5])
        return macaddress.uppercased()
    }
    
    /// 回傳手機型號
    private func getPlatformString() -> String {
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0,  count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        return String(cString: machine)
    }
}
