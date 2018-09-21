//
//  Router.swift
//  AlamofireOAuth1_Example
//
//  Created by Cencen Zheng on 2018/9/17.
//  Copyright (c) 2018 Cencen Zheng. All rights reserved.
//

import Foundation
import Alamofire

enum Router: URLRequestConvertible {
    case fanfou
    case twitter
    
    var baseUrl: String {
        get {
            switch self {
            case .fanfou:
                return "http://api.fanfou.com/"
            case .twitter:
                return "https://api.twitter.com/1.1/"
            }
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        let result: (path: String, parameters: Parameters?, method: HTTPMethod) = {
            switch self {
            case .fanfou:
                return ("statuses/home_timeline.json", nil, .get)
            case .twitter:
                return ("statuses/user_timeline.json", nil, .get)
            }
        }()
        
        let url = try baseUrl.asURL()
        let urlRequest = try URLRequest(url: url.appendingPathComponent(result.path),
                                        method: result.method)
        return try URLEncoding.default.encode(urlRequest, with: result.parameters)
    }
}
