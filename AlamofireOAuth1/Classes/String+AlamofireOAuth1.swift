//
//  String+AlamofireOAuth1.swift
//  AlamofireOAuth1
//
//  Created by Cencen Zheng on 2018/8/24.
//

import Foundation
import CommonCrypto

public extension String {
    var safeStringByRemovingPercentEncoding: String {
        return self.removingPercentEncoding ?? self
    }
    
    // percent encoding, see RFC 5849, https://tools.ietf.org/html/rfc5849#section-3.6
    func percentEncoding() -> String? {
        // encoded as UTF-8 octets
        guard let data = self.data(using: .utf8) else {
            print("Error: cannot get utf8 data with \(self)")
            return nil
        }
        guard let utf8String = String(data: data, encoding: .utf8) else {
            print("Error: cannot convert data data to utf8 string")
            return nil
        }
        
        // escaped using the RFC3986 mechanism, https://tools.ietf.org/html/rfc3986#section-2.3
        // create custom character set, https://stackoverflow.com/a/32527940
        let allowedCharacterSet = NSMutableCharacterSet()
        allowedCharacterSet.formUnion(with: .alphanumerics)
        allowedCharacterSet.formUnion(with: .decimalDigits)
        allowedCharacterSet.addCharacters(in: "-._~")
        
        return utf8String.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet as CharacterSet)
    }
    
    // https://stackoverflow.com/a/48406753/9246748
    func hmacsha1(with key: String) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1), key, key.count, self, self.count, &digest)
        let data = Data(bytes: digest)
        return data.base64EncodedString(options: Data.Base64EncodingOptions.lineLength76Characters)
        //        hexadecimal format, https://tools.ietf.org/html/rfc3986#section-2.1
        //        return data.map { String(format: "%02hhx", $0) }.joined()
    }
}

