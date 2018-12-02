//
//  APIClient.swift
//  AlamofireOAuth1
//
//  Created by Cencen Zheng on 2018/8/24.
//

import Alamofire
import AlamofireOAuth1

public class APIClient: RequestAdapter {
    public var sessionManager: SessionManager
    
    fileprivate let oauth1: OAuth1
    fileprivate let tokenId: String
    fileprivate let errorHandler: (Error) -> Void = { (error) in
        print(error.localizedDescription)
    }
    
    init(with oauth: OAuth1) {
        self.oauth1 = OAuth1(with: oauth)
        self.tokenId = oauth1.key
        self.sessionManager = SessionManager()
        self.sessionManager.adapter = self
    }
    
    open func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        let accessToken = try OAuth1TokenStore.shared.retrieveCurrentToken(with: tokenId)
        return try oauth1.adaptRequest(urlRequest, with: accessToken)
    }
    
    public func request(_ router: URLRequestConvertible) -> DataRequest {
        return sessionManager.request(router)
    }
    
    public func authorize(with authorizeURLOpener: URLOpening? = nil, completion: @escaping () -> Void) {
        if let opener = authorizeURLOpener {
            oauth1.authorizeURLOpener = opener
        }
        oauth1.fetchAccessToken(accessMethod: .get, successHandler: { (accessToken) in
            OAuth1TokenStore.shared.saveToken(accessToken, with: self.tokenId)
            completion()
        }, failureHandler: errorHandler)
    }
}

