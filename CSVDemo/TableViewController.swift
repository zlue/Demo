//
//  TableViewController.swift
//  CSVDemo
//
//  Created by lue on 2018/11/20.
//  Copyright © 2018年 e lu. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = false
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        let v = HeaderRefresh()
//        v.backgroundColor = UIColor.red
        tableView.header = v
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 10
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        return cell
    }
    
    deinit {
        debugPrint("table view controller")
    }
}
class HeaderRefresh: RefreshBaseView {
    lazy var label: UILabel = {
        let lab = UILabel()
        self.addSubview(lab)
        lab.font = UIFont.systemFont(ofSize: 14)
        lab.textColor = UIColor.gray
        lab.text = "下拉刷新"
        return lab
    }()
    lazy var arrow: UIImageView = {
        let img = UIImageView(image: #imageLiteral(resourceName: "arrow"))
        self.addSubview(img)
        return img
    }()
    lazy var activityIndicator: UIActivityIndicatorView = {
        let ac = UIActivityIndicatorView(style: .gray)
        self.addSubview(ac)
        return ac
    }()
    
    override func prepare() {
        super.prepare()
        self.h = 50
    }
    override func placeSubviews() {
        super.placeSubviews()
        self.y = -self.h
        arrow.center = CGPoint(x: self.w/2 - arrow.w, y: self.h/2)
        label.sizeToFit()
        label.x = arrow.frame.maxX + 4
        label.center = CGPoint(x: label.center.x, y: arrow.center.y)
        activityIndicator.center = arrow.center
        arrow.isHidden = true
        activityIndicator.startAnimating()
    }
    override var refreshState: RefreshBaseView.RefreshState {
        get {
            return super.refreshState
        }
        set {
            
        }
    }
    override func scrollViewContentOffsetDid(change: [NSKeyValueChangeKey : Any]) {
        super.scrollViewContentOffsetDid(change: change)
        guard let scrollView = scrollView else { return }
        
        if refreshState == .refreshing {
            if window == nil { return }
            
            var inset = -scrollView.offsetY > originContentInset.top ? scrollView.offsetY : originContentInset.top
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
class RefreshBaseView: UIView {
    let offsetKey = "contentOffset"
    let sizeKey = "contentSize"
    let stateKey = "state"
    
    enum RefreshState {
        case idle
        case pulling
        case willRefresh
        case refreshing
        case noMoreData
    }
    
    private weak var _scrollView: UIScrollView?
    private var interval: TimeInterval = 0.25
    private var _state: RefreshState = .idle
    
    var scrollView: UIScrollView? {
        return _scrollView
    }
    var refreshState: RefreshState {
        get {
            return _state
        }
        set {
            _state = newValue
            DispatchQueue.main.async { [weak self] in
                self?.setNeedsLayout()
            }
        }
    }
    var originContentInset: UIEdgeInsets = .zero
    var panGesture: UIPanGestureRecognizer?
    var insertDelta: CGFloat = 0
    var pullingPercent: CGFloat = 0
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        guard let superview = newSuperview, superview.isKind(of: UIScrollView.self) else { return }
        removeObserver()
        guard let scrollView = superview as? UIScrollView else { return }
        _scrollView = scrollView
        _scrollView?.alwaysBounceVertical = true
        originContentInset = scrollView.inset
        refreshState = .idle
        
        self.x = scrollView.contentInset.left
        self.w = scrollView.w
        
        addObserver()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        prepare()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    override func layoutSubviews() {
        placeSubviews()
        superview?.layoutSubviews()
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard isUserInteractionEnabled else { return }
        guard let path = keyPath else { return }
        guard let changed = change else { return }
        if path == sizeKey { scrollViewContentSizeDid(change: changed) }
        if isHidden { return }
        if path == offsetKey { scrollViewContentOffsetDid(change: changed) }
        else if path == stateKey { scrollViewPanStateDid(change: changed) }
    }
    
    private func addObserver() {
        panGesture = _scrollView?.panGestureRecognizer
        
        _scrollView?.addObserver(self, forKeyPath: offsetKey, options: [.old, .new], context: nil)
        _scrollView?.addObserver(self, forKeyPath: sizeKey, options: [.old, .new], context: nil)
        panGesture?.addObserver(self, forKeyPath: stateKey, options: [.old, .new], context: nil)
    }
    private func removeObserver() {
        _scrollView?.removeObserver(self, forKeyPath: offsetKey)
        _scrollView?.removeObserver(self, forKeyPath: sizeKey)
        panGesture?.removeObserver(self, forKeyPath: stateKey)
        panGesture = nil
    }
    
    func beginRefreshing() {
        UIView.animate(withDuration: interval) {
            self.alpha = 1
        }
        self.pullingPercent = 1
        
        if window == nil {
            refreshState = .willRefresh
            setNeedsDisplay()
        }
        else {
            refreshState = .refreshing
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
        removeObserver()
    }
}

extension UIScrollView {
    var header: RefreshBaseView? {
        get {
            return objc_getAssociatedObject(self, "header") as? RefreshBaseView
        }
        set {
            if let h = newValue {
                if let old = header { old.removeFromSuperview() }
                insertSubview(h, at: 0)
                objc_setAssociatedObject(self, "header", h, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
            }
        }
    }
    
    
    var offset: CGPoint {
        get {
            return contentOffset
        }
        set {
            contentOffset = newValue
        }
    }
    var offsetY: CGFloat {
        get {
            return contentOffset.y
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
            contentInset = newValue
        }
    }
    var insetTop: CGFloat {
        get {
            return inset.top
        }
        set {
            var set = inset
            set.top = newValue
            inset = set
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
