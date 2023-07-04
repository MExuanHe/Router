//
//  TapRouterKit.swift
//  TapTap
//
//  Created by ^-^ on 2022/7/4.
//

import UIKit

public protocol TapRouterNavigationProtocol {
    func routerNavigate(_ fromVC: UIViewController, toVC: UIViewController)
}

public struct TapRouterKit {
    
    /// 拆解URL中的参数
    /// - Parameter url: 路径
    /// - Returns: 字典
    public static func urlParams(url: String) -> [String: Any]? {
        let url = URL(string: url)
        var parm = [String: Any]()
        if let items: [URLQueryItem] = URLComponents(string: url?.absoluteString ?? "")?.queryItems {
            for obj in items {
                if let value = obj.value {
                    parm[obj.name] = value
                }
            }
        }
        return parm
    }
    
    public static func routeKeyByUrl(url: String, urlConvertMap: [String: TapURLConvert]) -> String? {
        if let dic = mapURLToKey(url: url, urlConvertMap: urlConvertMap) {
            return dic["key"] as? String
        }
        return nil
    }
    
    public static func routeParamsByUrl(url: String, urlConvertMap: [String: TapURLConvert]) -> [String: Any]? {
        if let dic = mapURLToKey(url: url, urlConvertMap: urlConvertMap), let value = dic["params"] as? [String: Any] {
            return value
        }
        return urlParams(url: url)
    }
    
    public static func mapURLToKey(url: String, urlConvertMap: [String: TapURLConvert]) -> [String: Any]? {
        if let urlConvert = mapURLToConvert(url: url, urlConvertMap: urlConvertMap) {
            return urlConvert(url)
        }
        return nil
    }
    
    public static func mapURLToConvert(url: String, urlConvertMap: [String: TapURLConvert]) -> TapURLConvert? {
        let url = URL(string: url)
        for keyUrl in urlConvertMap.keys {
            let keyurl = URL(string: keyUrl)
            if url?.host == keyurl?.host && url?.scheme == keyurl?.scheme {
                return urlConvertMap[keyUrl]
            }
        }
        return nil
    }
    
    public static func checkIfContains(_ specialCharacter: String, specialCharacters: String) -> Bool {
        let specialCharactersSet = CharacterSet(charactersIn: specialCharacters)
        guard let range = specialCharacter.rangeOfCharacter(from: specialCharactersSet) else {
            return false
        }
        return nsRange(range, specialCharacter).location != NSNotFound
    }
    
    public static func nsRange(_ fromRange: Range<String.Index>, _ specialCharacter: String) -> NSRange {
        NSRange(fromRange, in: specialCharacter)
    }
    
    public static func pathComponents(_ fromURL: String, character: String) -> [String]? {
        var url = fromURL as NSString
        var pathComponents = [String]()
        
        if url.range(of: "://").location != NSNotFound {
            let pathSegments = url.components(separatedBy: "://")
            // 如果 URL 包含协议，那么把协议作为第一个元素放进去
            pathComponents.append(pathSegments.first ?? "")
            
            // 如果只有协议，那么放一个占位符
            url = pathSegments.last as NSString? ?? ""
            if url.length == 0 {
                pathComponents.append(character)
            }
        }
        
        let urlString = url as String
        guard let pathComponentsArr = URL(string: urlString)?.pathComponents else {
            return pathComponents
        }
        
        for pathComponent in pathComponentsArr {
            if pathComponent == "/" {
                continue
            }
            
            if (pathComponent as NSString).substring(to: 1) == "?" {
                break
            }
            pathComponents.append(pathComponent)
        }
        
        return pathComponents
    }
    
    public static func remove(_ urlPattern: String, routes: NSMutableDictionary, character: String) {
        guard var pathComponentsArr = pathComponents(urlPattern, character: character) else {
            return
        }
        
        // 只删除该 pattern 的最后一级
        if pathComponentsArr.count >= 1 {
            // 假如 URLPattern 为 a/b/c, components 就是 @"a.b.c" 正好可以作为 KVC 的 key
            let components = pathComponentsArr.joined(separator: ".")
            guard var route = routes.value(forKeyPath: components) as? NSMutableDictionary else {
                return
            }
            
            if route.count >= 1 {
                let lastComponent = pathComponentsArr.last ?? ""
                pathComponentsArr.removeLast()
                
                // 有可能是根 key，这样就是 self.routes 了
                route = routes
                if pathComponentsArr.count > 0 {
                    let componentsWithoutLast = pathComponentsArr.joined(separator: ".")
                    if let dic = routes.value(forKeyPath: componentsWithoutLast) as? NSMutableDictionary {
                        route = dic
                    }
                    if let dic = routes.value(forKeyPath: componentsWithoutLast) as? NSMutableDictionary {
                        route = dic
                    }
                }
                route.removeObject(forKey: lastComponent)
            }
        }
    }
     
    /// 找到顶部导航控制器
    static func routerTopNavigationController() -> UINavigationController? {
        /// 找到目标控制器对应的导航控制器
        /// - Parameter root: 目标控制器
        func _findTopNav(from root: UIViewController) -> UINavigationController? {
            if let nav = root as? UINavigationController {
                return nav
            }
            if let nav = root.navigationController {
                return nav
            }
            if let presentingViewController = root.presentingViewController {
                if let nav = presentingViewController as? UINavigationController {
                    return nav
                }
                return _findTopNav(from: presentingViewController)
            }
            return nil
        }
        
        guard let topVC = routerTopViewController() else { return nil }
        return _findTopNav(from: topVC)
    }
    
    /// 找到顶部控制器
    static func routerTopViewController() -> UIViewController? {
        /// 找到顶部控制器
        /// - Parameter root: 根控制器
        func _findTopVC(from root: UIViewController) -> UIViewController? {
            if let root = root as? UINavigationController,
               let visibleViewController = root.viewControllers.last {
                return _findTopVC(from: visibleViewController)
            }
            if let root = root as? UITabBarController,
               let selectedViewController = root.selectedViewController {
                return _findTopVC(from: selectedViewController)
            }
            if let root = root.presentedViewController, !(root is UIAlertController) {
                return _findTopVC(from: root)
            }
            return root
        }
        
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController ?? UIApplication.shared.windows.first?.rootViewController else {
            return nil
        }
        return _findTopVC(from: rootViewController)
    }
}

public extension UIViewController {
    private struct VcStruct {
        static var navigator: TapRouterNavigationProtocol?
        static var tapParams: [String: Any]?
    }
    
    var navigator: TapRouterNavigationProtocol? {
        get {
            objc_getAssociatedObject(self, &VcStruct.navigator) as? TapRouterNavigationProtocol
        }
        set {
            objc_setAssociatedObject(self, &VcStruct.navigator, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var tapParams: [String: Any] {
        get {
            objc_getAssociatedObject(self, &VcStruct.tapParams) as? [String: Any] ?? [:]
        }
        set {
            objc_setAssociatedObject(self, &VcStruct.tapParams, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

public extension Dictionary {
    func routerMerge(with dictionary: Dictionary?) -> Dictionary {
        guard let dictionary = dictionary else {
            return self
        }

        var copy = self
        dictionary.forEach { copy.updateValue($1, forKey: $0) }
        return copy
    }
}
