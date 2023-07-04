//
//  RouterManager.swift
//  TapRouter_Example
//
//  Created by 李翰阳 on 2022/11/1.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit
import TapRouter
import WebKit

struct RouterManager {
    
    static let shared = RouterManager()
    
    static func registerRouter() {
        RouterBase.shared.excludeListStrategyRouter = ["https://www.taptap.cn/",
                                                       "https://www.xd.com"]
        
        Router.redirect = RouterManager.shared
        Router.presentProtocol = RouterManager.shared
        
        RouterBase.shared.register(routeHooker: RouterManager.shared)
        
        
        register(urls: ExampleModel.RouterStr.push.rawValue,
                 ExampleModel.RouterStr.present.rawValue,
                 ExampleModel.RouterStr.redirect.rawValue) { _ in
            return nil
        }
        
        let urlStr = ExampleModel.RouterStr.whiteListUrl.rawValue
        RouterBase.registerWithHandler(urlStr) { routerParameters in
            if let url = URL(string: urlStr) {
                let webVC = WebViewController.init(url: url)
                Router.route(webVC, params:[:])
            }
        }
    }
        
    
    static func register(urls: String..., complete: @escaping (_ parameters: [String: Any]?) -> UIViewController?) {
        register(urls: urls, complete: complete)
    }
    
    static func register(urls: [String], complete: @escaping (_ parameters: [String: Any]?) -> UIViewController?) {
        for url in urls {
            RouterBase.registerWithHandler(url) { routerParameters in
                let vc = TapRouterViewController()
                Router.route(vc, params:[:])
            }
        }
    }
}

// MARK: - redirect 重定向
extension RouterManager: RouterRedirectProtocol {
    func redirect(url: String, userInfo: [String : Any]) {
        
    }
}

// MARK: - 自定义跳转控制器
extension RouterManager: RouterPresentProtocol {
    func getNavigationController(turnTupe: Router.TurnType, vc: UIViewController) -> UINavigationController {
        if let nav = vc.navigationController {
            nav.modalPresentationStyle = .fullScreen
            return nav
        }
        return UINavigationController()
    }
}

// MARK: - hook 路由的能力
extension RouterManager: RouteHooker {
    var hookId: String {
        "RouterManager"
    }
    
    func canRoute(url: String, params: [String: Any]?) -> Bool {
        if url.contains("canRoute") {
            let alert = UIAlertController(title: "", message: "路由被拦截！", preferredStyle: .alert)
            if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                rootVC.present(alert, animated: true, completion: nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    alert.dismiss(animated: true)
                }
                return false
            }
        }
        return true
    }
}
