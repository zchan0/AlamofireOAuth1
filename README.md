# AlamofireOAuth1

[![CI Status](https://img.shields.io/travis/zchan0/AlamofireOAuth1.svg?style=flat)](https://travis-ci.org/zchan0/AlamofireOAuth1)
[![Version](https://img.shields.io/cocoapods/v/AlamofireOAuth1.svg?style=flat)](https://cocoapods.org/pods/AlamofireOAuth1)
[![License](https://img.shields.io/cocoapods/l/AlamofireOAuth1.svg?style=flat)](https://cocoapods.org/pods/AlamofireOAuth1)
[![Platform](https://img.shields.io/cocoapods/p/AlamofireOAuth1.svg?style=flat)](https://cocoapods.org/pods/AlamofireOAuth1)

AlamofireOAuth1 is an OAuth1 library based on Alamofire for iOS.

## Why  

You don't have much choices for OAuth1 library based on Swift, [OAuthSwift](https://github.com/OAuthSwift/OAuthSwift) maybe the best(and the only) one. However, it's kind of huge(if you just need OAuth1 or OAuth 2). Moreover, you have to call `oauthswift.client` to make a signed request(while you have already had a HTTPClient based on [Alamofire](https://github.com/Alamofire/Alamofire)).

## Usage

### Fetch Access Token 

```swift
// create an instance directly
let oauth1 = OAuth1(key: "********",
secret: "********",
requestTokenUrl: "http://fanfou.com/oauth/request_token",
authorizeUrl: "http://fanfou.com/oauth/authorize",
accessTokenUrl: "http://fanfou.com/oauth/access_token",
callbackUrl: "alamofire-oauth1://callback")

// or instantiate with OAuth1Settings(see OAuth1Settings.swift.example)
let oauth1 = OAuth1()

// by default the authorized URL is opened in Safari
// you can make a SafariOpenURLHandler to use the SFSafariViewController
// the idea is inspired by OAuthSwift
let handler = SafariOpenURLHandler(viewController: self)
oauth1.authorizeURLHandler = handler

// fetch access token
oauth1.fetchAccessToken(accessMethod: .get, successHandler: { (accessToken) in
// handle with accessToken
}, failureHandler: errorHandler)
```

Don't forget to register your application to launch from a custom URL scheme. In this case, the callback url is `alamofire-oauth1://callback`.

Handle the custom URL scheme on iOS with `handleCallback`:

```swift
func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
if url.host == "alamofire-oauth1", url.path.contains("callback") {
OAuth1.handleCallback(callbackURL: url)
}
return true
}
```

### Persist Access Token 

```swift
// OAuth1TokenStore is built on the top of KeychainAccess

// save token
oauth1.fetchAccessToken(accessMethod: .get, successHandler: { (accessToken) in
OAuth1TokenStore.shared.saveToken(accessToken, withIdentifier: self.tokenId)
}, failureHandler: errorHandler)

// retrieve token
let accessToken: OAuth1Token = try OAuth1TokenStore.shared.retrieveCurrentToken(withIdentifier: tokenId)
```

### Make Verified Requests 

>  `RequestAdapter` is a new feature in Alamofire 4. It allows each `Request` made on a `SessionManager` to be inspected and adapted before being created, making it easy to append an `Authorization` header to requests.

- Authorize and request with`APIClient` :

```swift
// create a Router 
// see Routing Requests: https://github.com/Alamofire/Alamofire/blob/master/Documentation/AdvancedUsage.md#routing-requests
enum Router: URLRequestConvertible {
case fanfou
case twitter

func asURLRequest() throws -> URLRequest {
    return ...
}
}
```

```swift
// APClient has adopted RequestAdapter. 

func testTwitter() {
    let oauth1 = OAuth1(key: "YOUR-TWITTER-CONSUMER-KEY",
    secret: "YOUR-TWITTER-CONSUMER-SECRET",
    requestTokenUrl: "https://api.twitter.com/oauth/request_token",
    authorizeUrl: "https://api.twitter.com/oauth/authorize",
    accessTokenUrl: "https://api.twitter.com/oauth/access_token",
    callbackUrl: "https://alamofireoauth1redirect.herokuapp.com/")
    let client = APIClient(with: oauth1)
    client.authorize(with: SafariURLOpener(viewController: self)) {
        client.request(Router.twitter).validate().responseJSON(completionHandler: { (response) in
            debugPrint(response.result)
        })
    }
}
```

- Implement your adapter with `adaptRequest:withAccessToken` function

```swift
open func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
    let accessToken = try OAuth1TokenStore.shared.retrieveCurrentToken(withIdentifier: tokenId)
    return try oauth1.adaptRequest(urlRequest, withAccessToken: accessToken)
}
```

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first. [ViewController.swift](https://github.com/zchan0/AlamofireOAuth1/blob/master/Example/AlamofireOAuth1/ViewController.swift) shows the process of authenticating against [Twitter](https://developer.twitter.com/en/docs/basics/authentication/overview/oauth) and Fanfou([饭否](http://fanfou.com/apps)).

## Installation

AlamofireOAuth1 is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'AlamofireOAuth1'
```

## License

AlamofireOAuth1 is available under the MIT license. See the LICENSE file for more info.
