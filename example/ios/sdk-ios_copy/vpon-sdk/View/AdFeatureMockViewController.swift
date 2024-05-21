//
//  AdFeatureMockViewController.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/11/7.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import UIKit
import MessageUI
import StoreKit

class AdFeatureMockViewController: UIViewController {
    
    private var moreInfo: [String: Any]?
    private var sendMsg: AdSendMsg?
    private var store: AdStore?
    
    /// Present 傳送訊息的頁面
    /// - Parameters:
    ///   - sendMsg: 訊息 參數模型
    ///   - rootViewCtrl: 根控制項
    class func present(with sendMsg: AdSendMsg, rootViewCtrl: UIViewController) {
        let vc = AdFeatureMockViewController()
        vc.sendMsg = sendMsg
        rootViewCtrl.present(vc, animated: false)
    }
    
    /// Present AppStore 的頁面
    /// - Parameters:
    ///   - store: store 參數模型
    ///   - rootViewCtrl: 根控制項
    class func present(with store: AdStore, rootViewCtrl: UIViewController) {
        let vc = AdFeatureMockViewController()
        vc.store = store
        rootViewCtrl.present(vc, animated: false)
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        
        if let sendMsg {
            let success = sendSms(sendMsg)
            if !success { dismiss() }
        } else if let store {
            openStore(store)
        } else {
            dismiss()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    
    private func dismiss() {
        dismiss(animated: false)
    }
}

// MARK: - MFMessageComposeViewControllerDelegate

extension AdFeatureMockViewController: MFMessageComposeViewControllerDelegate {
    
    private func sendSms(_ sendMsg: AdSendMsg) -> Bool {
        if !MFMessageComposeViewController.canSendText() || !sendMsg.canSend() { return false }
        let msgVC = MFMessageComposeViewController()
        msgVC.body = sendMsg.body
        msgVC.recipients = sendMsg.recipients
        msgVC.messageComposeDelegate = self
        present(msgVC, animated: true)
        return true
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        self.resignFirstResponder()
        switch result {
        case .cancelled:
            break
        case .sent:
            break
        case .failed:
            break
        @unknown default:
            break
        }
        controller.dismiss(animated: true) {
            self.dismiss()
        }
    }
}

// MARK: - SKStoreProductViewControllerDelegate

extension AdFeatureMockViewController: SKStoreProductViewControllerDelegate {
    
    private func openStore(_ store: AdStore) {
        let storeVC = SKStoreProductViewController()
        storeVC.delegate = self
        var parameters = [String: Any]()
        
        if let id = store.storeID {
            parameters[SKStoreProductParameterITunesItemIdentifier] = id
        }
        if let token = store.campaignToken {
            parameters[SKStoreProductParameterCampaignToken] = token
        }
        if let token = store.providerToken {
            parameters[SKStoreProductParameterProviderToken] = token
        }
        
        if #available(iOS 10.0, *) {
            if let token = store.partnerToken {
                parameters[SKStoreProductParameterAdvertisingPartnerToken] = token
            }
        }
        
        storeVC.loadProduct(withParameters: parameters) { [weak self] result, error in
            guard let self else { return }
            if result {
                self.present(storeVC, animated: true)
            } else {
                self.dismiss()
            }
        }
    }
    
    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.dismiss(animated: true) {
            self.dismiss()
        }
    }
    
    func validStoreParam(config: [String: Any], key: String) -> String {
        var value = ""
        if let key = config[key] as? String {
            value = key
        }
        return value
    }
}
