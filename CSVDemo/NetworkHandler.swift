//
//  NetworkHandler.swift
//  CSVDemo
//
//  Created by lue on 2018/11/19.
//  Copyright © 2018年 e lu. All rights reserved.
//

import HandyJSON
import Alamofire

struct NetworkError: Error {
    var msg: String
    var localizedDescription: String {
        return msg
    }
}
struct BaseResponse<T>: HandyJSON {
    init() {}
    
    var error: Int?
    var msg: String?
    var data: T?
}
struct NetworkHandler {
    enum Api: String {
        case login = "/api2/login"
    }
    static let host = "http://t.yjxct-tms.com"
    static func request<T: Any>(_ method: HTTPMethod = .post, url: Api, module: T.Type, params: [String: Any]?, result: @escaping (Result<T>) -> Void) {
        let headers : HTTPHeaders = ["Accept": "application/json"]
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        Alamofire.request(host + url.rawValue, method: method, parameters: params, headers: headers).responseJSON { (res) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            switch res.result {
            case .success(let data):
                guard let md = BaseResponse<T>.deserialize(from: data as? [String: Any]) else {
                    return result(.failure(NetworkError(msg: "数据解析异常")))
                }
                if md.error == 0, let d = md.data {
                    result(.success(d))
                }
                else {
                    result(.failure(NetworkError(msg: md.msg ?? "解析数据不匹配")))
                }
            case .failure(let error):
                result(.failure(NetworkError(msg: error.localizedDescription)))
            }
        }
    }
}
