//
//  TapRouterViewController.swift
//  TapRouter_Example
//
//  Created by 李翰阳 on 2022/11/1.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit

class TapRouterViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .random
    }
}

extension UIColor {
    static var random: UIColor {
        return UIColor(red: .random(in: 0...1),
                       green: .random(in: 0...1),
                       blue: .random(in: 0...1),
                       alpha: 1.0)
    }
}
