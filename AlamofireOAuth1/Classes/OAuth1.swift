//
//  OAuth1.swift
//  AlamofireOAuth1
//
//  Created by Cencen Zheng on 2018/8/24.
//

import Alamofire
import SafariServices

public enum OAuthSignatureMethod: String {
    case HMAC_SHA1 = "HMAC-SHA1"
    case PLAINTEXT = "PLAINTEXT"
}

public enum OAuth1Error: Error {
    case noToken
    case noBaseString
    case invalidSignature
}

public class OAuth1 {
    public typealias SuccessHandler = (OAuth1Token) -> Void
    public typealias FailureHandler = (Error) -> Void
    
    public var signatureMethod: OAuthSignatureMethod
    public var authorizeURLOpener: URLOpening
    
    fileprivate(set) public var key: String
    fileprivate var secret: String
    fileprivate var token: String
    fileprivate var tokenSecret: String
    fileprivate var authorizeUrl: String
    fileprivate var accessTokenUrl: String
    fileprivate var requestTokenUrl: String
    fileprivate var callbackUrl:String
    fileprivate var callbackObserver: Any?
    fileprivate let version: String = "1.0"
    
    
    public init(key: String, secret: String, requestTokenUrl: String, authorizeUrl: String, accessTokenUrl: String, callbackUrl: String? = nil) {
        self.key = key
        self.secret = secret
        self.token = ""
        self.tokenSecret = ""
        self.authorizeUrl = authorizeUrl
        self.accessTokenUrl = accessTokenUrl
        self.requestTokenUrl = requestTokenUrl
        self.callbackUrl = "oob"
        self.signatureMethod = .HMAC_SHA1
        self.authorizeURLOpener = BrowserURLOpener()
        
        if let cb = callbackUrl {
            self.callbackUrl = cb
        }
    }
    
    public convenience init(with oauth: OAuth1) {
        self.init(key: oauth.key,
                  secret: oauth.secret,
                  requestTokenUrl: oauth.requestTokenUrl,
                  authorizeUrl: oauth.authorizeUrl,
                  accessTokenUrl: oauth.accessTokenUrl,
                  callbackUrl: oauth.callbackUrl)
    }
    
    public class func handleCallback(callbackURL: URL) {
        let notification = Notification(name: URLOpeningNotification.CallbackName, object: nil, userInfo: [URLOpeningNotification.CallbackUrlKey: callbackURL])
        NotificationCenter.default.post(notification)
    }
    
    public func fetchAccessToken(accessMethod: HTTPMethod, successHandler: @escaping SuccessHandler, failureHandler: @escaping FailureHandler) {
        self.acquireUnauthorizedRequestToken(with: accessMethod, successHandler: { (requestToken) in
            self.acquireAuthorizedRequestToken(with: self.callbackUrl, requestToken: requestToken, successHandler: { (requestToken) in
                self.acquireAccessToken(with: requestToken, accessMethod: accessMethod, successHandler: { (accessToken) in
                    successHandler(accessToken)
                }, failureHandler: failureHandler)
            })
        }, failureHandler: failureHandler)
    }
    
    public func adaptRequest(_ urlRequest: URLRequest, with accessToken: OAuth1Token) throws -> URLRequest {
        token = accessToken.token
        tokenSecret = accessToken.tokenSecret
        
        var parameters = OAuth1Parameters()
        
        guard let urlString = urlRequest.url?.absoluteString,
            let httpMethodString = urlRequest.httpMethod,
            let httpMethod = HTTPMethod(rawValue: httpMethodString),
            let baseString = constructBaseString(withBaseUrl: urlString, accessMethod: httpMethod, parameters: parameters)
            else {
                throw OAuth1Error.noBaseString
        }
        
        guard let signature = generateSignature(text: baseString).percentEncoding() else {
            throw OAuth1Error.invalidSignature
        }
        
        parameters["oauth_signature"] = signature
        
        let query = parameters.sorted(by: <).map({ $0 + "=" + $1 }).joined(separator: ",")
        if let _ = urlRequest.url?.absoluteString {
            var urlRequest = urlRequest
            urlRequest.setValue("OAuth " + query, forHTTPHeaderField: "Authorization")
            urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
            return urlRequest
        }
        
        return urlRequest
    }
}

// MARK: - OAuth1 flow
extension OAuth1 {
    // 1. acquire unauthorized request token
    private func acquireUnauthorizedRequestToken(
        with accessMethod: HTTPMethod,
        successHandler: @escaping SuccessHandler,
        failureHandler: @escaping FailureHandler)
    {
        var parameters = OAuth1Parameters()
        guard let baseString = constructBaseString(withBaseUrl: requestTokenUrl, accessMethod: accessMethod, parameters: parameters) else {
            print("Error: cannot construct base string")
            return
        }
        
        let signature = generateSignature(text: baseString)
        parameters["oauth_signature"] = signature
        
        Alamofire.request(requestTokenUrl, parameters: parameters).responseString { (response) in
            switch response.result {
            // statusCode within `200<..300`, and
            // the `Content-Type` header of the response matches the `Accept` header of the request
            case .success(let query):
                guard let token = OAuth1Token(query: query) else { return }
                successHandler(token)
            // if response.response.statusCode = 400/401, check https://oauth.net/core/1.0/#http_codes
            case .failure(let error):
                failureHandler(error)
            }
        }
    }
    
