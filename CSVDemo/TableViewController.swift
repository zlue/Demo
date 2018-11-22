//
//  TableViewController.swift
//  CSVDemo
//
//  Created by lue on 2018/11/20.
//  Copyright © 2018年 e lu. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = false
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        tableView.header = LueRefreshNormalHeader { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                self?.tableView.header?.endRefreshing()
            })
        }
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 10
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        return cell
    }
    
    deinit {
        debugPrint("table view controller")
    }
}

