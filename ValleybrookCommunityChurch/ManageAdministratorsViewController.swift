//
//  ManageAdministratorsViewController.swift
//  ValleybrookCommunityChurch
//
//  Created by Adam Zarn on 9/17/17.
//  Copyright © 2017 Adam Zarn. All rights reserved.
//

import UIKit

class ManageAdministratorsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var myTableView: UITableView!
    
    var groupToEdit: Group?
    var list: [[Member]] = [[],[]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.barTintColor = GlobalFunctions.shared.themeColor()
        self.navigationController?.navigationBar.isTranslucent = false
        
        myTableView.setEditing(true, animated: true)
        
        let admins = groupToEdit?.admins
        let users = groupToEdit?.users
        
        let adminNames = groupToEdit?.getAdminNames()
        
        var onlyUsers: [Member] = []
        
        for user in users! {
            if !(adminNames?.contains(user.name))! {
                onlyUsers.append(user)
            }
        }
        
        list[0] = admins!
        list[1] = onlyUsers
        
        myTableView.reloadData()
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        cell.textLabel?.text = list[indexPath.section][indexPath.row].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ["Administrators","Members"][section]
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 0 {
            if list[0].count == 1 {
                return false
            }
        }
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movingPerson = list[sourceIndexPath.section][sourceIndexPath.row]
        list[sourceIndexPath.section].remove(at: sourceIndexPath.row)
        list[destinationIndexPath.section].insert(movingPerson, at: destinationIndexPath.row)
        myTableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.none
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        if self.isMovingFromParentViewController {
            
            self.groupToEdit?.admins = list[0]
            self.groupToEdit?.users = list[1]
            
            let destinationVC = self.navigationController?.viewControllers[0] as! CreateGroupViewController
            destinationVC.groupToEdit = self.groupToEdit
        }
    }
    
}
