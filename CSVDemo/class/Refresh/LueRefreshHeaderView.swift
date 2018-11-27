//
//  LueRefreshHeaderBaseView.swift
//  CSVDemo
//
//  Created by lue on 2018/11/22.
//  Copyright © 2018年 e lu. All rights reserved.
//

import UIKit

class LueRefreshHeaderBaseView: LueRefreshBaseView {

    private var insertDelta: CGFloat = 0
    
    convenience init(block: @escaping () -> Void) {
        self.init(frame: CGRect.zero)
        self.refreshingBlock = block
    }
    
    override func prepare() {
        super.prepare()
        self.h = 54
    }
    override var refreshState: RefreshState {
        get {
            return super.refreshState
        }
        set {
            guard let oldState = newValue == refreshState ? nil : refreshState, let scrollView = self.scrollView else {
                return
            }
            super.refreshState = newValue
            
            if newValue == .idle {
                if oldState != .refreshing { return }
                UIView.animate(withDuration: interval, animations: {
                    scrollView.insetTop += self.insertDelta
                }) { (_) in
                    self.pullingPercent = 0
                }
            } else if newValue == .refreshing {
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.4, animations: {
                        if scrollView.panGestureRecognizer.state != .cancelled {
                            let top = self.originContentInset.top + self.h
                            scrollView.insetTop = top
                            var offset = scrollView.contentOffset
                            offset.y = -top
                            scrollView.setContentOffset(offset, animated: false)
                        }
                    }) { (_) in
                        self.executeRefreshingCallBack()
                    }
                }
            }
        }
    }
    override func scrollViewContentOffsetDid(change: [NSKeyValueChangeKey : Any]) {
        super.scrollViewContentOffsetDid(change: change)
        guard let scrollView = scrollView else { return }
        
        if refreshState == .refreshing {
            if window == nil { return }
            
            var inset = -scrollView.offsetY > originContentInset.top ? -scrollView.offsetY : originContentInset.top
            inset = inset > self.h + originContentInset.top ? self.h + originContentInset.top : inset
            scrollView.insetTop = inset
            
            insertDelta = originContentInset.top - inset
            return
        }
        originContentInset = scrollView.inset
        let offsetY = scrollView.offsetY
        let happenOffsetY = -originContentInset.top
        
        if offsetY > happenOffsetY { return }
        
        let normal2pullingOffsetY = happenOffsetY - self.h
        let pullingPercent = (happenOffsetY - offsetY)/self.h
        
        if scrollView.isDragging {
            self.pullingPercent = pullingPercent
            if refreshState == .idle, offsetY < normal2pullingOffsetY {
                refreshState = .pulling
            }
            else if refreshState == .pulling, offsetY >= normal2pullingOffsetY {
                refreshState = .idle
            }
        }
        else if refreshState == .pulling {
            beginRefreshing()
        }
        else if pullingPercent < 1 {
            self.pullingPercent = pullingPercent
        }
    }

}
