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

class GroupsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UISearchBarDelegate, UISearchControllerDelegate, PresentingViewController {
    
    @IBOutlet weak var aiv: UIActivityIndicatorView!
    @IBOutlet weak var addGroupButton: UIBarButtonItem!
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var welcomeBarButtonItem: UIBarButtonItem!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var user: User!
    var groups: [Group] = []
    var imageFetched: [Bool] = []
    var filteredGroups: [Group] = []
    let screenSize = UIScreen.main.bounds
    
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchController.delegate = self
        searchController.searchBar.delegate = self
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.definesPresentationContext = false
        searchController.hidesNavigationBarDuringPresentation = false
        myTableView.tableHeaderView = searchController.searchBar
        searchController.searchBar.placeholder = "Search your groups..."
        
        self.navigationController?.navigationBar.isTranslucent = false
        
        let displayName = Auth.auth().currentUser?.value(forKey: "displayName") as? String
        welcomeBarButtonItem.title = "Welcome \(displayName!)!"
        welcomeBarButtonItem.tintColor = GlobalFunctions.shared.themeColor()
        myTableView.tintColor = GlobalFunctions.shared.themeColor()
        
        self.navigationController?.navigationBar.barTintColor = GlobalFunctions.shared.themeColor()
        self.navigationController?.navigationBar.isTranslucent = false
        
        self.myTableView.rowHeight = 90.0
        
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
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        var groupToEdit = groups[indexPath.row]
        let createGroupNC = storyboard?.instantiateViewController(withIdentifier: "CreateGroupNavigationController") as! MyNavigationController
        let createGroupVC = createGroupNC.viewControllers[0] as! CreateGroupViewController
        let cell = myTableView.cellForRow(at: indexPath) as! TwoLineWithImageCell
        
        if let image = cell.myImageView?.image {
            let imageData = UIImageJPEGRepresentation(image, 0.0)
            groupToEdit.profilePicture = imageData!
        }
        
        createGroupVC.groupToEdit = groupToEdit
        createGroupVC.user = self.user

