//
//  NSLayoutConstraints+VpadnAd.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/4/14.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import UIKit

extension NSLayoutConstraint {
    
    /// 移除 view 相關的所有 Constraints(包含上層有關 view 的 Constraint)
    static func vpc_removeAllConstraints(from view: UIView) {
        // 完全移除所有 constraints 會導致 mediation bannerView frame 大小變成 0
        // 因此採用以下方式
        for c in view.constraints {
            if c.firstItem === view && c.secondItem === view { // 不會移除到 width, height
                view.removeConstraint(c)
            }
        }
    }
    
    /// 設定 view1 AspectFit 貼齊 view2
    /// - Parameters:
    ///   - view1: 視圖 1
    ///   - view2: 視圖 2
    ///   - materialSize: 希望廣告回傳的大小
    static func vpc_aspectFit(with view1: UIView, to view2: UIView, materialSize: CGSize) {
        NSLayoutConstraint.vpc_removeAllConstraints(from: view1)
        NSLayoutConstraint.vpc_removeAllConstraints(from: view2)
        let ratio = self.vpc_ratio(with: view1, multiplier: materialSize.width / materialSize.height)
        view1.addConstraint(ratio)

        let midX = self.vpc_equal(with: view1, to: view2, attribute: .centerX)
        let midY = self.vpc_equal(with: view1, to: view2, attribute: .centerY)
        view2.addConstraints([midX, midY])

        if materialSize.width == 0 || materialSize.height == 0 {
            view2.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[view1]-0-|", metrics: nil, views: ["view1": view1]))
        } else {
            let ratioH = view2.bounds.size.width / materialSize.width
            let ratioV = view2.bounds.size.height / materialSize.height
            if ratioH > ratioV {
                view2.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[view1]-0-|", metrics: nil, views: ["view1": view1]))
            } else {
                NSLayoutConstraint.activate([
                    view1.leadingAnchor.constraint(equalTo: view2.leadingAnchor),
                    view1.trailingAnchor.constraint(equalTo: view2.trailingAnchor)
                ])
            }
        }
//        print("DEBUG: after bannerView.constraints: \(view1.constraints)")
//        print("DEBUG: after view.constraints: \(view2.constraints)")
//        print("------------------------------------------")
    }
    
    /// 設定 view1 滿屏, 貼齊 view2
    static func vpc_bounds(with view1: UIView, to view2: UIView) {
        self.vpc_removeAllConstraints(from: view1)
        view2.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[view1]-0-|", metrics: nil, views: ["view1": view1]))
        view2.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[view1]-0-|", metrics: nil, views: ["view1": view1]))
    }
    
