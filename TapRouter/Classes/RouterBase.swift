//
//  TapRouter.swift
//  TapTap
//
//  Created by ^-^ on 2021/9/9.
//

import UIKit

/**
 *  routerParameters 里内置的几个参数会用到上面定义的 string
 */
public typealias TapRouterHandler = (_ routerParameters: [String: Any]?) -> Void

/**
 *  需要返回一个 object，配合 objectForURL: 使用
 */
public typealias TapRouterObjectHandler = (_ routerParameters: [String: Any]?) -> Any?

public typealias TapURLConvert = (_ url: String) -> [String: Any]?

public class RouterBase {
    public static let tapRouterParameterCompletion = "tapRouterParameterCompletion"
    public static let tapRouterParameterOriginUrl = "tapRouterParameterOriginUrl"
    public let tapRouterWildcardCharacter = "~"
    
    private let specialCharacters = "/?&."
    
    public static let shared = RouterBase()
    
    public var urlConvertMap = [String: TapURLConvert]()
    private static let schemes = ["http", "https", "tapglobal"]
    
    private var routeHookers: [RouteHooker] = []
    
    private var enableRouteHookers: [RouteHooker] {
        routeHookers.filter { $0.enable }
    }
    
    /**
     *  保存了所有已注册的 URL
     *  结构类似 ["beauty": [":id": ["_", 闭包]]]
     */
    public lazy var routes = NSMutableDictionary()
    
    /// 白名单
    public var excludeListStrategyRouter = [String]()
    
    public func register(routeHooker: RouteHooker) {
        guard !routeHookers.contains(where: { $0.hookId == routeHooker.hookId }) else {
            assertionFailure("不能注册相同的 RouteHooker")
            return
        }
        
        routeHookers.append(routeHooker)
    }
    
    /// 注册 URLPattern 对应的 Handler，在 handler 中可以初始化 VC，然后对 VC 做各种操作
    ///
    /// - Parameters:
    ///   - URLPattern: 带上 scheme，如 mgj://beauty/:id
    ///   - handler: 该 闭包 会传一个字典，包含了注册的 URL 中对应的变量。假如注册的 URL 为 mgj://beauty/:id 那么，就会传一个 @{@"id": 4} 这样的字典过来
    public class func registerWithHandler(_ urlPattern: String, _ toHandler: TapRouterHandler?) {
        shared.add(urlPattern, toHandler)
    }
    
    /// 注册 URLPattern 对应的 ObjectHandler，需要返回一个 object 给调用方
    ///
    /// - Parameters:
    ///   - urlPattern: 带上 scheme，如 mgj://beauty/:id
    ///   - toObjectHandler: 该 block 会传一个字典，包含了注册的 URL 中对应的变量。
    ///                      假如注册的 URL 为 mgj://beauty/:id 那么，就会传一个 @{@"id": 4} 这样的字典过来
    ///                      自带的 key 为 @"url" 和 @"completion" (如果有的话)
    public class func registerWithObjectHandler(_ urlPattern: String, toObjectHandler: TapRouterObjectHandler?) {
        shared.add(urlPattern, toObjectHandler)
    }
    
    /// 取消注册某个 URL Pattern
    ///
    /// - Parameter urlPattern: URLPattern
    public class func deregister(_ urlPattern: String) {
        TapRouterKit.remove(urlPattern, routes: shared.routes, character: shared.tapRouterWildcardCharacter)
    }
    
    /// 打开此 URL，带上附加信息，同时当操作完成时，执行额外的代码
    ///
    /// - Parameters:
    ///   - _url: 带 Scheme 的 URL，如 mgj://beauty/4
    ///   - userInfo: 附加参数
    ///   - completion: URL 处理完成后的 callback，完成的判定跟具体的业务相关
    public class func open(_ url: String, _ userInfo: [String: Any]? = [:], _ completion: ((_ result: Any?) -> Void)? = nil, navigation: TapRouterNavigationProtocol? = nil) {
        
        // 进行 + 和 %20 的 encode 的转换
        var urlStrs = url.components(separatedBy: "?")
        if urlStrs.count > 1 {
            urlStrs[1] = urlStrs[1].replacingOccurrences(of: "+", with: "%20")
        }
        let url = urlStrs.joined(separator: "?")
        
        let urlName = TapRouterKit.routeKeyByUrl(url: url, urlConvertMap: shared.urlConvertMap) ?? url
        
        var info: [String: Any]? = [:]
        
        let map = TapRouterKit.routeParamsByUrl(url: url, urlConvertMap: shared.urlConvertMap) ?? [:]
        // 防止为 nil 时，解析出来的参数无法正常被传递
        let userInfo = userInfo ?? [:]
        info = userInfo.routerMerge(with: map)
        
