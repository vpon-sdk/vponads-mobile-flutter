//
//  VponAdLocationManager.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/10/25.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import CoreLocation

@objcMembers public final class VponAdLocationManager: NSObject {
    
    private let UpdateFreq = 10
    
    typealias LocationSuccess = (_ manager: CLLocationManager, _ locAge: Int) -> Void
    typealias LocationFailure = (_ error: Error) -> Void
    typealias GeocoderSuccess =  (_ mark: CLPlacemark) -> Void
    
    public static let shared = VponAdLocationManager()
    
    /// SDK 是否能使用 Location
    public var isEnable: Bool
    
    /// location manager
    private var locationManager: CLLocationManager
 
    /// 轉換後的地址
    internal var placemark: CLPlacemark?
    
    /// 當前經緯度
    internal var currentLoc: CLLocation
    
    /// 取得經緯度的時間 (timestamp)
    internal var locTimestamp: TimeInterval
    
    /// 距離 locTimestamp 的時間 (s)
    internal var locAge: Int?
    
    /// 成功執行的邏輯
    private var successCallback: LocationSuccess = { _, _ in }
    
    /// 失敗執行的邏輯
    private var failureCallback: LocationFailure = { _ in }
    
    /// 第一次
    private var firstTimer: Timer?
    
    /// Last Message
    private var lastMessage: String = ""
    
    private override init() {
        locationManager = CLLocationManager()
        currentLoc = CLLocation()
        locTimestamp = Date().timeIntervalSince1970
        isEnable = true
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    // MARK: - First Time
    
    internal func startFirstTimer() {
        if locationEnable() {
            startAction()
        } else {
            firstTimer = Timer(timeInterval: 1, target: self, selector: #selector(startAction), userInfo: nil, repeats: true)
            RunLoop.current.add(firstTimer!, forMode: .common)
        }
    }
    
    @objc private func startAction() {
        updateLocation { manager, locAge in
            
        } failure: { error in
            
        }
    }
    
    private func stopFirstTimer() {
        firstTimer?.invalidate()
        firstTimer = nil
    }
    
    private func logPermission(message: String) {
        if lastMessage != message {
            lastMessage = message
            VponConsole.log(lastMessage)
        }
    }
    
    // MARK: - 取得經緯度相關
    
    private func currentLocAge() -> Int {
        let now = Date().timeIntervalSince1970
        let diff = now - locTimestamp
        return Int(diff)
    }
    
    /// 更新當前 Location 數據
    /// - Parameters:
    ///   - success: 成功執行的邏輯
    ///   - failure: 失敗執行的邏輯
    internal func updateLocation(success: @escaping LocationSuccess, failure: @escaping LocationFailure) {
        self.successCallback = success
        self.failureCallback = failure
        if !isEnable {
            failureCallback(ErrorGenerator.limitLocation())
        } else if locationEnable() {
            stopFirstTimer()
            if currentLocAge() > UpdateFreq ||
                locationManager.location == nil {
                locationManager.startUpdatingLocation()
            }
            if locationManager.location != nil {
                updateGeocoder()
                successCallback(locationManager, currentLocAge())
            }
        } else {
            failureCallback(ErrorGenerator.limitLocation())
        }
    }
    
    private func updateGeocoder() {
        if let location = locationManager.location {
            let geoCoder = CLGeocoder()
            let usLocale = Locale(identifier: "en_US")
            geoCoder.reverseGeocodeLocation(location, preferredLocale: usLocale) { [weak self] placemarks, error in
                guard let self else { return }
                if let placemark = placemarks?.first {
                    self.placemark = placemark
                }
            }
        } else {
            placemark = nil
        }
    }
    
    // This method is not being used.
    private func updateGeocoder(success: GeocoderSuccess) {
        if let location = locationManager.location {
            if let placemark {
                success(placemark)
            } else {
                let semaphore = DispatchSemaphore(value: 1)
                let geoCoder = CLGeocoder()
                geoCoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
                    guard let self else { return }
                    if let placemark = placemarks?.first {
                        self.placemark = placemark
                    } else {
                        self.placemark = nil
                    }
                    semaphore.signal()
                }
            }
        } else {
            placemark = nil
        }
    }
    
    private func locationEnable() -> Bool {
        if self.isEnable {
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined:
                logPermission(message: "Location Authorization status not Determined")
                return false
            case .authorizedWhenInUse:
                logPermission(message: "Location permission is allow (WhenInUse)")
                return true
            case .authorizedAlways:
                logPermission(message: "Location permission is allow (Always)")
                return true
            default:
                logPermission(message: "Location permission not allow or device location is disabled")
                return false
            }
        }
        logPermission(message: "Publisher not allow sdk get location")
        return false
    }
}

extension VponAdLocationManager: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()
        if let location = manager.location {
            currentLoc = location
            locTimestamp = location.timestamp.timeIntervalSince1970
        }
        updateGeocoder()
        successCallback(manager, currentLocAge())
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        manager.stopUpdatingLocation()
        if let _ = manager.location {
            updateGeocoder()
            successCallback(locationManager, currentLocAge())
        } else {
            failureCallback(error)
        }
    }
}
