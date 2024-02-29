//
//  VponAESEncryption.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/4/25.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import CommonCrypto

let vpadnKeyPointer: [UInt8] = [52, 127, -26, 45, -20, -126, 5, -6, 36, -51, -126, -108, 60, -47, -124, 18].map { UInt8(bitPattern: Int8($0))}

extension Data {
    
    func aes256Encrypt() -> Data? {
        let dataLength = self.count
        let bufferSize = dataLength + kCCBlockSizeAES128
        let buffer = UnsafeMutableRawPointer.allocate(byteCount: bufferSize, alignment: 1)
        var numBytesEncrypted: size_t = 0
        let cryptStatus = self.withUnsafeBytes { dataBytes in
            CCCrypt(CCOperation(kCCEncrypt),
                    CCAlgorithm(kCCAlgorithmAES128),
                    CCOptions(kCCOptionPKCS7Padding),
                    vpadnKeyPointer,
                    kCCBlockSizeAES128,
                    nil,
                    dataBytes.baseAddress,
                    dataLength,
                    buffer,
                    bufferSize,
                    &numBytesEncrypted)
        }
        if cryptStatus == kCCSuccess {
            return Data(bytesNoCopy: buffer, count: numBytesEncrypted, deallocator: .free)
        }
        buffer.deallocate()
        return nil
    }
    
    func aes256Decrypt() -> Data? {
        let dataLength = self.count
        let bufferSize = dataLength + kCCBlockSizeAES128
        let buffer = UnsafeMutableRawPointer.allocate(byteCount: bufferSize, alignment: 1)
        var numBytesEncrypted: size_t = 0
        let cryptStatus = self.withUnsafeBytes { dataBytes in
            CCCrypt(CCOperation(kCCDecrypt),
                    CCAlgorithm(kCCAlgorithmAES128),
                    CCOptions(kCCOptionPKCS7Padding),
                    vpadnKeyPointer,
                    kCCBlockSizeAES128,
                    nil,
                    dataBytes.baseAddress,
                    dataLength,
                    buffer,
                    bufferSize,
                    &numBytesEncrypted)
        }
        if cryptStatus == kCCSuccess {
            return Data(bytesNoCopy: buffer, count: numBytesEncrypted, deallocator: .free)
        }
        buffer.deallocate()
        return nil
    }
}

struct VponAESEncryption {
    
    /// 使用 AES256 再用 Base64 加密
    static func encryptAES(_ dataString: String) -> String? {
        // String to Data
        if let plain = dataString.data(using: .utf8) {
            
            // AES encode
            let cipher = plain.aes256Encrypt()
            
            // Base64 encode
            let encode64 = cipher?.base64EncodedString()
            
            return encode64
        } else { return nil }
    }
    
    /// 使用 Base64 與 AES256 解密
    /// - Parameter base64Encoded: 經過 Base64 encoded 的 String
    /// - Returns: AES 加密前的 String
    static func decryptAES(_ base64Encoded: String) -> String? {
        if let decodedData = Data(base64Encoded: base64Encoded),
           let aesDecode = decodedData.aes256Decrypt() {
            let decodedString = String(data: aesDecode as Data, encoding: .utf8)
            return decodedString
        } else { return nil }
    }
}
