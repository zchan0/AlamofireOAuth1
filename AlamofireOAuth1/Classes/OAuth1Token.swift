//
//  OAuth1Token.swift
//  AlamofireOAuth1
//
//  Created by Cencen Zheng on 2018/8/24.
//

import Foundation
import KeychainAccess

public struct OAuth1Token: Codable {
    var token: String           // "oauth_token"
    var tokenSecret: String     // "oauth_token_secret"
    var verifierCode: String?   // "oauth_verifier"
    
    init() {
        self.token = ""
        self.tokenSecret = ""
    }
    
    init?(query: String) {
        self.token = ""
        self.tokenSecret = ""
        
        if query.count == 0 {
            return nil
        }
        
        let parameters = self.parametersFromQueryString(query)
        
        if let confirmed = parameters["oauth_callback_confirmed"], confirmed != "true" {
            print("Error: value for oauth_callback_confirmed is not true")
            return nil
        }
        
        guard let oauthToken = parameters["oauth_token"] else {
            print("Error: cannot find oauth_token field in \(query)")
            return nil
        }
        self.token = oauthToken.safeStringByRemovingPercentEncoding
        
        if let oauthTokenSecret = parameters["oauth_token_secret"] {
            self.tokenSecret = oauthTokenSecret.safeStringByRemovingPercentEncoding
        }
        
        if let verifier = parameters["oauth_verifier"] {
            self.verifierCode = verifier.safeStringByRemovingPercentEncoding
        }
    }
    
    private func parametersFromQueryString(_ query: String) -> [String: String] {
        let scanner = Scanner(string: query)
        
        var key: NSString?
        var value: NSString?
        var parameters = [String: String]()
        
        while !scanner.isAtEnd {
            key = nil
            scanner.scanUpTo("=", into: &key)
            scanner.scanString("=", into: nil)
            
            value = nil
            scanner.scanUpTo("&", into: &value)
            scanner.scanString("&", into: nil)
            
            if let key = key as String?, let value = value as String? {
                parameters.updateValue(value, forKey: key)
            }
        }
        
        return parameters
    }
}

public class OAuth1TokenStore {
    enum OAuth1TokenStoreError: Error {
        case noCurrentToken
    }
    
    public static let shared = OAuth1TokenStore()
    fileprivate var keychain: Keychain
    
    private init() {
        self.keychain = Keychain()  // use bundleId as service by default
    }
    
    public func saveToken(_ token: OAuth1Token, with identifier: String) {
        guard let tokenData = try? JSONEncoder().encode(token) else { return }
        keychain[data: identifier] = tokenData
    }
    
    public func retrieveCurrentToken(with identifier: String) throws -> OAuth1Token {
        guard let tokenData = keychain[data: identifier] else {
            throw OAuth1TokenStoreError.noCurrentToken
        }
        return try JSONDecoder().decode(OAuth1Token.self, from: tokenData)
    }
    
    public func deleteToken(with identifier: String) throws {
        try keychain.remove(identifier)
    }
}
