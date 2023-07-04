# TapRouter

## 支持环境

`iOS 12`
`swift 5.0+`

## 安装到自己的项目

TapEditor 已经上传到私有 [CocoaPods](https://git.gametaptap.com/ios/universal/specs). 想要安装这个项目, 先在你的 Podfile 文件中添加私有库源

```
source 'git@git.gametaptap.com:ios/universal/specs.git'
```

然后添加这行代码：

```ruby
pod 'TapEditor'
```

最后执行 `pod install`即可

如果需要升级此库，请执行：

```ruby
pod install --repo-update
```

## Router 的调用

Router 的快速调用非常简单：

```swift

Router.push(uri)
Router.present(uri)

```
跳转也支持参数配置：

```swift
public class func push(_ url: String,
                params: [String: Any]? = [:],
                completion: ((_ result: Any?) -> Void)? = nil,
                animated: Bool = true, navigation: TapRouterNavigationProtocol? = nil) { }

```
其中 params 参数 会和 url 中的参数合并为一个参数，供路由接收方处理。

## Router 的注册

路由接收方需要注册路由以进行处理：

```swift

RouterBase.registerWithHandler(url) { routerParameters in
                guard let vc = UIViewController()
                Router.route(vc, params: vc.tapParams.merge(with: routerParameters))
            }

```
推荐将路由参数放入 tapParams 参数中由 vc 处理。


## Router 打开 URL

打开 URL 可以调用：

```swift
RouterBase.open(""）

```
Router.push & Router.present 最终调用的也是 RouterBase.open 方法。

RouterBase.open 过程中有重定向、白名单、自定义跳转控制器等能力：

### Router 的重定向

重定向可以让业务对路由进行二次处理， 设置 Router.redirect 并且实现 RouterRedirectProtocol  可以实现路由的重定向

```swift

public protocol RouterRedirectProtocol {
    func redirect(url: String, userInfo: [String: Any])
}

```

### Router 的域名白名单

在项目合适的地方设置域名白名单:

```swift

RouterBase.shared.excludeListStrategyRouter = ["aaa", "bbb.com"]

```

位于域名白名单之外的 url 会默认用 Safari 打开。

### Router 的自定义跳转控制器

设置 Router.presentProtocol 并且实现 RouterPresentProtocol 可以实现跳转前指定导航控制器。

```swift

public protocol RouterPresentProtocol {
    /// 跳转前指定导航控制器跳转
    func getNavigationController(turnTupe: Router.TurnType, vc: UIViewController) -> UINavigationController
}

```
比如可以在 present 前，把所有的 NavigationController 的 modalPresentationStyle 统一改为 .fullScreen 。


## 模块级别 hook 路由的能力
每个模块都可以 hook 路由的生命周期，以达到定制化的目的

```swift

RouterBase.shared.register(routeHooker: ModuleHooker())


struct ModuleHooker: RouteHooker {
    // ....
}

```
可以通过 RouteHooker 中的 canRoute 协议方法来决定路由是够能够继续执行。

也可以 在 willRoute & didRoute 方法中进行一些路由的定制化。

## Author

MExuanHe, zhangxuanhe@xd.com

## License

TapRouter is available under the MIT license. See the LICENSE file for more info.
