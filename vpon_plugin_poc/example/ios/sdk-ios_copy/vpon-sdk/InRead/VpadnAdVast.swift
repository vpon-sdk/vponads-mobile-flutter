//
//  VpadnAdVast.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/4/28.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

class VpadnAdVast {
    
    var adInlines: [VpadnAdInline] = []
    var adWrappers: [VpadnAdWrapper] = []
    
    init() {
        
    }
    
    func sendAsynchronousRequest(url: URL) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            
        }.resume()
    }
    
    func sendTracking(by event: String, currentInline: VpadnAdInline) {
        sendTracking(by: event, currentInline: currentInline, marco: nil)
    }
    
    func sendTracking(by event: String, currentInline: VpadnAdInline, marco: [String: Any]?) {
        currentInline.sendTracking(by: event, marco: marco)
        for wrapper in adWrappers {
            wrapper.sendTracking(by: event, marco: marco)
        }
    }
    
    func getTracking(by event: String, currentInline: VpadnAdInline) -> [VpadnTracking] {
        var allTrackings = [VpadnTracking]()
        allTrackings.append(contentsOf: currentInline.allTrackings)
        for wrapper in adWrappers {
            allTrackings.append(contentsOf: wrapper.allTrackings)
        }
        let predicate = NSPredicate(format: "event == %@", event)
        return allTrackings.filter { predicate.evaluate(with: $0) }
    }
    
    func sendTracking(_ tracking: VpadnTracking) {
        guard let url = tracking.url else { return }
        VponConsole.log("tracking event: \(tracking.event ?? ""), request url: \(url.absoluteString)")
        sendAsynchronousRequest(url: url)
    }
}
