//
//  AdPresentationViewController.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/11/8.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import Foundation

class AdPresentationViewController: UIViewController, UINavigationControllerDelegate {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        return .portrait
    }
}