        if let routerUrl = URL(string: url), schemes.contains(routerUrl.scheme ?? "") {
            // 不是白名单的URL 统一用safari打开
            if !RouterBase.shared.isVerifiedOfWhiteName(url: url), let openUrl = URL(string: url), UIApplication.shared.canOpenURL(openUrl) {
                return UIApplication.shared.open(openUrl, options: [:], completionHandler: nil)
            }
        }
                
        guard let urlString = urlName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let parameters = shared.extractParameters(urlString, false, userInfo: userInfo) else {
                return
        }
        
        for (key, value) in parameters {
            if Mirror(reflecting: value).subjectType is NSString.Type {
                if let value = value as? NSString {
                    parameters[key] = value.replacingOccurrences(of: "+", with: "%20").removingPercentEncoding
                }
            }
        }
        
        guard !parameters.allKeys.isEmpty else { return }
        
        shared.enableRouteHookers.forEach { $0.willRoute(url: url, params: userInfo) }
        
        let canRoute = shared.enableRouteHookers.reduce(into: true) { result, hooker in
            result = result && hooker.canRoute(url: url, params: userInfo)
        }
        
        guard canRoute else { return }
        
        if completion != nil {
            parameters[tapRouterParameterCompletion] = completion
        }
        parameters[tapRouterParameterOriginUrl] = url
        
        if let info = info {
            info.forEach { key, value in parameters[key] = value }
        }
        
        if navigation != nil {
            parameters["naviProtocol"] = navigation
        }
        if parameters["block"] != nil {
            let handler = parameters["block"] as? TapRouterHandler
            if handler != nil {
                parameters.removeObject(forKey: "block")
                handler?(parameters as? [String: Any])
            } else {
                let objectHandler = parameters["block"] as? TapRouterObjectHandler
                parameters.removeObject(forKey: "block")
                _ = objectHandler?(parameters as? [String: Any])
            }
        }
        
        shared.enableRouteHookers.forEach { $0.didRoute(url: url, params: userInfo) }
    }
    
    /// 是否可以打开URL
    ///
    /// - Parameter url: 带 Scheme，如 mgj://beauty/3
    /// - Returns: 返回 Bool 值
    public class func canOpen(url: String) -> Bool {
        (shared.extractParameters(url, false, userInfo: nil) != nil)
    }
    
    public class func canOpen(url: String, _ matchExactly: Bool) -> Bool {
        (shared.extractParameters(url, true, userInfo: nil) != nil)
    }
    
    /// 调用此方法来拼接 urlpattern 和 parameters
    ///
    /// #define Tap_ROUTE_BEAUTY @"beauty/:id"
    /// [TapRouter generateURLWithPattern:Tap_ROUTE_BEAUTY, @[@13]];
    ///
    /// - Parameters:
    ///   - pattern: url pattern 比如 @"beauty/:id"
    ///   - parameters: 一个数组，数量要跟 pattern 里的变量一致
    /// - Returns: 返回生成的URL String
    public class func generateURL(_ pattern: String, _ parameters: [String]) -> String? {
        var startIndexOfColon = 0
        
        var placeholders = [String]()
        
        for i in 0..<pattern.count {
            let character = "\((pattern as NSString).character(at: i))"
            if character == ":" {
                startIndexOfColon = i
            }
            
            if shared.specialCharacters.contains(character) && i > (startIndexOfColon + 1) && startIndexOfColon > 0 {
                let range = NSRange(location: startIndexOfColon, length: (i - startIndexOfColon))
                let placeholder = (pattern as NSString).substring(with: range)
                
                if !TapRouterKit.checkIfContains(placeholder, specialCharacters: shared.specialCharacters) {
                    placeholders.append(placeholder)
                    startIndexOfColon = 0
                }
            }
            
            if i == pattern.count - 1 && startIndexOfColon > 0 {
                let range = NSRange(location: startIndexOfColon, length: (i - startIndexOfColon + 1))
                let placeholder = (pattern as NSString).substring(with: range)
                
                if !TapRouterKit.checkIfContains(placeholder, specialCharacters: shared.specialCharacters) {
                    placeholders.append(placeholder)
                }
            }
        }
        
        var parsedResult = pattern
        for i in 0..<placeholders.count {
            let index = (parameters.count > i ? i : parameters.count - 1)
            parsedResult = parsedResult.replacingOccurrences(of: placeholders[i], with: parameters[index])
        }
        
        return parsedResult
    }
}

public extension RouterBase {
    func add(_ urlPattern: String, _ objectHandler: TapRouterObjectHandler?) {
        let subRoutes = add(urlPattern)
        if objectHandler != nil {
            subRoutes?["_"] = objectHandler
        }
    }
    
