//
//  OMManager.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/10/18.
//  Copyright © 2023 com.vpon. All rights reserved.
//

extension OMManager: VideoStateObserver {
    func receive(_ event: VideoState, data: [String : Any]?) {
        switch event {
        case .onVideoResume:
            fireMediaEventsResume()
            
        case .onVideoPause:
            fireMediaEventsPause()
            
        case .onVideoBufferStart:
            fireMediaEventsBufferStart()
            
        case .onVideoBufferFinish:
            fireMediaEventsBufferFinish()
            
        case .onVideoStart:
            guard let duration = data?["duration"] as? CGFloat,
                  let volume = data?["volume"] as? CGFloat else { return }
            fireMediaEventsStart(duration: duration, volume: volume)
            
        case .onVideoFirstQuartile:
            fireMediaEventsFirstQuartile()
            
        case .onVideoMidPoint:
            fireMediaEventsMidpoint()
            
        case .onVideoThirdQuartile:
            fireMediaEventsThirdQuartile()
            
        case .onVideoComplete:
            fireMediaEventsComplete()
      
        case .onVideoVolumeChange:
            guard let volume = data?["volume"] as? CGFloat else { return }
            fireMediaEventsChangeVolume(to: volume)
            
        case .onChangeToFullScreen:
            fireMediaEventsPlayerStateChange(to: .fullscreen)
            
        case .onChangeToNormal:
            fireMediaEventsPlayerStateChange(to: .normal)
        }
    }
}

extension OMManager: AdLifeCycleObserver {
    func receive(_ event: AdLifeCycle, data: [String : Any]?) {
        switch event {
        case .onAdLoaded:
            setupAdSession()
            setupAdEvents()
            
            if creativeType == .video {
                // t = "nv"
                setupMediaAdEventsForNativeVIdeo()
            }
            
            startSession()
 
        case .onAdImpression:
            fireImpression()
            
        case .onAdClicked:
            fireMediaEventsClick()
            
        case .onAdDestroyed:
            finishSession()
            
        default:
            return
        }
    }
}

final class OMManager {
    