    @available(iOS 11.0, *)
    static func vpc_fullScreen(with view1: UIView, to view2: UIView) {
        self.vpc_removeAllConstraints(from: view1)
        NSLayoutConstraint.activate([
            view1.leadingAnchor.constraint(equalTo: view2.safeAreaLayoutGuide.leadingAnchor),
            view1.trailingAnchor.constraint(equalTo: view2.safeAreaLayoutGuide.trailingAnchor),
            view1.topAnchor.constraint(equalTo: view2.safeAreaLayoutGuide.topAnchor),
            view1.bottomAnchor.constraint(equalTo: view2.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    /// 設定 view1 撐滿 view2 左邊以外的區域（包含 safe area）
    /// - Parameters:
    ///   - view1: 要補滿的 view
    ///   - view2: 主體 view
    static func vpc_leftMargin(with view1: UIView, to view2: UIView) {
        guard let view2Superview = view2.superview else { return }
        view1.translatesAutoresizingMaskIntoConstraints = false
        self.vpc_removeAllConstraints(from: view1)
        NSLayoutConstraint.activate([
            view1.leadingAnchor.constraint(equalTo: view2Superview.leadingAnchor),
            view1.trailingAnchor.constraint(equalTo: view2.leadingAnchor),
            view1.topAnchor.constraint(equalTo: view2Superview.topAnchor),
            view1.bottomAnchor.constraint(equalTo: view2Superview.bottomAnchor)
        ])
    }
    
    /// 設定 view1 撐滿 view2 右邊以外的區域（包含 safe area）
    /// - Parameters:
    ///   - view1: 要補滿的 view
    ///   - view2: 主體 view
    static func vpc_rightMargin(with view1: UIView, to view2: UIView) {
        guard let view2Superview = view2.superview else { return }
        view1.translatesAutoresizingMaskIntoConstraints = false
        self.vpc_removeAllConstraints(from: view1)
        NSLayoutConstraint.activate([
            view1.leadingAnchor.constraint(equalTo: view2.trailingAnchor),
            view1.trailingAnchor.constraint(equalTo: view2Superview.trailingAnchor),
            view1.topAnchor.constraint(equalTo: view2Superview.topAnchor),
            view1.bottomAnchor.constraint(equalTo: view2Superview.bottomAnchor)
        ])
    }
    
    /// 設定 view1 位於 view2 左上的位置
    /// - Parameters:
    ///   - view1: 視圖 1
    ///   - view2: 視圖 2
    ///   - multiplier: 視圖 1 長寬比例
    ///   - constant: 視圖 1 的寬
    static func vpc_leftTop(with view1: UIView, addTo view2: UIView, multiplier: CGFloat, constant: CGFloat) {
        self.vpc_removeAllConstraints(from: view1)
        var top: CGFloat = 0, left: CGFloat = 0
        let window = SDKHelper.getKeyWindow()
        top = window?.safeAreaInsets.top ?? 0
        left = window?.safeAreaInsets.left ?? 0
        
        view2.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-left-[view1(==width)]",
                                                            metrics: ["left": left, "width": constant],
                                                            views: ["view1": view1]))
        view2.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-top-[view1]",
                                                            metrics: ["top": top],
                                                            views: ["view1": view1]))
        let ratio = self.vpc_ratio(with: view1, multiplier: 1)
        view1.addConstraint(ratio)
    }
    
    /// 設定 view1 置中於 view2, 比例 1:1
    /// - Parameters:
    ///   - view1: 視圖 1
    ///   - view2: 視圖 2
    ///   - constant: 視圖 1 的寬
    static func vpc_center(with view1: UIView, to view2: UIView, constant: CGFloat) {
        self.vpc_center(with: view1, to: view2, multiplier: 1, constant: constant)
    }
    
    /// 設定 view1 置中於 view2
    /// - Parameters:
    ///   - view1: 視圖 1
    ///   - view2: 視圖 2
    ///   - multiplier: 視圖 1 長寬比例
    ///   - constant: 視圖 1 的寬
    static func vpc_center(with view1: UIView, to view2: UIView, multiplier: CGFloat, constant: CGFloat) {
        self.vpc_removeAllConstraints(from: view1)
        let midX = self.vpc_equal(with: view1, to: view2, attribute: .centerX)
        let midY = self.vpc_equal(with: view1, to: view2, attribute: .centerY)
        let ratio = self.vpc_ratio(with: view1, multiplier: 1)
        let widthConstraint = NSLayoutConstraint(item: view1, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: multiplier, constant: constant)
        view1.addConstraints([ratio, widthConstraint])
        view2.addConstraints([midX, midY])
    }
    
    /// 回傳 view 比例的 Constraint
    /// - Parameters:
    ///   - view: 視圖
    ///   - multiplier: 視圖長寬比例
    /// - Returns: NSLayoutConstraint
    static func vpc_ratio(with view: UIView, multiplier: CGFloat) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .width, relatedBy: .equal, toItem: view, attribute: .height, multiplier: multiplier, constant: 0)
    }
    
    /// 回傳 view1 相等 view2 的 attribute 屬性
    /// - Parameters:
    ///   - view1: 視圖 1
    ///   - view2: 視圖 2
    ///   - attribute: 屬性
    /// - Returns: NSLayoutConstraint
    static func vpc_equal(with view1: UIView, to view2: UIView, attribute: NSLayoutConstraint.Attribute) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view1, attribute: attribute, relatedBy: .equal, toItem: view2, attribute: attribute, multiplier: 1, constant: 0)
    }
}
