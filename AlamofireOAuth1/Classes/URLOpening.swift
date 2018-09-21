//
//  URLOpening.swift
//  AlamofireOAuth1
//
//  Created by Cencen Zheng on 2018/8/24.
//

import UIKit
import SafariServices

struct URLOpeningNotification {
    static let CallbackName = Notification.Name(rawValue: "AlamofireOAuthCallbackNotificationName")
    static let CallbackUrlKey = "AlamofireOAuthCallbackNotificationURLKey"
}

public protocol URLOpening {
    func open(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey : Any], completionHandler: ((Bool) -> Void)?)
}

public class BrowserURLOpener: NSObject, URLOpening {
    public func open(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey : Any], completionHandler: ((Bool) -> Void)?) {
        UIApplication.shared.open(url, options: options, completionHandler: completionHandler)
    }
}

public class SafariURLOpener: NSObject, URLOpening {
    var viewController: UIViewController
    var observers = [String : Any]()
    
    var animated: Bool = true
    var presentCompletion: (() -> ())?
    var dismissCompletion: (() -> ())?
    
    public init(viewController: UIViewController) {
        self.viewController = viewController
        super.init()
    }
    
    public func open(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey : Any], completionHandler: ((Bool) -> Void)?) {
        let controller = SFSafariViewController(url: url)
        let key = UUID().uuidString
        
        observers[key] = NotificationCenter.default.addObserver(
            forName: URLOpeningNotification.CallbackName,
            object: nil,
            queue: OperationQueue.main) { notification in
                if let observer = self.observers[key] {
                    NotificationCenter.default.removeObserver(observer)
                    self.observers.removeValue(forKey: key)
                }
                DispatchQueue.main.async {
                    controller.dismiss(animated: self.animated, completion: self.dismissCompletion)
                }
        }
        
        DispatchQueue.main.async {
            self.viewController.present(controller, animated: self.animated, completion: self.presentCompletion)
        }
    }
}
