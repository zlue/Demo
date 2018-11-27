//
//  LueRefreshBaseView.swift
//  CSVDemo
//
//  Created by lue on 2018/11/22.
//  Copyright © 2018年 e lu. All rights reserved.
//

import UIKit

class LueRefreshBaseView: UIView {
    struct LueRefreshKeys {
        static let offset = "contentOffset"
        static let size = "contentSize"
        static let state = "state"
        static var header = "header"
        static var footer = "footer"
    }
    enum RefreshState {
        case idle
        case pulling
        case willRefresh
        case refreshing
        case noMoreData
    }
    
    private weak var _scrollView: UIScrollView?
    private var _state: RefreshState = .idle
    private var panGesture: UIPanGestureRecognizer?
    
    var interval: TimeInterval = 0.25
    var scrollView: UIScrollView? {
        return _scrollView
    }
    var refreshState: RefreshState {
        get {
            return _state
        }
        set {
            _state = newValue
            DispatchQueue.main.async {
                self.setNeedsLayout()
            }
        }
    }
   
    var originContentInset: UIEdgeInsets = .zero
    var pullingPercent: CGFloat = 0
    
    var refreshingBlock: (() -> Void)?
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        guard let superview = newSuperview, superview.isKind(of: UIScrollView.self) else { return }
        removeObserver()
        guard let scrollView = superview as? UIScrollView else { return }
        _scrollView = scrollView
        _scrollView?.alwaysBounceVertical = true
        originContentInset = scrollView.inset
        
        self.x = scrollView.contentInset.left
        self.w = scrollView.w
        
        addObserver()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        refreshState = .idle
        prepare()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    override func layoutSubviews() {
        placeSubviews()
        superview?.layoutSubviews()
    }
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        if refreshState == .willRefresh {
            refreshState = .refreshing
        }
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard isUserInteractionEnabled else { return }
        guard let path = keyPath else { return }
        guard let changed = change else { return }
        if path == LueRefreshKeys.size { scrollViewContentSizeDid(change: changed) }
        if isHidden { return }
        if path == LueRefreshKeys.offset { scrollViewContentOffsetDid(change: changed) }
        else if path == LueRefreshKeys.state { scrollViewPanStateDid(change: changed) }
    }
    
    private func addObserver() {
        panGesture = _scrollView?.panGestureRecognizer
        
        _scrollView?.addObserver(self, forKeyPath: LueRefreshKeys.offset, options: [.old, .new], context: nil)
        _scrollView?.addObserver(self, forKeyPath: LueRefreshKeys.size, options: [.old, .new], context: nil)
        panGesture?.addObserver(self, forKeyPath: LueRefreshKeys.state, options: [.old, .new], context: nil)
    }
    private func removeObserver() {
        _scrollView?.removeObserver(self, forKeyPath: LueRefreshKeys.offset)
        _scrollView?.removeObserver(self, forKeyPath: LueRefreshKeys.size)
        panGesture?.removeObserver(self, forKeyPath: LueRefreshKeys.state)
        panGesture = nil
    }
    
    func beginRefreshing() {
        UIView.animate(withDuration: interval) {
            self.alpha = 1
        }
        self.pullingPercent = 1
        
        if window == nil {
            if refreshState != .refreshing {
                refreshState = .willRefresh
                setNeedsDisplay()
            }
        }
        else {
            refreshState = .refreshing
        }
    }
    func executeRefreshingCallBack() {
        DispatchQueue.main.async {
            if self.scrollView?.header == self {
                self.scrollView?.footer?.resetNoMoreData()
            }
            self.refreshingBlock?()
        }
    }
    func endRefreshing() {
        DispatchQueue.main.async {
            self.refreshState = .idle
        }
    }
    
    func prepare() {
        self.autoresizingMask = [.flexibleWidth]
        self.backgroundColor = UIColor.clear
    }
    func placeSubviews() { }
    func scrollViewContentOffsetDid(change: [NSKeyValueChangeKey : Any]) {}
    func scrollViewContentSizeDid(change: [NSKeyValueChangeKey : Any]) {}
    func scrollViewPanStateDid(change: [NSKeyValueChangeKey : Any]) {}
    
    deinit {
        debugPrint("deinit \(type(of: self))")
    }
}

extension UIScrollView {
    var header: LueRefreshHeaderBaseView? {
        get {
            return objc_getAssociatedObject(self, &LueRefreshBaseView.LueRefreshKeys.header) as? LueRefreshHeaderBaseView
        }
        set {
            if let h = newValue {
                if let old = header { old.removeFromSuperview() }
                insertSubview(h, at: 0)
                objc_setAssociatedObject(self, &LueRefreshBaseView.LueRefreshKeys.header, h, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
            }
        }
    }
    var footer: LueRefreshFooterBaseView? {
        get {
            return objc_getAssociatedObject(self, &LueRefreshBaseView.LueRefreshKeys.footer) as? LueRefreshFooterBaseView
        }
        set {
            if let h = newValue {
                if let old = footer { old.removeFromSuperview() }
                insertSubview(h, at: 0)
                objc_setAssociatedObject(self, &LueRefreshBaseView.LueRefreshKeys.footer, h, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
            }
        }
    }
    
    
    var offset: CGPoint {
        get { return contentOffset }
        set { contentOffset = newValue }
    }
    var offsetY: CGFloat {
        get {
            return offset.y
        }
        set {
            var set = offset
            set.y = newValue
            offset = set
        }
    }
    var offsetX: CGFloat {
        get {
            return contentOffset.x
        }
        set {
            var set = offset
            set.x = newValue
            offset = set
        }
    }
    var inset: UIEdgeInsets {
        get {
            if #available(iOS 11.0, *) {
                return adjustedContentInset
            }
            return contentInset
        }
        set {
            self.contentInset = newValue
        }
    }
    var insetTop: CGFloat {
        get {
            return inset.top
        }
        set {
            var old = contentInset
            old.top = newValue
            if #available(iOS 11.0, *) {
                old.top -= (adjustedContentInset.top - contentInset.top)
            }
            inset = old
        }
    }
    var insetBottom: CGFloat {
        get {
            return inset.bottom
        }
        set {
            var old = contentInset
            old.bottom = newValue
            if #available(iOS 11.0, *) {
                old.bottom -= (adjustedContentInset.bottom - contentInset.bottom)
            }
            inset = old
        }
    }
}
extension UIView {
    var x: CGFloat {
        get {
            return self.frame.origin.x
        }
        set {
            self.frame.origin.x = newValue
        }
    }
    
    var y: CGFloat {
        get {
            return self.frame.origin.y
        }
        set {
            self.frame.origin.y = newValue
        }
    }
    
    var w: CGFloat {
        get {
            return self.frame.size.width
        }
        set {
            self.frame.size.width = newValue
        }
    }
    
    var h: CGFloat {
        get {
            return self.frame.size.height
        }
        set {
            self.frame.size.height = newValue
        }
    }
    
    var size: CGSize {
        get {
            return self.frame.size
        }
        set {
            self.frame.size = newValue
        }
    }
    
    var origin: CGPoint {
        get {
            return self.frame.origin
        }
        set {
            self.frame.origin = newValue
        }
    }
}
