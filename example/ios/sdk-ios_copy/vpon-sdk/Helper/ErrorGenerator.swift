//
//  ErrorGenerator.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/2/7.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

struct ErrorGenerator {
    
    static func defaultError() -> NSError {
        let userInfo = [
            NSLocalizedDescriptionKey: NSLocalizedString("Contact to Vpon FAE", comment: ""),
            NSLocalizedFailureReasonErrorKey: NSLocalizedString("Contact to Vpon FAE", comment: ""),
            NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Contact to Vpon FAE", comment: "")
        ]
        return NSError(domain: Constants.Domain.error, code: -999, userInfo: userInfo)
    }
    
    static func requestFailed(code: Int, status: String, description: String) -> NSError {
        let userInfo = [
            NSLocalizedDescriptionKey: status,
            NSLocalizedFailureReasonErrorKey: description
        ]
        return NSError(domain: Constants.Domain.error, code: code, userInfo: userInfo)
    }
    
    static func noAds() -> NSError {
        let userInfo = [
            NSLocalizedDescriptionKey: "No ads",
            NSLocalizedFailureReasonErrorKey: "No ads"
        ]
        return NSError(domain: Constants.Domain.error, code: -999, userInfo: userInfo)
    }
    
    static func mediaView(description: String) -> NSError {
        ErrorGenerator.makeError(localizedDescription: "MediaView load failed.", errorDescription: description)
    }
    
    static func limitLocation() -> NSError {
        ErrorGenerator.makeError(localizedDescription: "User limit location.", errorDescription: nil)
    }
    
    static func sendTracking(error: Error) -> NSError {
        ErrorGenerator.makeError(localizedDescription: "Tracking failed.", errorDescription: error.localizedDescription)
    }
    
    static func calendarUsage() -> NSError {
        ErrorGenerator.makeError(localizedDescription: "NSCalendarsUsageDescription not found.", errorDescription: nil)
    }
    
    static func addCalendarFailed(errorDescription: String? = nil) -> NSError {
        ErrorGenerator.makeError(localizedDescription: "Add calendar failed.", errorDescription: errorDescription)
    }
    
    static func photoAuthorization() -> NSError {
        ErrorGenerator.makeError(localizedDescription: "Authorization not allowed.", errorDescription: nil)
    }
    
    static func photoUsage() -> NSError {
        ErrorGenerator.makeError(localizedDescription: "NSPhotoLibraryUsageDescription not found.", errorDescription: nil)
    }
    
    static func photoURLFailed() -> NSError {
        ErrorGenerator.makeError(localizedDescription: "The url of photo is invaild.", errorDescription: nil)
    }
    
    static func photoStoreFailed() -> NSError {
        ErrorGenerator.makeError(localizedDescription: "Photo store failed.", errorDescription: nil)
    }
    
    static func initSDKFailed() -> NSError {
        ErrorGenerator.makeError(localizedDescription: "Please init sdk.", errorDescription: nil)
    }
    
    // MARK: - Helper func
    
    private static func makeError(localizedDescription: String, errorDescription: String?, code: Int = -999) -> NSError {
        var userInfo = [String: String]()
        if let errorDescription {
            userInfo = [
                NSLocalizedDescriptionKey: "\(localizedDescription) Reason: \(errorDescription)"
            ]
        } else {
            userInfo = [
                NSLocalizedDescriptionKey: localizedDescription
            ]
        }
        return NSError(domain: Constants.Domain.error, code: code, userInfo: userInfo)
    }
}
