//
//  VPTimeIntervalFormatter.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/4/28.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

class VpadnTimeIntervalFormatter {
    
    func timeInterval(with string: String) -> TimeInterval {
        let scanner = Scanner(string: string)
        
        var hours: Int = 0
        var minutes: Int = 0
        var seconds: Int = 0
        var milliseconds: Int = 0
        
        guard scanner.scanInt(&hours),
              scanner.scanCharacters(from: CharacterSet(charactersIn: ":"), into: nil),
              scanner.scanInt(&minutes),
              scanner.scanCharacters(from: CharacterSet(charactersIn: ":"), into: nil),
              scanner.scanInt(&seconds) else {
            return TimeInterval.nan
        }
        
        if scanner.scanCharacters(from: CharacterSet(charactersIn: "."), into: nil) {
            scanner.scanInt(&milliseconds)
        }
        
        return TimeInterval(hours * 60 * 60 + minutes * 60 + seconds) + TimeInterval(milliseconds) / 1000.0
    }
    
    func stringWithTimeInterval(_ totalSeconds: TimeInterval) -> String {
        let hours = Int(totalSeconds / (60 * 60))
        let minutes = Int((totalSeconds - TimeInterval(hours * 60 * 60)) / 60)
        let seconds = max(0, totalSeconds - TimeInterval(hours * 60 * 60) - TimeInterval(minutes * 60))
        return String(format: "%02d:%02d:%06.3f", hours, minutes, seconds)
    }
}
