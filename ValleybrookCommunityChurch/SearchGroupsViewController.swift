//
//  SearchGroupsViewController.swift
//  ValleybrookCommunityChurch
//
//  Created by Adam Zarn on 9/18/17.
//  Copyright © 2017 Adam Zarn. All rights reserved.
//

import UIKit
import CoreData
import Contacts
import Alamofire
import AlamofireImage
import Firebase

enum SearchKey: String {
    case name = "lowercasedName"
    case createdBy = "lowercasedCreatedBy"
}

enum SearchCriteria: Int {
    case name = 0
    case createdBy = 1
    case uniqueID = 2
}

class SearchGroupsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UISearchBarDelegate, UISearchControllerDelegate {
    
    @IBOutlet weak var aiv: UIActivityIndicatorView!
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var searchCriteriaSegmentedControl: UISegmentedControl!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let defaults = UserDefaults.standard
    
    var user: User!
    var groups: [Group] = []
    let screenSize = UIScreen.main.bounds
    
    let searchController = UISearchController(searchResultsController: nil)
    var searchKey: String!
    var tableViewShrunk = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchController.delegate = self
        searchController.searchBar.delegate = self
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.definesPresentationContext = false
        searchController.hidesNavigationBarDuringPresentation = false
        myTableView.tableHeaderView = searchController.searchBar
        searchController.searchBar.placeholder = "Enter a group name..."
        
        self.navigationController?.navigationBar.isTranslucent = false

        myTableView.tintColor = GlobalFunctions.shared.themeColor()
        
        self.myTableView.rowHeight = 90.0
        
        if #available(iOS 15, *) {
            myTableView.sectionHeaderTopPadding = 0
        }
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        subscribeToKeyboardNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        unsubscribeFromKeyboardNotifications()
        searchController.isActive = false
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let group = groups[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "TwoLineWithImage") as! TwoLineWithImageCell

        cell.setUpCell(group: group)
        
        cell.myImageView.loadImage(from: group.uid)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        searchController.isActive = false
    
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedGroup = groups[indexPath.row]
        
        let alertController = UIAlertController(title: "Password Required", message: "Enter the password to join the group \"\(selectedGroup.name)\"", preferredStyle: .alert)
            
        let submitAction = UIAlertAction(title: "Submit", style: .default) { (_) in
            if let field = alertController.textFields?[0] {
                if selectedGroup.password == field.text {
                        
                    var updatedGroups = self.user.groups
                    updatedGroups.append(selectedGroup.uid)
                        
                    var updatedUsers = selectedGroup.users
                    let member = Member(uid: self.user.uid, name: self.user.name)
                    updatedUsers.append(member)
                        
                    FirebaseClient.shared.joinGroup(userUid: self.user.uid, groupUid: selectedGroup.uid, groups: updatedGroups, users: updatedUsers) { (success) in
                        if let success = success {
                            self.defaults.setValue(true, forKey: "shouldUpdateGroups")
                            if success {
                                self.user.groups = updatedGroups
                                let groupsVC = self.navigationController?.viewControllers[0] as! GroupsViewController
                                groupsVC.user = self.user
                                self.navigationController?.popViewController(animated: true)
                            } else {
                                self.displayAlert(title: "Error", message: "We were unable to join the group for you. Please try again.")
                            }
                        }
                    }
                    
                } else {
                    
                    let alert = UIAlertController(title: "Incorrect Password", message: "Please try again.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
        alertController.addTextField { (textField) in
            textField.textAlignment = .center
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }
            
        alertController.addAction(submitAction)
        alertController.addAction(cancelAction)
            
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    func displayAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(SearchGroupsViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow,object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SearchGroupsViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide,object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self,name: NSNotification.Name.UIKeyboardWillShow,object: nil)
        NotificationCenter.default.removeObserver(self,name: NSNotification.Name.UIKeyboardWillHide,object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if (!tableViewShrunk) {
            myTableView.frame.size.height -= getKeyboardHeight(notification: notification)
        }
        tableViewShrunk = true
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if (tableViewShrunk) {
            myTableView.frame.size.height += getKeyboardHeight(notification: notification)
        }
        tableViewShrunk = false
    }
    
    func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        let userInfo = notification.userInfo!
        let keyboardSize = userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.cgRectValue.height
    }
    
    func performSearch(key: String) {
        if GlobalFunctions.shared.hasConnectivity() {
            let query = searchController.searchBar.text!.lowercased()
            if query != "" {
                FirebaseClient.shared.queryGroups(query: query, searchKey: key) { (groups, error) -> () in
                    if let groups = groups {
                        self.groups = []
                        for group in groups {
                            if !self.user.groups.contains(group.uid) {
                                self.groups.append(group)
                            }
                        }
                        if key == SearchKey.name.rawValue {
                            self.groups.sort { $0.name < $1.name }
                        } else {
                            self.groups.sort { $0.createdBy < $1.createdBy }
                        }
                    }
                    self.myTableView.reloadData()
                }
            } else {
                self.myTableView.reloadData()
            }
        } else {
            self.displayAlert(title: "No Internet Connection", message: "Please establish an internet connection and try again.")
        }
    }
    
    func performSearch() {
        if GlobalFunctions.shared.hasConnectivity() {
            let groupUid = searchController.searchBar.text!
            if groupUid != "" {
                FirebaseClient.shared.getGroup(groupUid: groupUid) { (group, error) -> () in
                    if let group = group {
                        self.groups = []
                        if !self.user.groups.contains(group.uid) {
                            self.groups = [group]
                        }
                        self.myTableView.reloadData()
                    } else {
                        self.myTableView.reloadData()
                    }
                }
            } else {
                self.myTableView.reloadData()
            }
        } else {
            self.displayAlert(title: "No Internet Connection", message: "Please establish an internet connection and try again.")
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        groups = []
        myTableView.reloadData()
    }
    
    @IBAction func searchCriteriaChanged(_ sender: Any) {
        switch (searchCriteriaSegmentedControl.selectedSegmentIndex) {
            case SearchCriteria.name.rawValue:
                searchController.searchBar.placeholder = "Enter a group name..."
                groups = []
                performSearch(key: SearchKey.name.rawValue)
            case SearchCriteria.createdBy.rawValue:
                searchController.searchBar.placeholder = "Enter a group creator's name..."
                groups = []
                performSearch(key: SearchKey.createdBy.rawValue)
            case SearchCriteria.uniqueID.rawValue:
                searchController.searchBar.placeholder = "Enter a group Unique ID..."
                groups = []
                performSearch()
            default:
                searchController.searchBar.placeholder = "Enter a group name..."
                groups = []
                performSearch(key: SearchKey.name.rawValue)
        }

    }
    
}

extension SearchGroupsViewController: UISearchResultsUpdating {
    func updateSearchResults(for: UISearchController) {
        if searchController.isActive {
            switch (searchCriteriaSegmentedControl.selectedSegmentIndex) {
                case SearchCriteria.name.rawValue: performSearch(key: SearchKey.name.rawValue)
                case SearchCriteria.createdBy.rawValue: performSearch(key: SearchKey.createdBy.rawValue)
                case SearchCriteria.uniqueID.rawValue: performSearch()
                default: ()
            }
        }
    }
}


