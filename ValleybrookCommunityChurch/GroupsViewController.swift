//
//  GroupViewController.swift
//  ValleybrookCommunityChurch
//
//  Created by Adam Zarn on 9/13/17.
//  Copyright © 2017 Adam Zarn. All rights reserved.
//

import UIKit
import CoreData
import Contacts
import Alamofire
import AlamofireImage
import Firebase

class GroupsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UISearchBarDelegate, UISearchControllerDelegate {
    
    @IBOutlet weak var aiv: UIActivityIndicatorView!
    @IBOutlet weak var addGroupButton: UIBarButtonItem!
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var welcomeBarButtonItem: UIBarButtonItem!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var sections = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]
    
    var user: User!
    var groups: [Group] = []
    var filteredGroups: [Group] = []
    var groupsWithSections: [[Group]] = []
    var filteredGroupsWithSections: [[Group]] = []
    let screenSize = UIScreen.main.bounds
    
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.barTintColor = GlobalFunctions.shared.themeColor()
        myTableView.sectionIndexColor = GlobalFunctions.shared.themeColor()
        
        searchController.delegate = self
        searchController.searchBar.delegate = self
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.definesPresentationContext = false
        searchController.hidesNavigationBarDuringPresentation = false
        myTableView.tableHeaderView = searchController.searchBar
        searchController.searchBar.placeholder = "Search for your group..."
        
        self.navigationController?.navigationBar.isTranslucent = false
        
        let displayName = Auth.auth().currentUser?.value(forKey: "displayName") as? String
        welcomeBarButtonItem.title = "Welcome \(displayName!)!"
        welcomeBarButtonItem.tintColor = GlobalFunctions.shared.themeColor()
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        subscribeToKeyboardNotifications()
        loadGroups()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        unsubscribeFromKeyboardNotifications()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if searchController.isActive {
            if filteredGroupsWithSections.count > 0 {
                return filteredGroupsWithSections[section].count
            }
            return 0
        } else {
            if groupsWithSections.count > 0 {
                return groupsWithSections[section].count
            }
            return 0
        }
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sections
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        var groups = groupsWithSections
        if searchController.isActive {
            groups = filteredGroupsWithSections
        }
            
        if groups.count > 0 {
            if groups[section].count == 0 {
                return nil
            }
            return sections[section]
        }
        return nil
        
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        filteredGroupsWithSections = []
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        var group: Group!
        if searchController.isActive {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TwoLineWithoutImage") as! TwoLineWithoutImageCell
            group = filteredGroupsWithSections[indexPath.section][indexPath.row]
            cell.setUpCell(group: group)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TwoLineWithImage") as! TwoLineWithImageCell
            group = groupsWithSections[indexPath.section][indexPath.row]
            cell.setUpCell(group: group)
            let imageRef = Storage.storage().reference(withPath: "/\(group.uid).jpg")
            imageRef.getMetadata { (metadata, error) -> () in
                if let metadata = metadata {
                    let downloadUrl = metadata.downloadURL()
                    Alamofire.request(downloadUrl!, method: .get).responseImage { response in
                            guard let image = response.result.value else {
                            return
                        }
                        cell.myImageView.image = image
                        cell.aiv.stopAnimating()
                        cell.aiv.isHidden = true
                    }
                } else {
                    cell.myImageView.image = nil
                    cell.aiv.stopAnimating()
                    cell.aiv.isHidden = true
                }
            }
            if cell.myImageView.image == nil {
                cell.aiv.startAnimating()
                cell.aiv.isHidden = false
            }
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: false)
        
        var selectedGroup: Group!
        if searchController.isActive {
            selectedGroup = filteredGroupsWithSections[indexPath.section][indexPath.row]
        } else {
            selectedGroup = groupsWithSections[indexPath.section][indexPath.row]
        }
        
        let directoryVC = self.storyboard?.instantiateViewController(withIdentifier: "DirectoryViewController") as! DirectoryViewController
        directoryVC.group = selectedGroup
        
        if selectedGroup.admins.contains((Auth.auth().currentUser?.uid)!)
            || user.groups.contains(selectedGroup.uid) {
            self.navigationController?.pushViewController(directoryVC, animated: true)
        } else {
            let alertController = UIAlertController(title: "Password Required", message: "Enter the password to access the directory for \(selectedGroup.name)", preferredStyle: .alert)
            
            let submitAction = UIAlertAction(title: "Submit", style: .default) { (_) in
                if let field = alertController.textFields?[0] {
                    if selectedGroup.password == field.text {
                        
                        var updatedGroups = self.user.groups
                        updatedGroups.append(selectedGroup.uid)
                        
                        var updatedUsers = selectedGroup.admins
                        updatedUsers.append(self.user.uid)
                        
                        FirebaseClient.shared.joinGroup(userUid: self.user.uid, groupUid: selectedGroup.uid, groups: updatedGroups, users: updatedUsers) { (success) in
                            if let success = success {
                                if success {
                                    self.navigationController?.pushViewController(directoryVC, animated: true)
                                } else {
                                    self.displayAlert(title: "Error", message: "We were unable to access the directory for you. Please try again.")
                                }
                            }
                        }
                    } else {
                        let alert = UIAlertController(title: "Incorrect Password", message: "Please try again.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alert, animated: false, completion: nil)
                    }
                }
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
            
            alertController.addTextField { (textField) in
                textField.placeholder = "Password"
                textField.isSecureTextEntry = true
            }
            
            alertController.addAction(submitAction)
            alertController.addAction(cancelAction)
            
            self.present(alertController, animated: true, completion: nil)
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            
        }
    }
    
    func displayAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: false, completion: nil)
    }
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
            
        filteredGroups = groups.filter { group in
            return (group.name.lowercased().contains(searchText.lowercased()))
        }
        
        filteredGroupsWithSections = []
        for i in 0...25 {
            var tempArray: [Group] = []
            for group in self.filteredGroups {
                if group.name[0] == self.sections[i] {
                    tempArray.append(group)
                }
            }
            filteredGroupsWithSections.append(tempArray)
        }
        
        myTableView.reloadData()
    }
    
    func loadGroups() {
        
        myTableView.isHidden = true
        aiv.isHidden = false
        aiv.startAnimating()
        
        FirebaseClient.shared.getGroups { (groups, error) -> () in
            if let groups = groups {
                self.groups = groups
                
                var sortedGroups = groups
                sortedGroups.sort { $0.name < $1.name }
                
                self.groupsWithSections = []
                for i in 0...25 {
                    var tempArray: [Group] = []
                    for group in sortedGroups {
                        if group.name[0] == self.sections[i] {
                            tempArray.append(group)
                        }
                    }
                    self.groupsWithSections.append(tempArray)
                }
                
                
                self.myTableView.reloadData()
                self.myTableView.isHidden = false
                self.aiv.isHidden = true
                self.aiv.stopAnimating()
            } else {
                print(error!)
            }
        }
    }
    
    func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(DirectoryViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow,object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(DirectoryViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide,object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self,name: NSNotification.Name.UIKeyboardWillShow,object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {

    }
    
    func keyboardWillHide(notification: NSNotification) {

    }
    
    func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        let userInfo = notification.userInfo!
        let keyboardSize = userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.cgRectValue.height
    }
    
    @IBAction func addGroupButtonPressed(_ sender: Any) {
        let createGroupNC = storyboard?.instantiateViewController(withIdentifier: "CreateGroupNavigationController") as! MyNavigationController
        self.present(createGroupNC, animated: true, completion: nil)
    }

    @IBAction func logoutButtonPressed(_ sender: Any) {
        FirebaseClient.shared.logout(vc: self)
    }
    
}

