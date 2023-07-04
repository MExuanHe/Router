//
//  RouteHooker.swift
//  TapRouter
//
//  Created by wzb on 2022/8/3.
//

import Foundation

/// 如果需要 hook router，实现这个协议
/// 这个协议是模块级别的，也就是说每个模块都可以实现一个来针对本模块的 router hook
public protocol RouteHooker {
    /// 是否启用这个 Hooker，默认 true
    var enable: Bool { get }
    
    /// 为了避免重复传入相同的 Hooker，需要给每个 Hooker 一个 id，必传，如果和其他模块相同会被过滤掉
    var hookId: String { get }
    
    /// 即将执行路由时执行
    /// - Parameters:
    ///   - url: route 的 url
    ///   - params: route 参数
    func willRoute(url: String, params: [String: Any]?)
    
    /// TapRouter 执行路由前会先通过这个方法来检查是否可以执行
    /// - Parameters:
    ///   - url: route 的 url
    ///   - params: route 参数
    /// - Returns: 返回 true 使用 TapRouter 执行，返回 false 不使用 TapRouter 执行，默认值 true
    func canRoute(url: String, params: [String: Any]?) -> Bool
    
    /// 执行路由完成时执行
    /// - Parameters:
    ///   - url: route 的 url
    ///   - params: route 参数
    func didRoute(url: String, params: [String: Any]?)
}

public extension RouteHooker {
    var enable: Bool { true }
    func canRoute(url: String, params: [String: Any]?) -> Bool { true }
    func willRoute(url: String, params: [String: Any]?) {}
    func didRoute(url: String, params: [String: Any]?) {}
}
