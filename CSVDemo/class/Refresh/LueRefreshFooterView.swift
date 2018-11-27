//
//  LueRefreshBottomBaseView.swift
//  CSVDemo
//
//  Created by lue on 2018/11/26.
//  Copyright © 2018年 e lu. All rights reserved.
//

import UIKit

class LueRefreshFooterBaseView: LueRefreshBaseView {
    
    convenience init(block: @escaping () -> Void) {
        self.init(frame: CGRect.zero)
        self.refreshingBlock = block
    }
    
    override func prepare() {
        super.prepare()
        self.h = 44
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview == nil {
            if isHidden == false {
                scrollView?.insetBottom -= self.h
            }
        }
        else if isHidden == false {
            scrollView?.insetBottom += self.h
            self.y = scrollView?.contentSize.height ?? 0
        }
    }
    
    func endRefreshingWithNoMoreData() {
        DispatchQueue.main.async {
            self.refreshState = .noMoreData
        }
    }
    
    func resetNoMoreData() {
        DispatchQueue.main.async {
            self.refreshState = .idle
        }
    }
}
