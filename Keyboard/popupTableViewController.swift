//
//  popupTableViewController.swift
//  TastyImitationKeyboard
//
//  Created by Benjamin Katz on 11/3/16.
//  Copyright © 2016 Apple. All rights reserved.
//

import Foundation
import UIKit
class PopUpTableViewController:  UIViewController,UITableViewDelegate, UITableViewDataSource {

    let tableView = UITableView()
    var selector: UIButton?
    var items: [String] = ["Default", "Aero", "Family", "Friends"]
    
    init(selector: UIButton)
    {
        super.init(nibName: nil, bundle: nil)
        self.selector = selector
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        tableView.rowHeight = 40
        let height = items.count * Int(self.tableView.rowHeight)

        tableView.frame         =   CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: 300, height: height))
        self.preferredContentSize = CGSize(width: 300, height: height)
        tableView.delegate      =   self
        tableView.dataSource    =   self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        self.view.addSubview(tableView)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
        let text = self.items[indexPath.row]
        cell.textLabel?.text = text
        if text == selector?.titleLabel!.text! {
            cell.backgroundColor = UIColor.init(red: 242/255, green: 193/255, blue: 133/255, alpha: 1)
        }
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let newSelection = self.items[indexPath.row]
        selector?.setTitle(newSelection, for: UIControlState())
        UserDefaults.standard.register(defaults: ["profile": newSelection])
        self.dismiss(animated: true, completion: { _ in })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

