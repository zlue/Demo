//
//  LueRefreshNormalBottomView.swift
//  CSVDemo
//
//  Created by lue on 2018/11/26.
//  Copyright © 2018年 e lu. All rights reserved.
//

import UIKit

class LueRefreshNormalFooter: LueRefreshFooterBaseView {
    lazy var label: UILabel = {
        let lab = UILabel()
        self.addSubview(lab)
        lab.font = UIFont.systemFont(ofSize: 14)
        lab.textColor = UIColor.gray
        lab.textAlignment = .left
        return lab
    }()
    lazy var activityIndicator: UIActivityIndicatorView = {
        let ac = UIActivityIndicatorView(style: .gray)
        ac.hidesWhenStopped = true
        self.addSubview(ac)
        return ac
    }()
    
    var labelTexts: [RefreshState: String] = [.idle: "", .pulling: "释放刷新", .refreshing: "加载中...", .willRefresh: "即将加载", .noMoreData: "No more data"]
    
    var triggerPercent: CGFloat = 0.5
    
    private var oneNewPan: Bool?
    
    override func placeSubviews() {
        super.placeSubviews()
        let labelW: CGFloat = 60
        activityIndicator.center = CGPoint(x: self.w/2 - labelW/2, y: self.h/2)
        label.center = CGPoint(x: activityIndicator.frame.maxX + labelW/2 + 6, y: self.h/2)
    }
    
    override func scrollViewContentSizeDid(change: [NSKeyValueChangeKey : Any]) {
        super.scrollViewContentSizeDid(change: change)
        
        self.y = scrollView?.contentSize.height ?? 0
    }
    
    override open func scrollViewContentOffsetDid(change: [NSKeyValueChangeKey: Any]) {
        super.scrollViewContentOffsetDid(change: change)
        guard let scrollView = self.scrollView else { return }
        if refreshState != .idle || self.y == 0 { return }
        if scrollView.insetTop + scrollView.contentSize.height > scrollView.h {
            let condition = scrollView.offsetY >= scrollView.contentSize.height - scrollView.h + self.h * self.triggerPercent + scrollView.insetBottom - self.h
            if condition {
                if let old = change[.oldKey] as? CGPoint, let new = change[.newKey] as? CGPoint {
                    if new.y <= old.y { return }
                    self.beginRefreshing()
                }
            }
        }
    }
    
    override open func scrollViewPanStateDid(change: [NSKeyValueChangeKey: Any]) {
        super.scrollViewPanStateDid(change: change)
        guard let scrollView = self.scrollView else { return }
        if refreshState != .idle { return }
        let state = scrollView.panGestureRecognizer.state
        if state == .ended {
            if scrollView.insetTop + scrollView.contentSize.height <= scrollView.h {
                if scrollView.offsetY >= -scrollView.insetTop {
                    self.beginRefreshing()
                }
            }
            else {
                if scrollView.offsetY >= scrollView.contentSize.height + scrollView.insetBottom - scrollView.h {
                    self.beginRefreshing()
                }
            }
        } else if state == .began {
            self.oneNewPan = true
        }
    }
    
    override public func beginRefreshing() {
        guard oneNewPan == true else { return }
        super.beginRefreshing()
        self.oneNewPan = false
    }
    
    override open var refreshState: RefreshState {
        get {
            return super.refreshState
        }
        set {
            guard (newValue == refreshState ? nil : refreshState) != nil else {
                return
            }
            super.refreshState = newValue
            self.label.text = labelTexts[newValue]
            label.sizeToFit()
            
            if newValue == .refreshing {
                self.executeRefreshingCallBack()
                activityIndicator.startAnimating()
            }
            else if newValue == .noMoreData || newValue == .idle {
                activityIndicator.stopAnimating()
            }
        }
    }
}
