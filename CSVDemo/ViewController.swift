//
//  ViewController.swift
//  CSVDemo
//
//  Created by e lu on 2018/11/2.
//  Copyright © 2018年 e lu. All rights reserved.
//

import UIKit
import HandyJSON

struct EVTExModel: HandyJSON {
    var name: String?
    var code: String?
    var en: String?
    var cn: String?
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let path = Bundle.main.path(forResource: "AMap_adcode_citycode", ofType: "csv") ?? ""
        let parser = CSV.Parser(url: URL(fileURLWithPath: path), configuration: CSV.Configuration(delimiter: ",", encoding: .utf8))
        parser?.delegate = self
        do { try parser?.parse() } catch {
            debugPrint("错误❌")
        }
        
//        let path = Bundle.main.path(forResource: "evt_ex_codes", ofType: "json") ?? ""
//        do {
//            var enResult = ""
//            var cnResult = ""
//            try [EVTExModel].deserialize(from: String(contentsOfFile: path))?.forEach({ (m) in
//                if let tem = m {
//                    enResult += "\"e_\(tem.code ?? "")\" = \"\(tem.en ?? "")\";\n"
//                    cnResult += "\"e_\(tem.code ?? "")\" = \"\(tem.cn ?? tem.en ?? "")\";\n"
//                }
//            })
//            WalletManage.share.save(obj: enResult, name: "en.strings")
//            WalletManage.share.save(obj: cnResult, name: "cn.strings")
//        } catch {}
    }

    @IBAction func buttonAction(_ sender: UIButton) {
        
//        // Prepare the popup
//        let title = "THIS IS A DIALOG WITHOUT IMAGE"
//        let message = "If you don't pass an image to the default dialog, it will display just as a regular dialog. Moreover, this features the zoom transition"
//
//        // Create the dialog
//        let popup = PopupDialog(title: title, message: message, alignment: .center)
//
//        // Create first button
//        let buttonOne = CancelButton(title: "CANCEL") {
//
//        }
//
//        // Create second button
//        let buttonTwo = DefaultButton(title: "OK") {
//
//        }
//
//        // Add buttons to dialog
//        popup.addButtons([buttonOne, buttonTwo])
//
//        // Present dialog
//        self.present(popup, animated: true, completion: nil)
        
//        LuePopView.show(size: CGSize(width: 100, height: 100), atView: sender, list: ["1", "2"], isShowArrow: false) { (text, index) in
//
//        }
    }
    
    internal var didBeginLineIndex: UInt?
    internal var province = [Province]()
    internal var currentFieldValues = Array<String>()
}
extension ViewController: ParserDelegate {
    func parserDidBeginDocument(_ parser: CSV.Parser) {
        province.removeAll()
        currentFieldValues.removeAll()
    }
    func parserDidEndDocument(_ parser: CSV.Parser) {
//        debugPrint(content)

//        var result = ""
//        content.forEach { (list) in
//            result += "\(list[1]):\(list[0])\n"
//        }
        
        WalletManage.share.save(obj: province.toJSONString() ?? "")
    }
    
    func parser(_ parser: CSV.Parser, didBeginLineAt index: UInt) {
        didBeginLineIndex = index
        currentFieldValues.removeAll()
    }
    func parser(_ parser: CSV.Parser, didEndLineAt index: UInt) {
        guard let _ = didBeginLineIndex else {
            return
        }
        let code = currentFieldValues[1]
        let name = currentFieldValues[0]
        let ac = currentFieldValues[2]
        if code.hasSuffix("0000") {
            if name.contains("区") {
                if name.contains("内蒙古") {
                    province.append(Province(code, String(name.prefix(3)), ac))
                }
                else {
                    province.append(Province(code, String(name.prefix(2)), ac))
                }
            }
            else {
                province.append(Province(code, String(name.prefix(name.count - 1)), ac))
            }
        }
        else if code.hasSuffix("00") {
            let m = province.filter({$0.code?.prefix(2) == code.prefix(2)}).first
            if m?.city == nil {
                if m?.ac?.isEmpty == true {
                    m?.city = [City(code, name)]
                }
            }
            else {
                m?.city?.append(City(code, name))
            }
        }
        else {
            let p = province.filter({$0.code?.prefix(2) == code.prefix(2)}).first
            let m = p?.city?.filter({$0.code?.prefix(4) == code.prefix(4)}).first
            if p?.ac?.isEmpty == false {
                if p?.city == nil {
                    p?.city = [City(code, name)]
                }
                else {
                    p?.city?.append(City(code, name))
                }
            }
            else {
                if m?.area == nil {
                    m?.area = [name]
                }
                else {
                    m?.area?.append(name)
                }
            }
        }
    }
    
    func parser(_ parser: CSV.Parser, didReadFieldAt index: UInt, value: String) {
        currentFieldValues.append(value)
    }
}
class Province: HandyJSON {
    required init() {}
    var code: String?
    var name: String?
    var city: [City]?
    var ac: String?
    init(_ c: String, _ n: String, _ a: String) {
        self.code = c
        self.name = n
        self.ac = a
//        self.city = []
    }
    
    func mapping(mapper: HelpingMapper) {
        mapper >>> code
        mapper >>> ac
    }
}
class City: HandyJSON {
    required init() {}
    var code: String?
    var name: String?
    var area: [String]?
    
    init(_ c: String, _ n: String) {
        self.code = c
        self.name = n
//        self.area = []
    }
    
    func mapping(mapper: HelpingMapper) {
        mapper >>> code
    }
}

final class WalletManage {
    let directory: URL

    static let share: WalletManage = WalletManage(directoryName: "wallets")
    
    init(directoryName: String) {
        let path = NSHomeDirectory().appending("/Documents/") + directoryName
        directory = URL(fileURLWithPath: path)
        debugPrint(path)
        do {
            try load()
        } catch {
            debugPrint("❎")
        }
    }
    
    private func load() throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
    }
    func save(obj: String, name: String = "city.json") {
        debugPrint(obj)
        do {
            try obj.write(to: directory.appendingPathComponent(name), atomically: true, encoding: .utf8)
        } catch {
            debugPrint("错误❎")
        }
    }
}
