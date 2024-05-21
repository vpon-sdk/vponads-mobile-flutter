//
//  UIView+VpadnAd.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/3/13.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import UIKit

extension String {
    
    func replace(tag: String, with string: String) -> String? {
        if self.contains(tag) {
            return self.replacingOccurrences(of: tag, with: string)
        } else { return nil }
    }
}

extension UIButton {
    
    /// 產生文字 Button
    /// - Parameters:
    ///   - title: 文案
    ///   - target: selector 所在的對象
    ///   - selector: 執行的邏輯
    /// - Returns: UIButton
    class func vp_btn(title: String, target: Any?, selector: Selector) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(.red, for: .normal)
        btn.addTarget(target, action: selector, for: .touchUpInside)
        return btn
    }
    
    /// 產生圖片 Button
    /// - Parameters:
    ///   - image: 圖片
    ///   - target: selector 所在的對象
    ///   - selector: 執行的邏輯
    /// - Returns: UIButton
    class func vp_btn(image: UIImage, target: Any?, selector: Selector) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setBackgroundImage(image, for: .normal)
        btn.setBackgroundImage(image, for: .selected)
        btn.addTarget(target, action: selector, for: .touchUpInside)
        return btn
    }
}

extension UIWindow {
    
    class func keyWindow() -> UIWindow? {
        var foundWindow: UIWindow?
        for window in UIApplication.shared.windows {
            if window.isKeyWindow {
                foundWindow = window
                break
            }
        }
        return foundWindow
    }
}

extension UIApplication {
    
    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}

extension Dictionary {
    
    mutating func append(_ other: Dictionary) {
        for (key,value) in other {
            self.updateValue(value, forKey:key)
        }
    }
}

extension UIView {
    
    func superviews() -> [UIView]? {
        var superviews = [UIView]()
        guard let superview = self.superview else { return nil }
        if superview.isKind(of: UIScrollView.self) ||
            superview.isKind(of: UITableView.self) ||
            superview.isKind(of: UICollectionView.self) {
            superviews.append(superview)
        }
        
        if let views = superview.superviews() {
            superviews.append(contentsOf: views)
        }
        return superviews
    }
}

extension URL {
    
    static func queryParameters(from url: URL) -> [String: String] {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = urlComponents.queryItems else {
            return [:]
        }
        var queryParams = [String: String]()
        for queryItem in queryItems {
            if queryItem.value == nil { continue }
            queryParams[queryItem.name] = queryItem.value
        }
        return queryParams
    }
}

extension UIAlertController {
    
    class func show(_ message: String, rootVC vc: UIViewController) {
        let alert = UIAlertController(title: "Notice", message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "確定", style: .default)
        alert.addAction(ok)
        vc.present(alert, animated: true)
    }
}