        self.present(createGroupNC, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if searchController.isActive {
            if filteredGroups.count > 0 {
                return filteredGroups.count
            }
            return 0
        } else {
            if groups.count > 0 {
                return groups.count
            }
            return 0
        }
        
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        filteredGroups = []
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        var group: Group!
        if searchController.isActive {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TwoLineWithoutImage") as! TwoLineWithoutImageCell
            group = filteredGroups[indexPath.row]
            if group.getAdminUids().contains(Auth.auth().currentUser!.uid) {
                cell.accessoryType = UITableViewCellAccessoryType.detailDisclosureButton
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.none
            }
            cell.setUpCell(group: group)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TwoLineWithImage") as! TwoLineWithImageCell
            group = groups[indexPath.row]
            if group.getAdminUids().contains(Auth.auth().currentUser!.uid) {
                cell.accessoryType = UITableViewCellAccessoryType.detailDisclosureButton
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.none
            }
            cell.setUpCell(group: group)
            if !imageFetched[indexPath.row] {
                cell.aiv.startAnimating()
                cell.aiv.isHidden = false
                let imageRef = Storage.storage().reference(withPath: "/\(group.uid).jpg")
                imageRef.getMetadata { (metadata, error) -> () in
                    if let metadata = metadata {
                        let downloadUrl = metadata.downloadURL()
                        Alamofire.request(downloadUrl!, method: .get).responseImage { response in
                                guard let image = response.result.value else {
                                    cell.aiv.stopAnimating()
                                    cell.aiv.isHidden = true
                                return
                            }
                            cell.myImageView.image = image
                            self.groups[indexPath.row].profilePicture = UIImageJPEGRepresentation(image, 0.0)!
                            cell.aiv.stopAnimating()
                            cell.aiv.isHidden = true
                        }
                    } else {
                        cell.myImageView.image = nil
                        self.groups[indexPath.row].profilePicture = UIImageJPEGRepresentation(UIImage(data: Data())!, 0.0)!
                        cell.aiv.stopAnimating()
                        cell.aiv.isHidden = true
                    }
                }
                imageFetched[indexPath.row] = true
            } else {
                cell.myImageView.image = UIImage(data: group.profilePicture)
            }
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: false)
        
        var selectedGroup: Group!
        if searchController.isActive {
            selectedGroup = filteredGroups[indexPath.row]
            searchController.isActive = false
        } else {
            selectedGroup = groups[indexPath.row]
        }
        
        let directoryVC = self.storyboard?.instantiateViewController(withIdentifier: "DirectoryViewController") as! DirectoryViewController
        directoryVC.group = selectedGroup

        self.navigationController?.pushViewController(directoryVC, animated: true)
        
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let groupToEdit = groups[indexPath.row]
        var message: String!
        var admin: Bool!
        if groupToEdit.getAdminUids().contains((Auth.auth().currentUser?.uid)!) {
            message = "Since you are an admin of this group, this will delete this group from the database. Are you sure you want to continue?"
            admin = true
        } else {
            message = "This will only remove this group from \"My Groups\". You will be able to add it back again later. Continue?"
            admin = false
        }
        
        if editingStyle == .delete {
            
            let alert = UIAlertController(title: "Delete Group", message: message, preferredStyle: .alert)
            let yes = UIAlertAction(title: "Yes", style: .default, handler: { (action) in
            
                if GlobalFunctions.shared.hasConnectivity() {
                    
                    if admin {
                        FirebaseClient.shared.deleteGroup(uid: groupToEdit.uid) { (success) -> () in
                            if let success = success {
                                if success {
                                    self.displayAlert(title: "Success", message: "\(groupToEdit.name) was successfully removed from the database.")
                                    self.loadGroups()
                                } else {
                                    self.displayAlert(title: "Error", message: "There was a problem removing \(groupToEdit.name) from the database. Please try again.")
                                }
                            } else {
                                self.displayAlert(title: "Error", message: "There was a problem removing \(groupToEdit.name) from the database. Please try again.")
                            }
                        }
                    } else {
                        var updatedUserGroups = self.user.groups
                        updatedUserGroups = updatedUserGroups.filter { $0 != groupToEdit.uid }
                        
                        FirebaseClient.shared.updateUserGroups(userUid: self.user.uid, groups: updatedUserGroups) { (success) -> () in
                            if let success = success {
                                if success {
                                    self.displayAlert(title: "Success", message: "\(groupToEdit.name) was successfully removed from \"My Groups\".")
                                    self.loadGroups()
                                } else {
                                self.displayAlert(title: "Error", message: "There was a problem removing \(groupToEdit.name) from \"My Groups\". Please try again.")
                                }
                            } else {
                                self.displayAlert(title: "Error", message: "There was a problem removing \(groupToEdit.name) from \"My Groups\". Please try again.")
                            }
                        }
                    }
                } else {
                    self.displayAlert(title: "No Internet Connection", message: "Please establish an internet connection and try again.")
                }
                
            })
            
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.addAction(yes)
            alert.addAction(cancel)
            
            self.present(alert, animated: false, completion: nil)

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
        
        myTableView.reloadData()
        
    }
    
    func loadGroups() {
        
        self.groups = []
        self.imageFetched = []
        var deletedGroups = 0
        
        myTableView.isHidden = true
        aiv.isHidden = false
        aiv.startAnimating()
        
        if user.groups.count == 0 {
            
            self.myTableView.isHidden = false
            self.aiv.isHidden = true
            self.aiv.stopAnimating()

        } else {
        
            for groupUid in user.groups {
            
                FirebaseClient.shared.getGroup(groupUid: groupUid) { (group, error) -> () in
                    if let group = group {
                        
                        self.groups.append(group)
                        
                        if self.groups.count == self.user.groups.count - deletedGroups {
                        
                            for _ in self.groups {
                                self.imageFetched.append(false)
                            }
                            
                            self.groups.sort { $0.name < $1.name }
                            
                            self.myTableView.reloadData()
                            self.myTableView.isHidden = false
                            self.aiv.isHidden = true
                            self.aiv.stopAnimating()
                            
                        }
                        
                    } else {
                        deletedGroups += 1
                        print(error!)
                    }
                }
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
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Create a New Group", style: .default) { (_) in
            let createGroupNC = self.storyboard?.instantiateViewController(withIdentifier: "CreateGroupNavigationController") as! MyNavigationController
            let createGroupVC = createGroupNC.viewControllers[0] as! CreateGroupViewController
            createGroupVC.delegate = self
            createGroupVC.user = self.user
            self.present(createGroupNC, animated: true, completion: nil)
        })
        
        actionSheet.addAction(UIAlertAction(title: "Search for a Group", style: .default) { (_) in
            let searchGroupsVC = self.storyboard?.instantiateViewController(withIdentifier: "SearchGroupsViewController") as! SearchGroupsViewController
            searchGroupsVC.user = self.user
            self.navigationController?.pushViewController(searchGroupsVC, animated: true)
        })
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(actionSheet, animated: true, completion: nil)
        

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
        
        if Auth.auth().currentUser?.uid == group.createdByUid {
            createdByLabel.text = "Created by You"
        } else {
            createdByLabel.text = "Created by \(group.createdBy)"
        }
    }
    
}


class TwoLineWithImageCell: UITableViewCell {
    
    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var line2: UILabel!
    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var aiv: UIActivityIndicatorView!
    @IBOutlet weak var createdByLabel: UILabel!
    
    func setUpCell(group: Group) {
        
        myImageView.image = nil
        header.attributedText = GlobalFunctions.shared.bold(string: group.name)
        let location = "\(group.city), \(group.state)"
        line2.attributedText = GlobalFunctions.shared.italics(string: location)
        if Auth.auth().currentUser?.uid == group.createdByUid {
            createdByLabel.text = "Created by You"
        } else {
            createdByLabel.text = "Created by \(group.createdBy)"
        }
        let w = myImageView.frame.size.width
        myImageView.layer.cornerRadius = w/2
        myImageView.layer.masksToBounds = true
        
    }
    
}

extension GroupsViewController: UISearchResultsUpdating {
    func updateSearchResults(for: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
}

protocol PresentingViewController {
    
    var user: User! {get set}
    
}

