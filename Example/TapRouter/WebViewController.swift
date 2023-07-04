//
//  WebViewController.swift
//  TapRouter_Example
//
//  Created by 李翰阳 on 2022/11/1.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.backgroundColor = UIColor.white
        
        view.addSubview(webView)
        webView.frame = view.bounds
        
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    let url: URL
    
    init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var webView: WKWebView = {
        let userController = WKUserContentController()
        let config = WKWebViewConfiguration()
        config.userContentController = userController
        let webView = WKWebView(frame: CGRect.zero, configuration: config)
        webView.isOpaque = false
        return webView
    }()
}
