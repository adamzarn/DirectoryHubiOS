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
    let defaults = UserDefaults.standard
    
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var submitButton: UIBarButtonItem!
    
    var groupToEdit: Group?
    var list: [[Member]] = [[],[]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        submitButton.tintColor = GlobalFunctions.shared.themeColor()
        self.navigationController?.navigationBar.barTintColor = GlobalFunctions.shared.themeColor()
        self.navigationController?.navigationBar.isTranslucent = false
        toolbar.isTranslucent = false
        
        myTableView.setEditing(true, animated: true)
        
        var admins = groupToEdit?.admins
        let users = groupToEdit?.users
        
        let adminNames = groupToEdit?.getAdminNames()
        
        var onlyUsers: [Member] = []
        
        for user in users! {
            if !(adminNames?.contains(user.name))! {
                onlyUsers.append(user)
            }
        }
        
        admins!.sort { $0.name < $1.name }
        onlyUsers.sort { $0.name < $1.name }
        
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
        let adminsHeader = "Administrators (\(list[0].count))"
        let membersHeader = "Members (\(list[1].count))"
        return [adminsHeader,membersHeader][section]
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
    
    @IBAction func submitButtonPressed(_ sender: Any) {
        FirebaseClient.shared.updateGroupRoles(groupUid: (groupToEdit?.uid)!, admins: list[0], users: list[1]) { (success) -> () in
            if let success = success {
                self.defaults.setValue(true, forKey: "shouldUpdateGroups")
                self.displayAlert(title: "Success", message: "This list has been successfully updated.")
            } else {
                self.displayAlert(title: "Error", message: "This list has been successfully updated.")
            }
            
        }
    }
        
    func displayAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: false, completion: nil)
    }
    
}
