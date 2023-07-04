//
//  TapRouterProxyNew.swift
//  TapTap
//
//  Created by ^-^ on 2021/9/10.
//

import UIKit

public protocol RouterProtocol {
    // 跳转是否带动画 默认: true
    var animation: Bool { get }
    // 跳转类型 默认: push
    var turnType: Router.TurnType { get }
    // 是否需要登录 默认: false
    var requiredLogin: Bool { get }
    // 检查 tapParams，为了解决 router 跳当前所在页面 tapParams 更新了的情况（如：首页跳转不同 tab）
    func checkParams()
}

public extension RouterProtocol {
    var animation: Bool { true }
    var turnType: Router.TurnType { .push }
    var requiredLogin: Bool { false }
    func checkParams() {}
}

public protocol RouterRedirectProtocol {
    func redirect(url: String, userInfo: [String: Any])
}

public protocol RouterPresentProtocol {
    /// 跳转前指定导航控制器跳转
    func getNavigationController(turnTupe: Router.TurnType, vc: UIViewController) -> UINavigationController
}

public extension Router {
    static var redirect: RouterRedirectProtocol?
    static var presentProtocol: RouterPresentProtocol?

    enum TurnType {
        case push, present
    }
}

public class Router {
        
    /// push 跳转
    /// - Parameters:
    ///   - url: 路径
    ///   - params: 扩展参数
    ///   - completion: URL 处理完成后的 callback，完成的判定跟具体的业务相关
    ///   - animated: 是否开启动画跳转，默认为true
    ///   - navigation: 自定义跳转 默认 nil
    public class func push(_ url: String,
                    params: [String: Any]? = [:],
                    completion: ((_ result: Any?) -> Void)? = nil,
                    animated: Bool = true, navigation: TapRouterNavigationProtocol? = nil) {
        let userInfo = params?.routerMerge(with: ["animated": animated, "turnType": TurnType.push]) as [String: Any]?
        RouterBase.open(url, userInfo, completion, navigation: navigation)
    }
    
    /// present 跳转
    /// - Parameters:
    ///   - url: 路径
    ///   - params: 扩展参数
    ///   - completion: URL 处理完成后的 callback，完成的判定跟具体的业务相关
    ///   - animated: 是否开启动画跳转，默认为true
    ///   - navigation: 自定义跳转 默认niu
    public class func present(_ url: String,
                       params: [String: Any]? = [:],
                       completion: ((_ result: Any?) -> Void)? = nil,
                       animated: Bool = true,
                       navigation: TapRouterNavigationProtocol? = nil) {
        let userInfo = params?.routerMerge(with: ["animated": animated, "turnType": TurnType.present]) as [String: Any]?
        RouterBase.open(url, userInfo, completion, navigation: navigation)
    }
    
    public class func registerURL(toKeyConvertor url: String, converter: @escaping TapURLConvert) {
        RouterBase.shared.registerURLToKeyConvertor(url: url, converter: converter)
    }
    
    /// 通过URL获取注册时的name
    /// - Parameter byURL: 路由
    /// - Returns: 注册路由时的Key
    public class func routeKey(byURL: String) -> String {
        TapRouterKit.routeKeyByUrl(url: byURL, urlConvertMap: RouterBase.shared.urlConvertMap) ?? ""
    }
    
    /// 通过URL 获取参数
    /// - Parameter byURL: url
    /// - Returns: 字典
    public class func routeParams(byURL: String) -> [AnyHashable: Any] {
        TapRouterKit.routeParamsByUrl(url: byURL, urlConvertMap: RouterBase.shared.urlConvertMap) ?? [:]
    }
    
    /// pop to controller
    /// - Parameters:
    ///   - deep: pop的深度，默认为0，即pop到上一个控制器。如果大于0，则pop到页面栈倒数第deep个控制器上
    ///   - animated: pop animate
    public class func pop(deep: Int = 0, animated: Bool = true) {
        guard deep > 0 else {
            TapRouterKit.routerTopNavigationController()?.popViewController(animated: animated)
            return
        }
        guard let nav = TapRouterKit.routerTopNavigationController() else {
            return
        }
        let deep = deep + 1
        if deep >= nav.viewControllers.count {
            TapRouterKit.routerTopNavigationController()?.popToRootViewController(animated: animated)
            return
        }
        let targetVc = nav.viewControllers[deep]
        TapRouterKit.routerTopNavigationController()?.popToViewController(targetVc, animated: animated)
    }
    
    /// dismiss to controller
    /// - Parameters:
    ///   - completion:  处理完成后的 callback
    ///   - animated: dismiss animate
    public class func dismiss(completion: (() -> Void)?, animated: Bool = true) {
        if let nav = TapRouterKit.routerTopNavigationController(), nav.viewControllers.count > 1 {
            pop(animated: animated)
            completion?()
        } else if let topVc = TapRouterKit.routerTopViewController() {
            topVc.dismiss(animated: animated, completion: completion)
        }
    }
    
    public static func route(_ toVC: UIViewController, params: [String: Any]?) {
        let fromVc = TapRouterKit.routerTopViewController()
        var animated = true
        var turnTupe: TurnType = .push
        if let rp = toVC as? RouterProtocol {
            animated = rp.animation
            turnTupe = rp.turnType
        }
        if let animation = params?["animated"] as? Bool {
            animated = animation
        }
        if let tType = params?["turnType"] as? Router.TurnType {
            turnTupe = tType
        }
        let navProtocol = params?["naviProtocol"] as? TapRouterNavigationProtocol
        
        // 移除无效参数
        var params = params
        params?["animated"] = nil
        params?["turnType"] = nil
        params?["naviProtocol"] = nil
        
        toVC.tapParams = params ?? [:]
        
        if let navProtocol = navProtocol {
            navProtocol.routerNavigate(fromVc ?? UIViewController(), toVC: toVC)
        } else {
            switch turnTupe {
            case .push:
                 fromVc?.navigationController?.pushViewController(toVC, animated: animated)

            case .present:
                guard let nav = Router.presentProtocol?.getNavigationController(turnTupe: turnTupe, vc: toVC) else {
                    let navigationController = UINavigationController(rootViewController: toVC)
                    navigationController.modalPresentationStyle = .fullScreen
                    fromVc?.present(navigationController, animated: animated)
                    return
                }
                fromVc?.present(nav, animated: animated, completion: nil)
            }
        }
    }
}
