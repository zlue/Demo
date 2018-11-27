//
//  LueNormalRefreshHeader.swift
//  CSVDemo
//
//  Created by lue on 2018/11/22.
//  Copyright © 2018年 e lu. All rights reserved.
//

import UIKit

class LueRefreshNormalHeader: LueRefreshHeaderBaseView {

    lazy var label: UILabel = {
        let lab = UILabel()
        self.addSubview(lab)
        lab.font = UIFont.systemFont(ofSize: 14)
        lab.textColor = UIColor.gray
        return lab
    }()
    lazy var arrow: UIImageView = {
        let img = UIImageView(image: #imageLiteral(resourceName: "arrow"))
        self.addSubview(img)
        return img
    }()
    lazy var activityIndicator: UIActivityIndicatorView = {
        let ac = UIActivityIndicatorView(style: .gray)
        ac.hidesWhenStopped = true
        self.addSubview(ac)
        return ac
    }()
    
    var labelTexts: [RefreshState: String] = [.idle: "下拉刷新", .pulling: "释放刷新", .refreshing: "加载中...", .willRefresh: "即将加载"]
    
    override func placeSubviews() {
        super.placeSubviews()
        self.y = -self.h
        arrow.center = CGPoint(x: self.w/2 - arrow.w, y: self.h/2)
        label.sizeToFit()
        label.x = arrow.frame.maxX + 4
        label.center = CGPoint(x: label.center.x, y: arrow.center.y)
        activityIndicator.center = arrow.center
    }
    
    override var refreshState: RefreshState {
        get {
            return super.refreshState
        }
        set {
            guard let oldState = newValue == refreshState ? nil : refreshState else {
                return
            }
            super.refreshState = newValue
            self.label.text = labelTexts[newValue]
            
            if newValue == .idle {
                if oldState == .refreshing {
                    self.arrow.transform = CGAffineTransform.identity
                    UIView.animate(withDuration: 0.4, animations: {
                        self.activityIndicator.alpha = 0.0
                    }) { (finished) in
                        if newValue != .idle { return }
                        self.activityIndicator.alpha = 1.0
                        self.activityIndicator.stopAnimating()
                        self.arrow.isHidden = false
                    }
                } else {
                    self.activityIndicator.stopAnimating()
                    self.arrow.isHidden = false
                    UIView.animate(withDuration: interval, animations: {
                        self.arrow.transform = CGAffineTransform.identity
                    })
                }
            } else if newValue == .pulling {
                self.activityIndicator.stopAnimating()
                self.arrow.isHidden = false
                UIView.animate(withDuration: interval, animations: {
                    self.arrow.transform = CGAffineTransform(rotationAngle: 0.000001 - .pi)
                })
            } else if newValue == .refreshing {
                self.activityIndicator.alpha = 1.0
                self.activityIndicator.startAnimating()
                self.arrow.isHidden = true
            }
        }
    }
}
