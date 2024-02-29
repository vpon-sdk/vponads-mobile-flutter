//
//  VpadnVideoAdTableCell.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/5/3.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import UIKit

class VpadnVideoAdTableCell: UITableViewCell {
    var vpadnInReadAd: VpadnInReadAd?
    var contentConstraint: NSLayoutConstraint?
    var mainTable: UITableView?
    weak var delegate: VpadnInReadAdDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentView.backgroundColor = .blue
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func loadWithPid(_ pid: String, identifiers: [String], indexPath: IndexPath, delegate: VpadnInReadAdDelegate?) -> VpadnInReadAd {
        vpadnInReadAd = VpadnInReadAd(placementId: pid, delegate: self)
        vpadnInReadAd?.vpadnInReadAdType = .inTableCustomAd
        vpadnInReadAd?.indexPath = indexPath
        self.delegate = delegate
        vpadnInReadAd?.loadAdWithTestIdentifiers(identifiers)
        
        contentConstraint = NSLayoutConstraint(item: self.contentView,
                                               attribute: .width,
                                               relatedBy: .equal,
                                               toItem: self.contentView,
                                               attribute: .height,
                                               multiplier: 320 / 195,
                                               constant: 0)
        self.contentView.addConstraint(contentConstraint!)
        return vpadnInReadAd!
    }
    
    private func addVideoAdView() {
        guard let vpadnInReadAd,
        let view = vpadnInReadAd.videoView() else { return }
        self.contentView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.translatesAutoresizingMaskIntoConstraints = false
        view.superview?.addConstraints([
            NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: view.superview, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: view.superview, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal, toItem: view.superview, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: view, attribute: .trailing, relatedBy: .equal, toItem: view.superview, attribute: .trailing, multiplier: 1, constant: 0)
        ])
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

// MARK: - VpadnInReadAd Delegate

extension VpadnVideoAdTableCell: VpadnInReadAdDelegate {
    
    func vpadnInReadAd(_ ad: VpadnInReadAd, didFailLoading error: Error) {
        VponConsole.log("\(#file), \(#function)")
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if let contentConstraint = self.contentConstraint {
                self.contentView.removeConstraint(contentConstraint)
            }
            self.contentConstraint = NSLayoutConstraint(item: self.contentView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
            self.contentView.addConstraint(self.contentConstraint!)
            if let indexPath = ad.indexPath {
                self.mainTable?.reloadRows(at: [indexPath], with: .none)
            }
        }
        delegate?.vpadnInReadAd?(ad, didFailLoading: error)
    }
    
    func vpadnInReadAdWillLoad(_ ad: VpadnInReadAd) {
        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdWillLoad?(ad)
    }
    
    func vpadnInReadAdDidLoad(_ ad: VpadnInReadAd) {
        VponConsole.log("\(#file), \(#function)")
        self.addVideoAdView()
        delegate?.vpadnInReadAdDidLoad?(ad)
    }
    
    func vpadnInReadAdWillStart(_ ad: VpadnInReadAd) {
        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdWillStart?(ad)
    }
    
    func vpadnInReadAdDidStart(_ ad: VpadnInReadAd) {
        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdDidStart?(ad)
    }
    
    func vpadnInReadAdWillStop(_ ad: VpadnInReadAd) {
        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdWillStop?(ad)
    }
    
    func vpadnInReadAdDidStop(_ ad: VpadnInReadAd) {
        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdDidStop?(ad)
    }
    
    func vpadnInReadAdDidPause(_ ad: VpadnInReadAd) {
        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdDidPause?(ad)
    }
    
    func vpadnInReadAdDidResume(_ ad: VpadnInReadAd) {
        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdDidResume?(ad)
    }
    
    func vpadnInReadAdDidMute(_ ad: VpadnInReadAd, withRatio ratio: CGFloat) {
        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdDidMute?(ad)
    }
    
    func vpadnInReadAdDidUnmute(_ ad: VpadnInReadAd) {
        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdDidUnmute?(ad)
    }
    
    func vpadnInReadAdCanExpand(_ ad: VpadnInReadAd, withRatio ratio: CGFloat) {
        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdCanExpand?(ad, withRatio: ratio)
    }
    
    func vpadnInReadAdWillExpand(_ ad: VpadnInReadAd) {
        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdWillExpand?(ad)
    }
    
    func vpadnInReadAdDidExpand(_ ad: VpadnInReadAd) {
        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdDidExpand?(ad)
    }
    
    func vpadnInReadAdCanCollapse(_ ad: VpadnInReadAd) {
        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdCanCollapse?(ad)
    }
    
    func vpadnInReadAdWillCollapse(_ ad: VpadnInReadAd) {
        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdWillCollapse?(ad)
    }
    
    func vpadnInReadAdDidCollapse(_ ad: VpadnInReadAd) {
        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdDidCollapse?(ad)
    }
    
    func vpadnInReadAdWasClicked(_ ad: VpadnInReadAd) {
        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdWasClicked?(ad)
    }
    
    func vpadnInReadAdDidClickBrowserClose(_ ad: VpadnInReadAd) {
        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdDidClickBrowserClose?(ad)
    }
    
    func vpadnInReadAdWillTakeOverFullScreen(_ ad: VpadnInReadAd) {
        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdWillTakeOverFullScreen?(ad)
    }
    
    func vpadnInReadAdDidTakeOverFullScreen(_ ad: VpadnInReadAd) {
        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdDidTakeOverFullScreen?(ad)
    }
    
    func vpadnInReadAdWillDismissFullscreen(_ ad: VpadnInReadAd) {
        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdWillDismissFullscreen?(ad)
    }
    
    func vpadnInReadAdDidDismissFullscreen(_ ad: VpadnInReadAd) {
        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdDidDismissFullscreen?(ad)
    }
    
    func vpadnInReadAdSkipButtonTapped(_ ad: VpadnInReadAd) {
        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdSkipButtonTapped?(ad)
    }
    
    func vpadnInReadAdSkipButtonDidShow(_ ad: VpadnInReadAd) {
        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdSkipButtonDidShow?(ad)
    }
    
    func vpadnInReadAdDidReset(_ ad: VpadnInReadAd) {
        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdDidReset?(ad)
    }
    
    func vpadnInReadAdDidClean(_ ad: VpadnInReadAd) {
        VponConsole.log("\(#file), \(#function)")
        delegate?.vpadnInReadAdDidClean?(ad)
    }
}