    // 2. acquire authorized request token
    private func acquireAuthorizedRequestToken(
        with callbackUrl: String,
        requestToken: OAuth1Token,
        successHandler: @escaping SuccessHandler)
    {
        token = requestToken.token
        tokenSecret = requestToken.tokenSecret
        
        var parameters = OAuth1Parameters()
        parameters["oauth_callback"] = callbackUrl
        
        self.observeCallback { (url) in
            guard let query = url.query else {
                print("Error: callbackURL query is nil")
                return
            }
            guard let authorizedToken = OAuth1Token(query: query) else { return }
            // Your application should verify that the token matches the request token received in step 1.
            // https://dev.twitter.com/web/sign-in/implementing
            guard self.token == authorizedToken.token else { return }
            
            successHandler(authorizedToken)
        }
        
        guard let url = URL(string: "\(authorizeUrl)?oauth_token=\(token)&oauth_callback=\(callbackUrl  )") else {
            print("Error: cannot convert authorizeUrl to URL")
            return
        }
        authorizeURLOpener.open(url, options: [:], completionHandler: nil)
    }
    
    // 3. acquire access token with authorized request token
    private func acquireAccessToken(
        with requestToken: OAuth1Token,
        accessMethod: HTTPMethod,
        successHandler: @escaping SuccessHandler,
        failureHandler: @escaping FailureHandler)
    {
        token = requestToken.token
        
        var parameters = OAuth1Parameters()
        
        guard let baseString = constructBaseString(withBaseUrl: accessTokenUrl, accessMethod: accessMethod, parameters: parameters) else {
            print("Error: cannot construct base string")
            return
        }
        
        let signature = generateSignature(text: baseString)
        parameters["oauth_signature"] = signature
        
        if let verifier = requestToken.verifierCode {
            parameters["oauth_verifier"] = verifier
        }
        
        Alamofire.request(accessTokenUrl, parameters: parameters).responseString { (response) in
            switch response.result {
            case .success(let query):
                guard let token = OAuth1Token(query: query) else { return }
                successHandler(token)
            case .failure(let error):
                failureHandler(error)
            }
        }
    }
    
    private func observeCallback(with callbackHandler: @escaping (URL) -> Void) {
        callbackObserver = NotificationCenter.default.addObserver(forName: URLOpeningNotification.CallbackName, object: nil, queue: OperationQueue.main, using: { [weak self] (notification) in
            self?.removeCallbackObserver()
            
            if let userInfo = notification.userInfo,
                let url = userInfo[URLOpeningNotification.CallbackUrlKey] as? URL {
                callbackHandler(url)
            }
        })
    }
    
    private func removeCallbackObserver() {
        if let observer = callbackObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

// MARK: - Helpers
extension OAuth1 {
    private func OAuth1Parameters() -> Dictionary<String, String> {
        var parameters = Dictionary<String, String>()
        parameters["oauth_version"] = version
        parameters["oauth_consumer_key"] = key
        parameters["oauth_token"] = token
        parameters["oauth_signature_method"] = signatureMethod.rawValue
        parameters["oauth_timestamp"] = generateTimestamp()
        parameters["oauth_nonce"] = generateNonce()
        return parameters
    }
    
    // construct Base String, see RFC 5849, https://tools.ietf.org/html/rfc5849#section-3.4.1.1
    private func constructBaseString(withBaseUrl baseUrl: String, accessMethod: HTTPMethod, parameters: [String: String]) -> String? {
        guard let encodedBaseUrl = baseUrl.percentEncoding() else {
            print("Error: cannot encode \(requestTokenUrl)")
            return nil
        }
        
        // [k1: v1, k2: v2, ...] => k1 = v1 & k2 = v2 &...
        let query = parameters.sorted(by: <).map({ $0 + "=" + $1 }).joined(separator: "&")
        guard let encodedQuery = query.percentEncoding() else {
            print("Error: cannot encode \(query)")
            return nil
        }
        
        let baseString = "\(accessMethod.rawValue)&\(encodedBaseUrl)&\(encodedQuery)"
        return baseString
    }
    
    private func generateSignature(text: String) -> String {
        var signature: String
        let key = "\(secret)&\(tokenSecret)"
        switch signatureMethod {
        case .HMAC_SHA1:
            // sign with HMAC-SHA1, https://tools.ietf.org/html/rfc5849#section-3.4.2
            signature = text.hmacsha1(with: key)
        case .PLAINTEXT:
            signature = key
        }
        return signature
    }
    
    private func generateNonce() -> String {
        return UUID().uuidString
    }
    
    private func generateTimestamp() -> String {
        return String(Int64(Date().timeIntervalSince1970))
    }
}
