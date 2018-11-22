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
        
//        let path = Bundle.main.path(forResource: "trans.cn", ofType: "csv") ?? ""
//        let parser = CSV.Parser(url: URL(fileURLWithPath: path), configuration: CSV.Configuration(delimiter: ",", encoding: .utf8))
//        parser?.delegate = self
//        do { try parser?.parse() } catch {
//            debugPrint("错误❌")
//        }
        
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

    internal var didBeginLineIndex: UInt?
    internal var content = Array<[String]>()
    internal var currentFieldValues = Array<String>()
}
extension ViewController: ParserDelegate {
    func parserDidBeginDocument(_ parser: CSV.Parser) {
        content.removeAll()
        currentFieldValues.removeAll()
    }
    func parserDidEndDocument(_ parser: CSV.Parser) {
//        debugPrint(content)

        var result = ""
        content.forEach { (list) in
            result += "\"e_\(list[1])\" = \"\(list[2])\";\n"
        }
//        debugPrint(result)
        
        WalletManage.share.save(obj: result)
    }
    
    func parser(_ parser: CSV.Parser, didBeginLineAt index: UInt) {
        didBeginLineIndex = index
        currentFieldValues.removeAll()
    }
    func parser(_ parser: CSV.Parser, didEndLineAt index: UInt) {
        guard let _ = didBeginLineIndex else {
            return
        }
        content.append(currentFieldValues)
    }
    func parser(_ parser: CSV.Parser, didReadFieldAt index: UInt, value: String) {
        currentFieldValues.append(value)
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
    func save(obj: String, name: String = "csv") {
        do {
            try obj.write(to: directory.appendingPathComponent(name), atomically: true, encoding: .utf8)
        } catch {
            debugPrint("错误❎")
        }
    }
}
