//
//  ETBottomActionController.swift
//  MyEVT
//
//  Created by e lu on 2018/10/26.
//  Copyright © 2018年 shyy. All rights reserved.
//

/*
let nav = ETBottomActionController(rootViewController: vc)
nav.isClickMaskDismiss = true
nav.controllerHeight = 100
nav.dismissSelf = { [weak self] in
}
self.present(nav)
 */

import UIKit

class ETBottomActionController: UINavigationController {
    
    public var controllerHeight: CGFloat = UIScreen.main.bounds.height*0.6
    public var isClickMaskDismiss = false
    
    public var dismissSelf: (()->())?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.barTintColor = UIColor(hex: "fb")
        navigationBar.isTranslucent = false
        navigationBar.tintColor = UIColor.black
        navigationBar.titleTextAttributes = [.foregroundColor: UIColor.black, .font: UIFont.systemFont(ofSize: 15)]
        navigationBar.corner(byRoundingCorners: [.topLeft, .topRight], radii: 6)
    }
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if self.children.count > 0 {
            viewController.hidesBottomBarWhenPushed = true
        }
        let backItem = UIBarButtonItem()
        backItem.title = ""
        viewController.navigationItem.backBarButtonItem = backItem
        super.pushViewController(viewController, animated: animated)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

class ETPresentController: UIPresentationController {
    lazy var maskView: UIView = {
        let v = UIView()
        if let frame = containerView?.bounds {
            v.frame = frame
        }
        v.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        return v
    }()
    
    @objc func dismissVC() {
        (presentedViewController as? ETBottomActionController)?.dismissSelf?()
        presentedViewController.dismiss(animated: true, completion: nil)
    }
    
    override func presentationTransitionWillBegin() {
        maskView.alpha = 0
        containerView?.addSubview(maskView)
        UIView.animate(withDuration: 0.35) { [weak self] in
            self?.maskView.alpha = 1
        }
    }
    override func dismissalTransitionWillBegin() {
        UIView.animate(withDuration: 0.35) { [weak self] in
            self?.maskView.alpha = 0
        }
    }
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed {
            maskView.removeFromSuperview()
        }
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        var height: CGFloat
        if case let vc as ETBottomActionController = presentedViewController {
            height = vc.controllerHeight
            if vc.isClickMaskDismiss {
                maskView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissVC)))
            }
        } else {
            height = UIScreen.main.bounds.width
        }
        return CGRect(x: 0, y: UIScreen.main.bounds.height - height, width: UIScreen.main.bounds.width, height: height)
    }
}
extension UIViewController: UIViewControllerTransitioningDelegate {
    func present(_ vc: UIViewController) {
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = self
        self.present(vc, animated: true, completion: nil)
    }
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return ETPresentController(presentedViewController: presented, presenting: presenting)
    }
}
