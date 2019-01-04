//
//  LuePopView.swift
//  CSVDemo
//
//  Created by lue on 2018/11/26.
//  Copyright © 2018年 e lu. All rights reserved.
//

import UIKit

class LuePopView: UIView, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {
    
    private var textsArr: [String]!
    private var block: ((String, Int) -> Void)?
    
    private var contentView: UIView!
    private var tableView: UITableView!
    private var dependRect: CGRect!
    
    private let _sw = UIScreen.main.bounds.width
    private let _sh = UIScreen.main.bounds.height
    private let navMaxY = UIApplication.shared.statusBarFrame.maxY + 44 + 1
    
    
    private let arrowH: CGFloat = 10
    private let margin: CGFloat = 6
    private let bgColor: UIColor = UIColor.white
    
    enum BarItemLocation {
        case left
        case right
    }
    
    static func show(size: CGSize, atView: UIView, list: [String], isShowArrow: Bool = true, block: @escaping (String, Int) -> Void) {
        _ = LuePopView(size: size, atView: atView, isShowArrow: isShowArrow, list: list, block: block)
    }
    
    static func show(size: CGSize, atItem: BarItemLocation, list: [String], block: @escaping (String, Int) -> Void) {
        _ = LuePopView(size: size, atItem: atItem, list: list, block: block)
    }
    
    convenience private init(size: CGSize, atView: UIView? = nil, isShowArrow: Bool = true, atItem: BarItemLocation = .left, list: [String], block: @escaping (String, Int) -> Void) {
        self.init(frame: UIScreen.main.bounds)
        self.block = block
        textsArr = list

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissSelf(tap:)))
        tap.delegate = self
        addGestureRecognizer(tap)
        UIApplication.shared.delegate?.window??.addSubview(self)
        
        var originFrame: CGRect
        var arrowOrigin: CGPoint!
        if let at = atView {
            dependRect = at.convert(at.bounds, to: UIApplication.shared.keyWindow)
            originFrame = calculateOrigin(rect: dependRect, size: size)
            if isShowArrow {
                if dependRect.minY > originFrame.minY {
                    originFrame.origin.y -= arrowH - 2
                    arrowOrigin = CGPoint(x: dependRect.minX + (dependRect.width - arrowH)/2, y: originFrame.maxY - 2)
                }
                else {
                    arrowOrigin = CGPoint(x: dependRect.minX + (dependRect.width - arrowH)/2, y: originFrame.minY)
                    originFrame.origin.y += arrowH - 2
                }
            }
        }
        else {
            dependRect = CGRect.zero
            switch atItem {
            case .left:
                originFrame = CGRect(origin: CGPoint(x: margin, y: navMaxY + arrowH - 2), size: size)
                arrowOrigin = CGPoint(x: originFrame.minX + 14, y: navMaxY)
            case .right:
                originFrame = CGRect(origin: CGPoint(x: _sw - size.width - margin, y: navMaxY + arrowH - 2), size: size)
                arrowOrigin = CGPoint(x: originFrame.maxX - 16 - arrowH, y: navMaxY)
            }
        }
    
        var frame: CGRect
        if dependRect.minY > originFrame.minY {
            frame = CGRect(x: originFrame.minX, y: dependRect.minY, width: size.width, height: 0)
        } else {
            frame = CGRect(x: originFrame.minX, y: originFrame.minY, width: size.width, height: 0)
        }
        
        contentView = UIView(frame: frame)
        tableView = UITableView(frame: CGRect.zero, style: .plain)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)
        tableView.sectionIndexColor = UIColor(hex: "f5")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.clear
        tableView.rowHeight = 40
        tableView.isScrollEnabled = size.height < CGFloat(40*list.count)
        addSubview(contentView)
        contentView.addSubview(tableView)
        
        contentView.backgroundColor = bgColor
        contentView.layer.cornerRadius = 6
        contentView.layer.borderColor = UIColor(hex: "f5").cgColor
        contentView.layer.borderWidth = 1
        contentView.layer.shadowRadius = 6
        contentView.layer.shadowColor = UIColor.gray.cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowOpacity = 1
        
        if isShowArrow {
            let arrow = LueArrowView(frame: CGRect(origin: arrowOrigin, size: CGSize(width: arrowH, height: arrowH)), c: bgColor)
            if originFrame.minY < arrowOrigin.y {
                arrow.transform = CGAffineTransform(rotationAngle: .pi)
            }
            addSubview(arrow)
        }
        
        UIView.animate(withDuration: 0.25, animations: { [weak self] in
            frame.size.height = size.height
            frame.origin.y = originFrame.minY
            self?.contentView.frame = frame
        }) { [weak self] (_) in
            self?.tableView.frame = self?.contentView.bounds ?? CGRect.zero
        }
    }
    private func calculateOrigin(rect: CGRect, size: CGSize) -> CGRect {
        var x = rect.minX + (rect.width - size.width)/2
        x = x + size.width + margin > _sw ? _sw - size.width - margin : x
        x = x < margin ? margin : x
        
        var y = rect.maxY + size.height + margin > _sh ? rect.minY - size.height : rect.maxY
        
        if y < 0 || y + size.height > _sh {
            y = (rect.height - size.height)/2 + rect.minY
        }
        return CGRect(origin: CGPoint(x: x, y: y), size: size)
    }
    
    @objc private func dismissSelf(tap: UITapGestureRecognizer) {
        dismiss()
    }
    private func dismiss() {
        var frame = self.contentView.frame
        self.tableView.frame = CGRect.zero
        UIView.animate(withDuration: 0.25, animations: { [weak self] in
            if self?.dependRect.minY ?? 0 > frame.minY {
                frame.origin.y = frame.maxY
            }
            frame.size.height = 0
            self?.contentView.frame = frame
            self?.contentView.alpha = 0.5
        }) { [weak self] (_) in
            self?.removeFromSuperview()
        }
    }
    private override init(frame: CGRect) {
        super.init(frame: frame)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == self
    }
    
    private func initCell() -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        cell.backgroundColor = UIColor.clear
        cell.selectionStyle = .none
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.font = UIFont.systemFont(ofSize: 15)
        cell.textLabel?.textAlignment = .center
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return textsArr.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? initCell()
        cell.textLabel?.text = textsArr[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        block?(textsArr[indexPath.row], indexPath.row)
        dismiss()
    }
    
    deinit {
        debugPrint("deinit \(type(of: self))")
    }
}
class LueArrowView: UIView {
    convenience init(frame: CGRect, c bgColor: UIColor) {
        self.init(frame: frame)
        self.bgColor = bgColor
    }
    private override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.isOpaque = false
        
        self.layer.shadowRadius = 6
        self.layer.shadowColor = UIColor.gray.cgColor
        self.layer.shadowOpacity = 1
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: w/2, y: 0))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.addLine(to: CGPoint(x: w, y: h))

        self.layer.shadowPath = path.cgPath
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var bgColor: UIColor!
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        drawCorner()
    }
    private func drawCorner() {
        let w = frame.width
        let h = frame.height

        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(bgColor.cgColor)
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: w/2, y: 0))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.addLine(to: CGPoint(x: w, y: h))
        context?.addPath(path)
        context?.fillPath()
    }
}
