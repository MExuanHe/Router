//
//  ViewController.swift
//  TapRouter
//
//  Created by MExuanHe on 07/05/2022.
//  Copyright (c) 2022 MExuanHe. All rights reserved.
//

import UIKit
import TapRouter

class TableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "TapRouter Guides"
        // 注册路由
        RouterManager.registerRouter()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    // MARK: - properties
    let classesArr: [ExampleModel] = [ExampleModel.init(displayText: "TapRouter Push",
                                                        routerString: .push),
                                      ExampleModel.init(displayText: "TapRouter Present",
                                                        routerString: .present),
                                      ExampleModel.init(displayText: "TapRouter url",
                                                        routerString: .url),
                                      ExampleModel.init(displayText: "TapRouter White List url",
                                                        routerString: .whiteListUrl),
                                      ExampleModel.init(displayText: "TapRouter hook canRoute",
                                                        routerString: .redirect)]
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return classesArr.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = classesArr[indexPath.row].displayText
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        88
    }

    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = classesArr[indexPath.row]
        if model.routerString == .present {
            Router.present(model.routerString.rawValue)
        } else if model.routerString == .url || model.routerString == .whiteListUrl   {
            Router.push(model.routerString.rawValue)
        } else {
            Router.push(model.routerString.rawValue)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

struct ExampleModel {
    var displayText: String
    var routerString: RouterStr
    
    enum RouterStr: String {
        case push = "TapRouterPush"
        case present = "TapRouterPresent"
        case url = "http://www.baidu.com"
        case whiteListUrl = "https://www.taptap.cn/"
        case redirect = "TapRouter_hook_canRoute"
    }
}