    func add(_ urlPattern: String, _ handler: TapRouterHandler?) {
        let subRoutes = add(urlPattern)
        if handler != nil {
            subRoutes?["_"] = handler
        }
    }
    
    func add(_ urlPattern: String) -> NSMutableDictionary? {
        guard let pathComponentsArr = TapRouterKit.pathComponents(urlPattern, character: tapRouterWildcardCharacter) else {
            return nil
        }
        
        var subRoutes = routes
        
        for component in pathComponentsArr {
            if subRoutes[component] == nil {
                subRoutes[component] = NSMutableDictionary()
            }
            
            if let subRoute = subRoutes[component] as? NSMutableDictionary {
                subRoutes = subRoute
            }
        }
        return subRoutes
    }
    
    func extractParameters(_ fromURL: String, _ matchExactly: Bool, userInfo: [String: Any]?) -> NSMutableDictionary? {

        let parameters = NSMutableDictionary()
        
        var subRoutes = routes
        guard let pathComponentsArr = TapRouterKit.pathComponents(fromURL, character: tapRouterWildcardCharacter) else {
            return nil
        }
        
        var found = false
        for pathComponent in pathComponentsArr {
            // 对 key 进行排序，这样可以把 ~ 放到最后
            let subRoutesKeys = subRoutes.allKeys.sorted { key1, key2 -> Bool in
                if let key1 = key1 as? String, let key2 = key2 as? String {
                    switch key1.compare(key2).rawValue {
                    case 1:
                        return true
                        
                    case 0, -1:
                        return false
                        
                    default:
                        return false
                    }
                } else {
                    return false
                }
            }
            
            if let subRoutesKeys = subRoutesKeys as? [String] {
                for key in subRoutesKeys {
                    if key == pathComponent || key == tapRouterWildcardCharacter {
                        found = true
                        if let dic = subRoutes[key] as? NSMutableDictionary {
                            subRoutes = dic
                        }
                        break
                    } else if key.hasPrefix(":") {
                        found = true
                        if let dic = subRoutes[key] as? NSMutableDictionary {
                            subRoutes = dic
                        }
                        var newKey = (key as NSString).substring(from: 1)
                        var newPathComponent = pathComponent
                        
                        // 再做一下特殊处理，比如 :id.html -> :id
                        if TapRouterKit.checkIfContains(key, specialCharacters: RouterBase.shared.specialCharacters) {
                            let specialCharacterSet = CharacterSet(charactersIn: specialCharacters)
                            guard let initRange = key.rangeOfCharacter(from: specialCharacterSet) else {
                                return nil
                            }
                            let range = TapRouterKit.nsRange(initRange, key)
                            if range.location != NSNotFound {
                                // 把 pathComponent 后面的部分也去掉
                                newKey = (newKey as NSString).substring(to: range.location - 1)
                                let suffixToStrip = (key as NSString).substring(from: range.location)
                                newPathComponent = (newPathComponent as NSString).replacingOccurrences(of: suffixToStrip, with: "")
                            }
                        }
                        parameters[newKey] = newPathComponent
                        break
                    } else if matchExactly {
                        found = false
                    }
                }
            }
        }
        
        if !found && (subRoutes["_"] == nil) {
            redirect(url: fromURL, userInfo: userInfo)
            return nil
        }
        
        // Extract Params From Query.
        guard let url = URL(string: fromURL), let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else {
            if subRoutes["_"] != nil {
                parameters["block"] = subRoutes["_"]
            }
            
            return parameters
        }
        
        for item in queryItems {
            parameters[item.name] = item.value
        }
        
        if subRoutes["_"] != nil {
            parameters["block"] = subRoutes["_"]
        }
        
        return parameters
    }
    
    func redirect(url: String, userInfo: [String: Any]?) {
        Router.redirect?.redirect(url: url, userInfo: userInfo ?? [:])
    }
    
}

public extension RouterBase {
    
    /// 验证是否是白名单的url
    /// - Parameter url: url
    /// - Returns: 验证结果
    func isVerifiedOfWhiteName(url: String) -> Bool {
        // taptap://taptap.com/app \ http://www.taptap.com/app/168332  print(url?.host,"===",url?.scheme)
        guard let url = URL(string: url), let scheme = url.scheme else {
            return false
        }
        
        for router in RouterBase.shared.excludeListStrategyRouter {
            if let routerUrl = URL(string: router),
               routerUrl.host == url.host,
               Self.schemes.contains(scheme) {
                return true
            }
        }
        return false
    }
    
    func registerURLToKeyConvertor(url: String, converter: @escaping TapURLConvert) {
        if url.count <= 0 {
            return debugPrint("当前URL为空")
        }
        
        urlConvertMap[url] = converter
    }
}
