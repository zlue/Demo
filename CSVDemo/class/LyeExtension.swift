
//
//  LyeExtension.swift
//  MoDuLiving
//
//  Created by sh-lx on 2017/3/10.
//  Copyright © 2017年 liangyi. All rights reserved.
//

import UIKit


typealias Task = (_ cancel : Bool) -> Void
func delay(_ time: TimeInterval, task: @escaping ()->()) -> Task? {
    func dispatch_later(block: @escaping ()->()) {
        let t = DispatchTime.now() + time
        DispatchQueue.main.asyncAfter(deadline: t, execute: block)
    }
    var closure: (()->Void)? = task
    var result: Task?
    let delayedClosure: Task = {
        cancel in
        if let internalClosure = closure {
            if (cancel == false) {
                DispatchQueue.main.async(execute: internalClosure)
            }
        }
        closure = nil
        result = nil
    }
    result = delayedClosure
    dispatch_later {
        if let delayedClosure = result {
            delayedClosure(false)
        }
    }
    return result
}
func cancel(_ task: Task?) {
    task?(true)
}


extension String {
    // 是否全是数字
    var isPureInt: Bool {
        let scan = Scanner(string: self)
        var val: Int = 0
        return scan.scanInt(&val) && scan.isAtEnd
    }
    // 16进制
    var isHexCharacter: Bool {
        let regex = "^[0-9a-fA-F]+$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: self)
    }
    /// 密码限制
    var isProperPassword: Bool {
        if self.count < 6 {
            return false
        }
        let regex = "^[0-9A-Za-z]{6,16}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: self)
    }
    /// 验证手机号
    var isPhoneNumber: Bool {
        let regex = "^((13[0-9])|(14[5,7,9])|(15[^4,\\D])|(16[6])|(17[^2,^4,^9,\\D])|(18[0-9])|(19[8,9]))\\d{8}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        debugPrint(self, predicate.evaluate(with: self))
        return predicate.evaluate(with: self)
    }
    /// 验证邮编号
    var isZipcode: Bool {
        let regex = "[1-9]\\d{5}(?!\\d)"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: self)
    }
    /// 精确验证身份证号
    var isIDCard: Bool {
        var msg: String
        let count = self.count
        if count != 18 {
            msg = "长度应为18位，而您输入的长度为: \(self.count)位"
            print(msg)
            return false
        }
        // 地区码
        let areas = ["11","12", "13","14", "15","21", "22","23", "31","32", "33","34", "35","36", "37","41", "42","43", "44","45", "46","50", "51","52", "53","54", "61","62", "63","64", "65","71", "81","82", "91"]
        let areaCode = self.prefix(2)
        if !areas.contains(String(areaCode)) {
            print("不存在地区码: \(areaCode)")
            return false
        }
        let year = Int(self.prefix(10).suffix(4))!
        var regular = "^[1-9][0-9]{5}(19|20)[0-9]{2}((01|03|05|07|08|10|12)(0[1-9]|[1-2][0-9]|3[0-1])|(04|06|09|11)(0[1-9]|[1-2][0-9]|30)|02(0[1-9]|1[0-9]|2[0-8]))[0-9]{3}[0-9X]$"
        // 闰年
        if year % 400 == 0 || (year % 4 == 0 && year % 100 != 0) {
            regular = "^[1-9][0-9]{5}(19|20)[0-9]{2}((01|03|05|07|08|10|12)(0[1-9]|[1-2][0-9]|3[0-1])|(04|06|09|11)(0[1-9]|[1-2][0-9]|30)|02(0[1-9]|[1-2][0-9]))[0-9]{3}[0-9X]$"
        }
        let predicate = NSPredicate(format: "SELF MATCHES %@", regular)
        let isMatch = predicate.evaluate(with: self)
        // 18 位
        if isMatch {
            // 校验位计算，对应系数
            let conefficient = [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2]
            var num = 0
            for i in 0..<count - 1 {
                num += Int(self.prefix(i+1).suffix(1))! * conefficient[i]
            }
            // 结果校验码
            let checkCode = ["1", "0", "X", "9", "8", "7", "6", "5", "4", "3", "2"]
            
            if checkCode[num % 11] == self.suffix(1) {
                print("满足18位身份证格式")
                return true
            } else {
                print("校验码不对, 正常应为: \(checkCode[num % 11])")
            }
        } else {
            print("可能年月日格式不对")
        }
        return false
    }
    
    func at(_ index: String.IndexDistance) -> String.Index {
        return self.index(self.startIndex, offsetBy: index)
    }
}

extension UIViewController {
    class func currentViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return currentViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return currentViewController(base: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return currentViewController(base: presented)
        }
        return base
    }
}
extension UIView {
    //查找vc
    func responderViewController() -> UIViewController? {
        var next = self.superview
        while next != nil {
            let responder = next?.next
            if responder!.isKind(of: UIViewController.self) {
                return responder as? UIViewController
            }
            next = next?.superview
        }
        return nil
    }
}
