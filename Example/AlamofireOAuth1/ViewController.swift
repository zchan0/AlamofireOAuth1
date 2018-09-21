//
//  ViewController.swift
//  AlamofireOAuth1
//
//  Created by Cencen Zheng on 08/24/2018.
//  Copyright (c) 2018 Cencen Zheng. All rights reserved.
//

import UIKit
import AlamofireOAuth1

class ViewController: UITableViewController {
    var services = [
        "Twitter",
        "Fanfou"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Service Provider"
    }
}

// MARK: services

extension ViewController {
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
    
    func testFanfou() {
        let oauth1 = OAuth1(key: "YOUR-FANFOU-CONSUMER-KEY",
                            secret: "YOUR-FANFOU-CONSUMER-SECRET",
                            requestTokenUrl: "http://fanfou.com/oauth/request_token",
                            authorizeUrl: "http://fanfou.com/oauth/authorize",
                            accessTokenUrl: "http://fanfou.com/oauth/access_token",
                            callbackUrl: "alamofire-oauth1://alamofire-oauth1/callback")
        let client = APIClient(with: oauth1)
        client.authorize {
            client.request(Router.fanfou).validate().responseJSON(completionHandler: { (response) in
                debugPrint(response.result)
            })
        }
    }
}

// MARK: Table

extension ViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return services.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        let service = services[indexPath.row]
        cell.textLabel?.text = service
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            testTwitter()
        case 1:
            testFanfou()
        default:
            break;
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }
}
