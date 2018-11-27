//
//  TableViewController.swift
//  CSVDemo
//
//  Created by lue on 2018/11/20.
//  Copyright © 2018年 e lu. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {

    var count = 10
    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = false
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "ba", style: .done, target: self, action: #selector(rightBarButtonItemAction(item:)))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "ba", style: .done, target: self, action: #selector(leftBarButtonItemAction(item:)))
        
        tableView.header = LueRefreshNormalHeader { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                self?.tableView.header?.endRefreshing()
                self?.count = 10
                self?.tableView.reloadData()
            })
        }
        tableView.footer = LueRefreshNormalFooter { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                self?.count += 2
                self?.tableView.reloadData()
                if self?.count ?? 0 > 20 {
                    self?.tableView.footer?.endRefreshingWithNoMoreData()
                }
                else {
                    self?.tableView.footer?.endRefreshing()
                }
            })
        }
    }
    
    @objc func rightBarButtonItemAction(item: UIBarButtonItem) {
        LuePopView.show(size: CGSize(width: 100, height: 100), atItem: .right, list: ["1", "2"]) { (text, index) in
            
        }
    }
    @objc func leftBarButtonItemAction(item: UIBarButtonItem) {
        LuePopView.show(size: CGSize(width: 100, height: 100), atItem: .left, list: ["1", "2"]) { (text, index) in
            
        }
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return count
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        cell.textLabel?.text = "\(indexPath.section)"
        return cell
    }
    
    deinit {
        debugPrint("table view controller")
    }
}