class TwoLineWithoutImageCell: UITableViewCell {
    
    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var line2: UILabel!
    @IBOutlet weak var createdByLabel: UILabel!
    
    func setUpCell(group: Group) {
        header.attributedText = GlobalFunctions.shared.bold(string: group.name)
        let location = "\(group.city), \(group.state)"
        line2.attributedText = GlobalFunctions.shared.italics(string: location)
        createdByLabel.text = "Created by \(group.createdBy)"
    }
    
}


class TwoLineWithImageCell: UITableViewCell {
    
    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var line2: UILabel!
    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var aiv: UIActivityIndicatorView!
    @IBOutlet weak var createdByLabel: UILabel!
    
    func setUpCell(group: Group) {
        header.attributedText = GlobalFunctions.shared.bold(string: group.name)
        let location = "\(group.city), \(group.state)"
        line2.attributedText = GlobalFunctions.shared.italics(string: location)
        createdByLabel.text = "Created by \(group.createdBy)"
        let w = myImageView.frame.size.width
        myImageView.layer.cornerRadius = w/2
        myImageView.layer.masksToBounds = true
        myImageView.layer.borderWidth = 1
        myImageView.layer.borderColor = UIColor.lightGray.cgColor
    }
    
}

extension GroupsViewController: UISearchResultsUpdating {
    func updateSearchResults(for: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
}