    // For fetching service.js
    static private var documentPath: String {
        return NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0].appending("/vpadn/om")
    }
    static private var filePath: String {
        return documentPath.appending("/service.js")
    }
    
    var adLifeCycleManager: AdLifeCycleManager?
    var videoStateManager: VideoStateManager?
    private weak var adView: UIView?
    
    private var didSetupSession = false
    private var verifications: [Verification]?
    private var friendlyObstructions: [VponAdObstruction] = []

    private var creativeType: OMIDCreativeType
    private var impressionType: OMIDImpressionType
    private var impressionOwner: OMIDOwner
    private var mediaEventOwner: OMIDOwner
    
    private var partner: OMIDVponPartner = {
        return OMIDVponPartner(name: Constants.OM.partnerName, versionString: SDK_VERSION)!
    }()
    
    private var adSession: OMIDVponAdSession?
    private var adEvents: OMIDVponAdEvents?
    private var mediaEvents: OMIDVponMediaEvents?

    // MARK: - Init
    
    init(adLifeCycleManager: AdLifeCycleManager, info: OMInfo, adView: UIView) {
        self.adLifeCycleManager = adLifeCycleManager
        self.creativeType = info.creativeType
        self.impressionType = info.impressionType
        self.impressionOwner = info.impressionOwner
        self.mediaEventOwner = info.mediaEventOwner
        self.verifications = info.verifications
        self.adView = adView
        
        adLifeCycleManager.register(self, .onAdLoaded)
        adLifeCycleManager.register(self, .onAdImpression)
        adLifeCycleManager.register(self, .onAdClicked)
        adLifeCycleManager.register(self, .onAdDestroyed)
    }
    
    /// For video format
    convenience init(adLifeCycleManager: AdLifeCycleManager, info: OMInfo, adView: UIView, videoStateManager: VideoStateManager?) {
        self.init(adLifeCycleManager: adLifeCycleManager, info: info, adView: adView)
        
        self.videoStateManager = videoStateManager
        for event in VideoState.allCases {
            videoStateManager?.register(self, event)
        }
    }
    
    func setFriendlyObstructions(_ obstructions: [VponAdObstruction]) {
        self.friendlyObstructions = obstructions
    }
    
    // MARK: - Setup
    
    private func setupAdSession() {
        guard OMIDVponSDK.shared.activate(), let adView else {
            VponConsole.log("[OMSDK] OMSDK is not activate!")
            return
        }
        
        guard let context = createAdSessionContext(partner: partner, adView: adView),
              let config = createAdSessionConfiguration() else { return }
        adSession = createAdSession(partner: partner, context: context, config: config)
    }
    
    /// Create event publisher before starting the session
    private func setupAdEvents() {
        guard let adSession else { return }
        do {
            adEvents = try OMIDVponAdEvents(adSession: adSession)
        } catch {
            VponConsole.log("[OMSDK] Unable to create ad event, reason \(error.localizedDescription)")
        }
    }
    
    /// Only needed for native video
    private func setupMediaAdEventsForNativeVIdeo() {
        guard let adSession else { return }
        do {
            mediaEvents = try OMIDVponMediaEvents(adSession: adSession)
        } catch {
            VponConsole.log("[OMSDK] Unable to instantiate video ad events, reason \(error.localizedDescription)")
        }
    }
    
    // MARK: - Session control
    
    private func startSession() {
        guard let adSession else { return }
        if didSetupSession {
            VponConsole.log("[OMSDK] Session start", .info)
            adSession.start()
            if creativeType == .definedByJavaScript { return }
            if creativeType == .video {
                let vastProperties = OMIDVponVASTProperties(autoPlay: true, position: .standalone)
                fireAdLoaded(with: vastProperties)
            } else {
                fireAdLoaded()
            }
        }
    }
    
    private func finishSession() {
        guard let adSession else { return }
        if didSetupSession {
            var webView = adView as? WKWebView
            adSession.finish()
            didSetupSession = false
            
            // 需要 keep webView reference 至少 1 秒再釋放，才能確保 sessionFinish event 被送出
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                webView = nil
            }
            VponConsole.log("[OMSDK] Session finish")
        }
    }
    
    // MARK: - Fire events
    
    /// For HTML display and Native display
    private func fireAdLoaded() {
        do {
            try adEvents?.loaded()
            VponConsole.log("[OMSDK] Fire ad loaded")
        } catch {
            VponConsole.log("[OMSDK] Unable to fire loaded event, reason: \(error.localizedDescription)")
        }
    }
    
    private func fireAdLoaded(with vastProperties: OMIDVponVASTProperties) {
        do {
            try adEvents?.loaded(with: vastProperties)
        } catch {
            VponConsole.log("[OMSDK] Unable to fire loaded event with vastProperties, reason: \(error.localizedDescription)")
        }
    }
    
    /// For HTML display and Native display
    private func fireImpression() {
        guard let adEvents, impressionOwner == .nativeOwner else { return }
        do {
            try adEvents.impressionOccurred()
            VponConsole.log("[OMSDK] Send impression succeeded")
        } catch {
            VponConsole.log("[OMSDK] Send impression failed, reason \(error.localizedDescription)")
        }
    }
    
    private func fireMediaEventsClick() {
        if let mediaEvents {
            VponConsole.log("[OMSDK] mediaEvents.adUserInteraction(withType: .click)")
            mediaEvents.adUserInteraction(withType: .click)
        }
    }
    
    private func fireMediaEventsStart(duration: CGFloat, volume: CGFloat) {
        if let mediaEvents {
            VponConsole.log("[OMSDK] mediaEvents.start")
            mediaEvents.start(withDuration: duration, mediaPlayerVolume: volume)
        }
    }
    
    private func fireMediaEventsFirstQuartile() {
        if let mediaEvents {
            VponConsole.log("[OMSDK] mediaEvents.firstQuartile")
            mediaEvents.firstQuartile()
        }
    }
    
    private func fireMediaEventsMidpoint() {
        if let mediaEvents {
            VponConsole.log("[OMSDK] mediaEvents.midpoint")
            mediaEvents.midpoint()
        }
    }
    
    private func fireMediaEventsThirdQuartile() {
        if let mediaEvents {
            VponConsole.log("[OMSDK] mediaEvents.thirdQuartile")
            mediaEvents.thirdQuartile()
        }
    }
    
    private func fireMediaEventsResume() {
        if let mediaEvents {
            VponConsole.log("[OMSDK] mediaEvents.resume")
            mediaEvents.resume()
        }
    }
    
    private func fireMediaEventsPause() {
        if let mediaEvents {
            VponConsole.log("[OMSDK] mediaEvents.pause")
            mediaEvents.pause()
        }
    }
    
    private func fireMediaEventsBufferStart() {
        if let mediaEvents {
            VponConsole.log("[OMSDK] mediaEvents.bufferStart")
            mediaEvents.bufferStart()
        }
    }
    
    private func fireMediaEventsBufferFinish() {
        if let mediaEvents {
            VponConsole.log("[OMSDK] mediaEvents.bufferFinish")
            mediaEvents.bufferFinish()
        }
    }
    
    private func fireMediaEventsChangeVolume(to volume: CGFloat) {
        if let mediaEvents {
            VponConsole.log("[OMSDK] mediaEvents.volumeChange")
            mediaEvents.volumeChange(to: volume)
        }
    }
    
    private func fireMediaEventsComplete() {
        if let mediaEvents {
            VponConsole.log("[OMSDK] mediaEvents.complete")
            mediaEvents.complete()
        }
    }
    
    private func fireMediaEventsPlayerStateChange(to state: OMIDPlayerState) {
        if let mediaEvents {
            VponConsole.log("[OMSDK] mediaEvents.playerStateChange")
            mediaEvents.playerStateChange(to: state)
        }
    }
    
    // MARK: - Create
    
    private func createPartner() -> OMIDVponPartner? {
        return OMIDVponPartner(name: Constants.OM.partnerName, versionString: SDK_VERSION)
    }
    
    private func createAdSession(partner: OMIDVponPartner, context: OMIDVponAdSessionContext, config: OMIDVponAdSessionConfiguration) -> OMIDVponAdSession? {
        do {
            let adSession = try OMIDVponAdSession(configuration: config, adSessionContext: context)
            adSession.mainAdView = adView
            
            for obstruction in friendlyObstructions {
                if let view = obstruction.view {
                    DispatchQueue.main.async {
                        do {
                            if !obstruction.desc.isEmpty {
                                try adSession.addFriendlyObstruction(view, purpose: obstruction.getOMIDPurpose(), detailedReason: obstruction.desc)
                            } else {
                                try adSession.addFriendlyObstruction(view, purpose: obstruction.getOMIDPurpose(), detailedReason: nil)
                            }
                        } catch {
                            VponConsole.log("[OMSDK] Unable to add friendly obstruction, reason \(error.localizedDescription)")
                        }
                    }
                }
            }
            didSetupSession = true
            return adSession
        } catch {
            VponConsole.log("[OMSDK] Unable to instance session, reason \(error.localizedDescription)")
            return nil
        }
    }
    
    private func createAdSessionContext(partner: OMIDVponPartner, adView: UIView) -> OMIDVponAdSessionContext? {
        
        do {
            switch creativeType {
            case .htmlDisplay, .definedByJavaScript:
                guard let webView = adView as? WKWebView else { return nil }
                return try OMIDVponAdSessionContext(partner: partner,
                                                    webView: webView,
                                                    contentUrl: nil,
                                                    customReferenceIdentifier: nil)
                
            case .nativeDisplay, .video:
                guard let verifications else { return nil }
                
                var resources = [OMIDVponVerificationScriptResource]()
                for verification in verifications {
                    
                    let urls = verification.verificationResources
                    let vendorKey = verification.vendorKey
                    let params = verification.verificationParams
                    
                    for urlString in urls {
                        if let url = URL(string: urlString),
                           let resource = OMIDVponVerificationScriptResource(url: url, vendorKey: vendorKey, parameters: params) {
                            resources.append(resource)
                        }
                    }
                }
                
                OMManager.fetchJSService()
                let script = getServiceFromDirectory()

                guard !resources.isEmpty else {
                    VponConsole.log("[OMSDK] Unable to instantiate session context: verification resource cannot be empty")
                    return nil
                }
                
                return try OMIDVponAdSessionContext(partner: partner,
                                                    script: script,
                                                    resources: resources,
                                                    contentUrl: nil,
                                                    customReferenceIdentifier: nil)
                
            default:
                return nil
            }
        } catch {
            VponConsole.log("[OMSDK] Unable to create ad session context: \(error)")
            return nil
        }
    }
 
    private func createAdSessionConfiguration() -> OMIDVponAdSessionConfiguration? {
        let isolateVerificationScripts = creativeType == .video ? false : true
        do {
            let config = try OMIDVponAdSessionConfiguration(creativeType: creativeType,
                                                            impressionType: impressionType,
                                                            impressionOwner: impressionOwner,
                                                            mediaEventsOwner: mediaEventOwner,
                                                            isolateVerificationScripts: isolateVerificationScripts)
            return config
        } catch {
            VponConsole.log("[OMSDK] Unable to instance session configuration, reason \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - OMID JS service Library
    
    /// Fetch the OMID JS service library (service.js) and save the response
    static func fetchJSService() {
        let keys = UserDefaults.standard.dictionaryRepresentation().keys
        if keys.contains(Constants.UserDefaults.omService) {
            UserDefaults.standard.removeObject(forKey: Constants.UserDefaults.omService)
        }
        if !keys.contains(Constants.UserDefaults.omServiceTime) {
            updateService()
            return
        }
        let last = UserDefaults.standard.integer(forKey: Constants.UserDefaults.omServiceTime)
        let now = Int(Date().timeIntervalSince1970)
        if now - last > Constants.OM.serviceUpdateInterval {
            updateService()
        }
    }
    
    static private func updateService() {
        guard let url = URL(string: Constants.OM.jsService) else { return }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if error != nil {
                VponConsole.log("[OMSDK] Unable to get service.js!")
            }
            if let data, let service = String(data: data, encoding: .utf8) {
                OMManager.saveServiceToDirectory(service)
            }
        }.resume()
    }
    
    static private func saveServiceToDirectory(_ content: String) {
        if !FileManager.default.fileExists(atPath: documentPath) {
            do {
                try FileManager.default.createDirectory(atPath: documentPath, withIntermediateDirectories: true)
            } catch {
                VponConsole.log("[OMSDK] Unable to create directory at: \(documentPath). Error: \(error.localizedDescription)")
            }
        }
        if !filePath.isEmpty {
            let url = URL(fileURLWithPath: filePath)
            do {
                try content.write(to: url, atomically: true, encoding: .utf8)
                let now = Date().timeIntervalSince1970
                UserDefaults.standard.set(now, forKey: Constants.UserDefaults.omServiceTime)
            } catch {
                VponConsole.log("[OMSDK] Unable to save service.js to url: \(url). Error: \(error.localizedDescription)")
            }
        }
    }
    
    private func getServiceFromDirectory() -> String {
        if !FileManager.default.fileExists(atPath: OMManager.filePath) {
            let bundle = Bundle(for: type(of: self))
            guard let filePath = bundle.path(forResource: "omsdk-vpon-latest", ofType: "js") else {
                VponConsole.log("[OMSDK] Unable to get service.js!(SDK)", .error)
                return ""
            }
            do {
                let resource = try String(contentsOfFile: filePath, encoding: .utf8)
                return resource
            } catch {
                VponConsole.log("[OMSDK] Unable to get service.js!(SDK)", .error)
                return ""
            }
        } else {
            do {
                let resource = try String(contentsOfFile: OMManager.filePath, encoding: .utf8)
                return resource
            } catch {
                VponConsole.log("[OMSDK] Unable to get service.js from filePath: \(OMManager.filePath). Error: \(error.localizedDescription)")
                return ""
            }
        }
    }
    
    func unregisterAllEvents() {
        adLifeCycleManager?.unregisterAllEvents(self)
        videoStateManager?.unregisterAllEvents(self)
    }
    
    // MARK: - Deinit
    
    deinit {
        finishSession()
        VponConsole.log("[ARC] OMManager deinit")
    }
}
