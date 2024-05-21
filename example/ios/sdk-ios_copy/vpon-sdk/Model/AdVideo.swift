////
////  AdVideo.swift
////  vpon-sdk
////
////  Created by Judy Tsai on 2023/11/28.
////  Copyright © 2023 com.vpon. All rights reserved.
////
//
//import Foundation
//
//// 目前 VponAdVideo 這個 class 沒有在使用
//
//enum VponCloseButton {
//    case small
//    case big
//}
//
//enum VponAdMode {
//    case none
//    case onlyVideo
//    case onlyWebView
//    case videoAndWebView
//}
//
//enum VponPosition {
//    case none
//    case top
//    case bottom
//    case right
//    case left
//    case middle
//    case full
//}
//
//enum VponDataType {
//    case video
//    case videoEx
//}
//
//final class AdVideo {
//    /// 自動關閉
//    var auto_close: Bool = false
//    /// 自動重播
//    var auto_replay: Bool = false
//    /// 自動開始
//    var auto_start: Bool = false
//    /// 自動靜音
//    var mute: Bool = false
//    /// 是否關閉 Parent ViewController
//    var close_parent: Bool = false
//    /// 播放完開顯示 CloseButton
//    var ended_close_btn: Bool = false
//    /// CloseButton 顯示的位置 (default: left, option: right)
//    var position: String?
//    /// 使用到 Web 疊層往前的特效
//    var w_in_front: Bool = false
//    /// 橫屏是否全屏
//    var l_v_fullscreen: Bool = false
//    /// 是否顯示倒數轉圈特效 cl
//    var show_progress_wheel: Bool = false
//    /// 是否隱藏控制項
//    var hide_video_btn: Bool = false
//
//    /// 背景色碼
//    var bk_c: String = ""
//    /// 容忍影片 Buffering 的時間(s)
//    var buffering_suffer_time: Int = 0
//    /// 檢查送 Tracking 的頻率(s)
//    var tracking_interval: Float = 0
//
//    /// CloseButton 的大小 (default: small, option: big)
//    var close_btn_size: VponCloseButton = .small
//    /// CloseButton 出現時間(倒數時間)
//    var cd: Int = 0
//    /// CD 文字格式
//    var cd_text: String = ""
//
//    /// 位移至 seekTo 的時間(s)
//    var seek_to: Int = 0
//
//    /// 品牌素材的路徑
//    var brand_icon_u: String = ""
//    /// 品牌素材的文字
//    var brand_text: String = ""
//
//    /// 直屏或橫屏進入影音
//    var force_first_mode: UIDeviceOrientation = .unknown
//    /// 直屏的類別 (ex:vw, v, w,...)
//    var p_t: VponAdMode = .none
//    /// 直屏 Video 的位置 (default: top, option: bottom, middle, full)
//    var p_v_pos: VponPosition = .top
//    /// 直屏 WebView 的位置 (default: top, option: bottom)
//    var p_w_pos: VponPosition = .top
//
//    /// 直屏影音播放完畢, 隱藏 Video
//    var p_ended_hide_v: Bool = false
//
//    /// 橫屏的類別 (ex:vw, v, w,...)
//    var l_t: VponAdMode = .none
//    /// 橫屏 Video 的位置 (default: full)
//    var l_v_pos: VponPosition = .full
//    /// 橫屏 WebView 的位置 (default: right, option: left)
//    var l_w_pos: VponPosition = .right
//    /// 橫屏影音播放完畢, 隱藏 Video
//    var l_ended_hide_v: Bool = false
//
//    var p_w_h_percent: Float = 0
//    var p_logo_w_h_percent: Float = 0
//    var l_w_size_percent: Float = 0
//
//    /// 影片的寬
//    var v_width: Int = 0
//    /// 影片的高
//    var v_height: Int = 0
//    /// 影片的路徑
//    var v_u: URL?
//
//    /// 網頁素材的路徑
//    var w_u: URL?
//    /// LOGO素材的路徑
//    var p_logo_w_u: URL?
//
//    /// 查看更多-Button資料
//    var btns: [String] = []
//    /// 查看更多-是否開啟inApp WebView
//    var launch_type: String = ""
//    /// 查看更多-隱藏 Action Button
//    var hide_action_btn: Bool = false
//
//    /// 重播TrackingUrls
//    var replay_tracking_urls: [String] = []
//    /// 恢復TrackingUrls
//    var resume_tracking_urls: [String] = []
//    /// 暫停TrackingUrls
//    var pause_tracking_urls: [String] = []
//    /// 靜音TrackingUrls
//    var mute_tracking_urls: [String] = []
//    /// 取消靜音TrackingUrls
//    var unmute_tracking_urls: [String] = []
//    /// 關閉TrackingUrls
//    var close_tracking_urls: [String] = []
//    /// 暫停的位置
//    var pause_locations: [String] = []
//    /// 進度Tracking
//    var v_progress: [String: Any] = [:]
//    /// 影音TrackingUrls
//    var v_tracking: [String: Any] = [:]
//    /// 影音TrackingUrls - start
//    var v_tracking_start: [String] = []
//    /// 影音TrackingUrls - firstQuartile
//    var v_tracking_firstQuartile: [String] = []
//    /// 影音TrackingUrls - midpoint
//    var v_tracking_midpoint: [String] = []
//    /// 影音TrackingUrls - thirdQuartile
//    var v_tracking_thirdQuartile: [String] = []
//    /// 影音TrackingUrls - complete
//    var v_tracking_complete: [String] = []
//
//    var tracking_u: String = ""
//
//    var store: VponAdStore?
//
//    private var args: [String: Any] = [:]
//    /// 是否合法使用
//    private var isValid = false
//
//    init(data: [String: Any], type: VponDataType) {
//        switch type {
//        case .video:
//            setupOpenVideo(data: data)
//        case .videoEx:
//            setupOpenVideoEx(data: data)
//        }
//    }
//
//    // 下一個影片 應對以下處理：v_tracking, tracking_u, replay_tracking_urls, auto_close, btns, tracking_interval
//    func next(data: [String: Any]) {
//        self.args = data
//        if let string = data[VVKEY_URL_STRING] as? String,
//           let url = URL(string: string) {
//            v_u = url
//            isValid = FormatVerifier.isURLValid(v_u!)
//        }
//
//        // Tracking
//        v_tracking = args[VVKEY_VIDEO_TRACKING_URLS_LIST] as? [String: Any] ?? [:]
//        v_tracking_start = setArgVTracking(key: "start")
//        v_tracking_firstQuartile = setArgVTracking(key: "firstQuartile")
//        v_tracking_midpoint = setArgVTracking(key: "midpoint")
//        v_tracking_thirdQuartile = setArgVTracking(key: "thirdQuartile")
//        v_tracking_complete = setArgVTracking(key: "complete")
//
//        tracking_u = args[VVKEY_TRACKING_URL] as? String ?? ""
//
//        replay_tracking_urls = args[VVKEY_REPLAY_BTN_TRACKING_URLS_LIST] as? [String] ?? []
//        tracking_interval = args[VVKEY_TRACKING_INTERVAL] as? Float ?? 0
//        btns = args[VVKEY_VIDEO_BUTTONS] as? [String] ?? []
//        auto_close = args[VVKEY_NEED_AUTO_CLOSE] as? Bool ?? false
//        auto_start = true
//    }
//
//    private func setupOpenVideo(data: [String: Any]) {
//        if let string = data[VVKEY_URL_STRING] as? String,
//           let url = URL(string: string) {
//            v_u = url
//            isValid = VponFormatVerifier.isURLValid(v_u!)
//        }
//    }
//
//    private func setupOpenVideoEx(data: [String: Any]) {
//        self.args = data
//
//        if let url = args[VVKEY_VIDEO_URL] as? URL {
//            v_u = url
//            isValid = VponFormatVerifier.isURLValid(v_u!)
//        }
//
//        if let width = args[VVKEY_VIDEO_SIZE_WIDTH] as? Int {
//            v_width = width
//        }
//        if let height = args[VVKEY_VIDEO_SIZE_HEIGHT] as? Int {
//            v_height = height
//        }
//
//        // Tracking
//        v_tracking = args[VVKEY_VIDEO_TRACKING_URLS_LIST] as? [String: Any] ?? [:]
//        v_tracking_start = setArgVTracking(key: "start")
//        v_tracking_firstQuartile = setArgVTracking(key: "firstQuartile")
//        v_tracking_midpoint = setArgVTracking(key: "midpoint")
//        v_tracking_thirdQuartile = setArgVTracking(key: "thirdQuartile")
//        v_tracking_complete = setArgVTracking(key: "complete")
//
//        tracking_u = args[VVKEY_TRACKING_URL] as? String ?? ""
//
//        replay_tracking_urls = args[VVKEY_REPLAY_BTN_TRACKING_URLS_LIST] as? [String] ?? []
//        resume_tracking_urls = args[VVKEY_RESUME_BTN_TRACKING_URLS_LIST] as? [String] ?? []
//        pause_tracking_urls = args[VVKEY_PAUSE_BTN_TRACKING_URLS_LIST] as? [String] ?? []
//        mute_tracking_urls = args[VVKEY_MUTE_BTN_TRACKING_URLS_LIST] as? [String] ?? []
//        unmute_tracking_urls = args[VVKEY_UNMUTE_BTN_TRACKING_URLS_LIST] as? [String] ?? []
//        close_tracking_urls = args[VVKEY_CLOSE_BTN_TRACKING_URLS_LIST] as? [String] ?? []
//        v_progress = setVideoProgress()
//
//        // AD elements
//        w_u = args[VVKEY_WEBVIEW_URL] as? URL
//        if let w_u {
//            VponConsole.log(w_u.absoluteString)
//        }
//        p_logo_w_u = args[VVKEY_LOGO_WEBVIEW_URL] as? URL
//        cd_text = args[VVKEY_COUNTDOWN_TEXT] as? String ?? ""
//        tracking_interval = args[VVKEY_TRACKING_INTERVAL] as? Float ?? 0
//
//        cd = 10 // args[VVKEY_COUNT_DOWN] as? Int
//        show_progress_wheel = args[VVKEY_SHOW_PROGRESS_WHEEL] as? Bool ?? false
//
//        brand_icon_u = args[VVKEY_BRAND_ICON_URL] as? String ?? ""
//        brand_text = args[VVKEY_BRAND_TEXT] as? String ?? ""
//        close_parent = args[VVKEY_CLOSE_PARENT_INTERSTITIAL] as? Bool ?? false
//        pause_locations = args[VVKEY_VIDEO_PRE_PAUSE_LOCATIONS_LIST] as? [String] ?? []
//        mute = args[VVKEY_MUTE_VIDEO] as? Bool ?? false
//        btns = args[VVKEY_VIDEO_BUTTONS] as? [String] ?? []
//
//        p_w_h_percent = args[VVKEY_PORTRAIT_WEBVIEW_HEIGHT_PERCENT] as? Float ?? 0
//        p_logo_w_h_percent = args[VVKEY_PORTRAIT_LOGO_HEIGHT_PERCENT] as? Float ?? 0
//        l_w_size_percent = args[VVKEY_LANDSCAPE_WEBVIEW_SIZE_PERCENT] as? Float ?? 0
//        l_v_fullscreen = args[VVKEY_IS_LANDSCAPE_VIDEO_FULLSCREEN] as? Bool ?? false
//
//        p_ended_hide_v = args[VVKEY_NEED_HIDE_PORTRAIT_FULL_VID_END] as? Bool ?? false
//        l_ended_hide_v = args[VVKEY_NEED_HIDE_LANDSCAPE_VID_END] as? Bool ?? false
//        hide_action_btn = args[VVKEY_NEED_HIDE_BUTTON_ACTION] as? Bool ?? false
//        hide_video_btn = args[VVKEY_NEED_SHOW_HIDE_VIDEO_BTN] as? Bool ?? false
//
//        close_btn_size = setArgVPCloseButton(argKey: VVKEY_CLOSE_BUTTON_SIZE)
//
//        bk_c = args[VVKEY_BACKGROUND_COLOR] as? String ?? ""
//
//        p_w_pos = setArgVPPosition(argKey: VVKEY_PORTRAIT_WEBVIEW_POS, defaultPosition: .top)
//        p_v_pos = setArgVPPosition(argKey: VVKEY_PORTRAIT_VIDEO_POS, defaultPosition: .top)
//        l_w_pos = setArgVPPosition(argKey: VVKEY_LANDSCAPE_WEBVIEW_POS, defaultPosition: .full)
//        l_v_pos = setArgVPPosition(argKey: VVKEY_LANDSCAPE_VIDEO_POS, defaultPosition: .full)
//
//        p_t = setArgVPAdMode(argKey: VVKEY_PORTRAIT_TYPE, defaultMode: .none)
//        l_t = setArgVPAdMode(argKey: VVKEY_LANDSCAPE_TYPE, defaultMode: .none)
//        if v_width != 0 && v_height != 0 &&
//            v_width <= v_height {
//            l_t = .none
//        }
//
//        force_first_mode = setArgLaunchOrientation(argKey: VVKEY_LAUNCH_ORIENTATION)
//
//        auto_close = args[VVKEY_NEED_AUTO_CLOSE] as? Bool ?? false
//        ended_close_btn = args[VVKEY_SHOW_CLOSE_WHEN_ENDED] as? Bool ?? false
//
//        w_in_front = setArgWebViewInFront()
//
//        if (!l_ended_hide_v && !p_ended_hide_v) {
//            auto_replay = args[VVKEY_AUTO_REPLAY] as? Bool ?? false
//        }
//
//        auto_start = args[VVKEY_AUTO_START] as? Bool ?? true
//
//        if args[VVKEY_STORE_ID] is String {
//            store = VponAdStore(data: args)
//        }
//
//        store = VponAdStore(data: args)
//        if let store, store.canOpen() {
//            // only support video on top when use in app store, and ipad only Full screen
//            if DeviceInfo.isPhone() {
//                p_v_pos = .top
//                p_w_pos = .none
//            } else {
//                p_v_pos = .full
//                p_w_pos = .none
//            }
//            // if use app store then don't support landscape mode
//            l_t = .none
//        }
//    }
//
//    func canPlay() -> Bool {
//        return isValid
//    }
//
//    // MARK: - Helper
//
//    private func setVideoProgress() -> [String: Any] {
//        var vprogress = [String: Any]()
//        if let progressList = args[VVKEY_VIDEO_PROGRESS_TRACKING_LIST] as? [[String: Any]] {
//            for progress in progressList {
//                if let key = progress[VVKEY_SEC_STRING] as? String,
//                   let urls = progress[VVKEY_URLS_STRING] as? [String] {
//                    if !key.isEmpty && !urls.isEmpty {
//                        vprogress[key] = urls
//                    }
//                }
//            }
//        }
//        return vprogress
//    }
//
//    private func setArgVPCloseButton(argKey: String) -> VponCloseButton {
//        if let value = args[argKey] as? String,
//           value == "big" {
//            return .big
//        }
//
//        return .small
//    }
//
//    private func setArgVPPosition(argKey: String, defaultPosition: VponPosition) -> VponPosition {
//        if let value = args[argKey] as? String {
//            switch value {
//            case "bottom":
//                return .bottom
//            case "right":
//                return .right
//            case "left":
//                return .left
//            case "middle":
//                return .middle
//            default:
//                return .full
//            }
//        }
//        return defaultPosition
//    }
//
//    private func setArgVPAdMode(argKey: String, defaultMode: VponAdMode) -> VponAdMode {
//        if let value = args[argKey] as? String {
//            if value == "v" {
//                return .onlyVideo
//            } else if value == "w" {
//                return .onlyWebView
//            } else if value == "vw" {
//                return .videoAndWebView
//            }
//        }
//        return defaultMode
//    }
//
//    private func setArgLaunchOrientation(argKey: String) -> UIDeviceOrientation {
//        if let value = args[argKey] as? String {
//            if value == "l" {
//                return .landscapeLeft
//            } else if value == "p" {
//                return .portrait
//            }
//        }
//        return .unknown
//    }
//
//    private func setArgWebViewInFront() -> Bool {
//        if let result = args[VVKEY_WEBVIEW_IN_FRONT] as? Bool {
//            if result {
//                if p_v_pos == .full && !p_ended_hide_v {
//                    return result
//                }
//
//                if l_t == .videoAndWebView && p_t == .none && l_ended_hide_v {
//                    return result
//                }
//            }
//        }
//        return false
//    }
//
//    private func setArgVTracking(key: String) -> [String] {
//        var temp = [String]()
//        if let value = v_tracking[key] as? [String] {
//            temp = value
//        }
//        return temp
//    }
//}
//
//// MARK: - Constants
//
//let VVDEFAULT_CLOSE_CONSTRANT = 50
//let VVKEY_SEC_STRING = "sec"
//let VVKEY_URL_STRING = "u"
//let VVKEY_URLS_STRING = "urls"
//let VVKEY_HTML_STRING = "html"
//let VVKEY_USE_CUSTOM_CLOSE = "custom_close"
//let VVKEY_ALLOW_ORIENTATION_CHANGE = "allow_orientation_change"
//let VVKEY_FORCE_ORIENTATION = "force_orientation"
//let VVKEY_BACKGROUND_COLOR = "bk_c"
//let VVKEY_SHOW_PROGRESS_BAR = "show_prog_bar"
//let VVKEY_SHOW_NAVIGATION_BAR = "show_nav_bar"
//let VVKEY_USE_WEBVIEW_LOAD = "use_webview_load_url"
//let VVKEY_PHONE_NUMBER = "tel"
//let VVKEY_SMS_MSG_BODY = "b"
//let VVKEY_TIMEOUT = "timeout"
//let VVKEY_EVENT_TYPE = "et"
//let VVKEY_EVENT_ID = "eid"
//let VVKEY_MRAID2_BANNER = "mraid2_banner"
//let VVKEY_MRAID2_EXPANDED = "mraid2_expanded"
//let VVKEY_MRAID2_INTERSITIAL = "mraid2_interstitial"
//let VVKEY_VIEWABLE_RATE = "viewable_rate"
//let VVKEY_VIEWABLE_DURATION = "viewable_duration"
//let VVKEY_VIEWABLE_DETECTION_RESTART = "viewable_detection_restart"
//let VVKEY_CALENDAR_EVENT = "e"
//let VVKEY_DOWNLOAD_APP_ID = "id"
//let VVKEY_SAVE_TEMP_DATA_KEY = "k"
//let VVKEY_SAVE_TEMP_DATA_VALUE = "d"
//let VVKEY_RESIZE_ALLOW_OFF_SCR = "allow_off_scr"
//let VVKEY_RESIZE_CUSTOM_CLOSE_POS = "cust_close_pos"
//let VVKEY_RESIZE_WIDTH = "w"
//let VVKEY_RESIZE_HEIGHT = "h"
//let VVKEY_RESIZE_OFF_X = "off_x"
//let VVKEY_RESIZE_OFF_Y = "off_y"
//
//// Video param
//let VVKEY_PORTRAIT_TYPE = "p_t"
//let VVKEY_LANDSCAPE_TYPE = "l_t"
//let VVKEY_VIDEO_URL = "v_u"
//let VVKEY_WEBVIEW_URL = "w_u"
//let VVKEY_LOGO_WEBVIEW_URL = "p_logo_w_u"
//let VVKEY_IS_LANDSCAPE_VIDEO_FULLSCREEN = "l_v_fullscreen"
//let VVKEY_PORTRAIT_VIDEO_POS = "p_v_pos"
//let VVKEY_PORTRAIT_WEBVIEW_POS = "p_w_pos"
//let VVKEY_LANDSCAPE_VIDEO_POS = "l_v_pos"
//let VVKEY_LANDSCAPE_WEBVIEW_POS = "l_w_pos"
//let VVKEY_VIDEO_POC = "pos"
//let VVKEY_COUNT_DOWN = "cd"
//let VVKEY_BUFFERING_SUFFER_TIME = "buffering_suffer_time"
//let VVKEY_SHOW_PROGRESS_WHEEL = "show_progress_wheel"
//let VVKEY_TRACKING_URL = "tracking_u"
//let VVKEY_TRACKING_INTERVAL = "tracking_interval"
//let VVKEY_VIDEO_BUTTONS = "btns"
//let VVKEY_BOTTON_ACTION = "action"
//let VVKEY_BUTTON_WEBVIEW_LAUNCH_TYPE = "launch_type"
//let VVKEY_BUTTON_DATA = "data"
//let VVKEY_SLAVE_URL = "slave_u"
//let VVKEY_COUNTDOWN_TEXT = "cd_text"
//let VVKEY_LAUNCH_ORIENTATION = "force_first_mode"
//let VVKEY_PORTRAIT_WEBVIEW_HEIGHT_PERCENT = "p_w_h_percent"
//let VVKEY_PORTRAIT_LOGO_HEIGHT_PERCENT = "p_logo_w_h_percent"
//let VVKEY_LANDSCAPE_WEBVIEW_SIZE_PERCENT = "l_w_size_percent"
//let VVKEY_SHOW_CLOSE_WHEN_ENDED = "ended_close_btn"
//let VVKEY_NEED_AUTO_CLOSE = "auto_close"
//let VVKEY_SHOW_TEST_LOG = "show_log"
//let VVKEY_BRAND_ICON_URL = "brand_icon_u"
//let VVKEY_BRAND_TEXT = "brand_text"
//let VVKEY_CLOSE_PARENT_INTERSTITIAL = "close_parent"
//let VVKEY_MUTE_VIDEO = "mute"
//let VVKEY_SEEK_TIME_TO = "seek_to"
//let VVKEY_CHANGE_VIDEO_ORIENGATION = "orientation"
//let VVKEY_LOC_ACCURACY = "loc_accuracy"
//let VVKEY_LOC_CACHETIME = "loc_cachetime"
//let VVKEY_CLOSE_BUTTON_POSITION = "position"
//let VVKEY_VIDEO_TRACKING_URLS_LIST = "v_tracking"
//let VVKEY_USE_AUTO_ROTATE = "use_auto_rotate"
//
//// vid3
//let VVKEY_NEED_HIDE_PORTRAIT_FULL_VID_END = "p_ended_hide_v"
//let VVKEY_NEED_HIDE_LANDSCAPE_VID_END = "l_ended_hide_v"
//let VVKEY_NEED_HIDE_BUTTON_ACTION = "hide_action_btn"
//let VVKEY_CLOSE_BUTTON_SIZE = "close_btn_size"
//let VVKEY_NEED_SHOW_HIDE_VIDEO_BTN = "hide_video_btn"
//let VVKEY_VIDEO_PROGRESS_TRACKING_LIST = "v_progress"
//let VVKEY_REPLAY_BTN_TRACKING_URLS_LIST = "replay_tracking_urls"
//
//let VVKEY_RESUME_BTN_TRACKING_URLS_LIST = "resume_tracking_urls"
//let VVKEY_PAUSE_BTN_TRACKING_URLS_LIST = "pause_tracking_urls"
//let VVKEY_MUTE_BTN_TRACKING_URLS_LIST = "mute_tracking_urls"
//let VVKEY_UNMUTE_BTN_TRACKING_URLS_LIST = "unmute_tracking_urls"
//let VVKEY_CLOSE_BTN_TRACKING_URLS_LIST = "close_tracking_urls"
//
//// vid4
//let VVKEY_WEBVIEW_IN_FRONT = "w_in_front"
//let VVKEY_AUTO_REPLAY = "auto_replay"
//let VVKEY_AUTO_START = "auto_start"
//
//let VVKEY_VIDEO_PRE_PAUSE_LOCATIONS_LIST = "pause_locations"
//let VVKEY_VIDEO_SIZE = "v_s"
//
//// vid5
//let VVKEY_VIDEO_SIZE_WIDTH = "v_width"
//let VVKEY_VIDEO_SIZE_HEIGHT = "v_height"
//let VVKEY_STORE_ID = "store_id"
