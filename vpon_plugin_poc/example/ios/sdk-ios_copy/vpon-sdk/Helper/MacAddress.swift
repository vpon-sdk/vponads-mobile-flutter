//
//  MacAddress.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/4/14.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import CommonCrypto

struct MacAddress {
    
    static let shared = MacAddress()
    
    private init() {}
    
    func getMacAddress() -> String {
        let index  = Int32(if_nametoindex("en0"))
        let bsdData = "en0".data(using: .utf8)!
        var mib : [Int32] = [CTL_NET,AF_ROUTE,0,AF_LINK,NET_RT_IFLIST,index]
        var len = 0;
        if sysctl(&mib,UInt32(mib.count), nil, &len,nil,0) < 0 {
            VponConsole.log("Error: could not determine length of info data structure")
            return "00:00:00:00:00:00"
        }
        var buffer = [CChar].init(repeating: 0, count: len)
        if sysctl(&mib, UInt32(mib.count), &buffer, &len, nil, 0) < 0 {
            VponConsole.log("Error: could not read info data structure")
            return "00:00:00:00:00:00"
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
        let macaddress = String.init(format: "%02X:%02X:%02X:%02X:%02X:%02X", macAddressData[0], macAddressData[1], macAddressData[2],
                                     macAddressData[3], macAddressData[4], macAddressData[5])
        return macaddress
    }
    
    // MARK: - Unused func

    func uniqueGlobalDeviceIdentifier() -> String? {
        let macAddress = getMacAddress().uppercased().replacingOccurrences(of: ":", with: "")
        let uniqueMD5Identifier = md5(macAddress)
        return uniqueMD5Identifier
    }
 
    private func md5(_ str: String) -> String? {
        guard let cStr = str.cString(using: .utf8) else {
            return nil
        }
        
        var result = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        CC_MD5(cStr, CC_LONG(cStr.count - 1), &result)
        
        return result.map { String(format: "%02hhx", $0) }.joined()
    }
}
