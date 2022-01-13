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
import GoogleMobileAds

class GroupsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UISearchBarDelegate, UISearchControllerDelegate, PresentingViewController, GADBannerViewDelegate {
    
    @IBOutlet weak var aiv: UIActivityIndicatorView!
    @IBOutlet weak var addGroupButton: UIBarButtonItem!
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var welcomeBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var versionBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var myToolbar: UIToolbar!
    
    var bannerView: GADBannerView!
    @IBOutlet weak var adContainer: UIView!
    @IBOutlet weak var adContainerHeight: NSLayoutConstraint!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let defaults = UserDefaults.standard
    
    var user: User!
    var groups: [Group] = []
    var filteredGroups: [Group] = []
    let screenSize = UIScreen.main.bounds
    var tableViewShrunk = false
    
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
        
        if #available(iOS 15, *) {
            myTableView.sectionHeaderTopPadding = 0
        }
        
        self.navigationController?.navigationBar.isTranslucent = false
        
        let displayName = Auth.auth().currentUser?.value(forKey: "displayName") as? String
        welcomeBarButtonItem.title = "Welcome \(displayName!)!"
        let versionNumber = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String
        versionBarButtonItem.title = "v\(versionNumber!)"
        welcomeBarButtonItem.tintColor = GlobalFunctions.shared.themeColor()
        versionBarButtonItem.tintColor = GlobalFunctions.shared.themeColor()
        myTableView.tintColor = GlobalFunctions.shared.themeColor()
        
        self.navigationController?.navigationBar.barTintColor = GlobalFunctions.shared.themeColor()
        self.navigationController?.navigationBar.isTranslucent = false
        
        self.myTableView.rowHeight = 90.0
        
        if let currentUser = Auth.auth().currentUser {
            if GlobalFunctions.shared.hasConnectivity() {
                set(loading: true)
                FirebaseClient.shared.getUserData(uid: currentUser.uid) { (user, error) in
                    if let error = error {
                        self.displayAlert(title: "Error", message: error.localizedLowercase)
                        self.set(loading: false)
                    } else if let user = user {
                        self.user = user
                        self.loadGroups()
                    }
                }
            } else {
                displayAlert(title: "Error", message: "No Internet Connectivity")
                set(loading: false)
            }
        }
        
        adContainerHeight.constant = 0
        bannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        bannerView.delegate = self
        bannerView.adUnitID = "ca-app-pub-4590926477342036/5514213695"
        //bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716" //test ad-unit id
        bannerView.rootViewController = self
        let request = GADRequest()
        //request.testDevices = ["191b6aacb501d4f65eef7379f19afce6"]
        bannerView.load(request)
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        subscribeToKeyboardNotifications()
        if defaults.bool(forKey: "shouldUpdateGroups") {
            loadGroups()
            defaults.setValue(false, forKey: "shouldUpdateGroups")
        }
    }
    
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        adContainer.addSubview(bannerView)
        self.adContainerHeight.constant = 50
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    }
    
    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
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
        defaults.setValue(true, forKey: "shouldUpdateGroups")
        filteredGroups = []
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        loadGroups()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        var group: Group!
        if searchController.isActive {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TwoLineWithoutImage") as! TwoLineWithoutImageCell
            group = filteredGroups[indexPath.row]
            cell.setUpCell(group: group)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TwoLineWithImage") as! TwoLineWithImageCell
            group = groups[indexPath.row]
            if let currentUserUid = Auth.auth().currentUser?.uid, group.getAdminUids().contains(currentUserUid) {
                cell.accessoryType = UITableViewCellAccessoryType.detailDisclosureButton
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.none
            }
            
            cell.setUpCell(group: group)

            cell.myImageView.loadImage(from: group.uid)

            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
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

        let message = "This will only remove \"\(groupToEdit.name)\" from \"My Groups\". You will be able to add it back again later. Continue?"
        
        if editingStyle == .delete {
            
            let alert = UIAlertController(title: "Delete Group", message: message, preferredStyle: .alert)
            let yes = UIAlertAction(title: "Yes", style: .default, handler: { (action) in
            
                if GlobalFunctions.shared.hasConnectivity() {
                    
                    var updatedUserGroups = self.user.groups
                    updatedUserGroups = updatedUserGroups.filter { $0 != groupToEdit.uid }
                        
                    FirebaseClient.shared.updateUserGroups(userUid: self.user.uid, groupUid: groupToEdit.uid, groups: updatedUserGroups) { (success, message) -> () in
                        if let message = message {
                            self.displayAlert(title: "Failure", message: message)
                            return
                        }
                        if let success = success {
                            if success {
                                self.displayAlert(title: "Success", message: "\(groupToEdit.name) was successfully removed from \"My Groups\".")
                                    self.user.groups = updatedUserGroups
                                    self.loadGroups()
                            } else {
                                self.displayAlert(title: "Error", message: "There was a problem removing \(groupToEdit.name) from \"My Groups\". Please try again.")
                            }
                        } else {
                            self.displayAlert(title: "Error", message: "There was a problem removing \(groupToEdit.name) from \"My Groups\". Please try again.")
                        }
                    }
                    
                } else {
                    self.displayAlert(title: "No Internet Connection", message: "Please establish an internet connection and try again.")
                }
                
            })
            
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.addAction(yes)
            alert.addAction(cancel)
            
            self.present(alert, animated: true, completion: nil)

        }
    }
    
    func displayAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        
        filteredGroups = groups.filter { group in
            return (group.name.lowercased().contains(searchText.lowercased()))
        }
        
        myTableView.reloadData()
        
    }
    
    func loadGroups() {
        
        defaults.setValue(false, forKey: "shouldUpdateGroups")
        self.groups = []
        var deletedGroups = 0
        
        set(loading: true)
        
        if user.groups.count == 0 {
            
            set(loading: false)

        } else {
        
            for groupUid in user.groups {
            
                FirebaseClient.shared.getGroup(groupUid: groupUid) { (group, error) -> () in
                    if let group = group {
                        self.groups.append(group)
                    } else {
                        deletedGroups += 1
                        print(error!)
                    }
                    
                    if self.groups.count == self.user.groups.count - deletedGroups {
                        
                        self.groups.sort { $0.name < $1.name }
                        
                        self.myTableView.reloadData()
                        self.set(loading: false)
                        
                        var groupsThatStillExist: [String] = []
                        for group in self.groups {
                            groupsThatStillExist.append(group.uid)
                        }
                        
                        if deletedGroups > 0 {
                            FirebaseClient.shared.updateUserGroups(userUid: self.user.uid, groups: groupsThatStillExist, completion: { (success) -> () in
                                print("success")
                            })
                        }
                    }
                }
            }
        }
    }
    
    func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(GroupsViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow,object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(GroupsViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide,object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self,name: NSNotification.Name.UIKeyboardWillShow,object: nil)
        NotificationCenter.default.removeObserver(self,name: NSNotification.Name.UIKeyboardWillHide,object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if (!tableViewShrunk) {
            myTableView.frame.size.height -= (getKeyboardHeight(notification: notification) - (myToolbar.frame.size.height + adContainer.frame.size.height))
        }
        tableViewShrunk = true
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if (tableViewShrunk) {
            myTableView.frame.size.height += (getKeyboardHeight(notification: notification) - (myToolbar.frame.size.height + adContainer.frame.size.height))
        }
        tableViewShrunk = false
    }
    
    func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        let userInfo = notification.userInfo!
        let keyboardSize = userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.cgRectValue.height
    }
    
    @IBAction func addGroupButtonPressed(_ sender: Any) {
        
        searchController.isActive = false
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Create Group", style: .default) { (_) in
            let createGroupNC = self.storyboard?.instantiateViewController(withIdentifier: "CreateGroupNavigationController") as! MyNavigationController
            let createGroupVC = createGroupNC.viewControllers[0] as! CreateGroupViewController
            createGroupVC.delegate = self
            createGroupVC.user = self.user
            self.present(createGroupNC, animated: true, completion: nil)
        })
        
        actionSheet.addAction(UIAlertAction(title: "Search Groups", style: .default) { (_) in
            let searchGroupsVC = self.storyboard?.instantiateViewController(withIdentifier: "SearchGroupsViewController") as! SearchGroupsViewController
            searchGroupsVC.user = self.user
            self.navigationController?.pushViewController(searchGroupsVC, animated: true)
        })
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(actionSheet, animated: true, completion: nil)
        

    }

    @IBAction func logoutButtonPressed(_ sender: Any) {
        
        searchController.isActive = false
        
        FirebaseClient.shared.logout(vc: self)
    }
    
    func set(loading: Bool) {
        myTableView.isHidden = loading
        aiv.isHidden = !loading
        if loading {
            aiv.startAnimating()
        } else {
            aiv.stopAnimating()
        }
    }
    
}

class TwoLineWithoutImageCell: UITableViewCell {
    
    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var line2: UILabel!
    @IBOutlet weak var createdByLabel: UILabel!
    
    func setUpCell(group: Group) {
        header.attributedText = GlobalFunctions.shared.bold(string: group.name)
        let location = "\(group.city.trimmingCharacters(in: .whitespaces)), \(group.state)"
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
    @IBOutlet weak var createdByLabel: UILabel!
    
    func setUpCell(group: Group) {
        
        header.attributedText = GlobalFunctions.shared.bold(string: group.name)
        let location = "\(group.city.trimmingCharacters(in: .whitespaces)), \(group.state)"
        line2.attributedText = GlobalFunctions.shared.italics(string: location)
        if Auth.auth().currentUser?.uid == group.createdByUid {
            createdByLabel.text = "Created by You"
        } else {
            createdByLabel.text = "Created by \(group.createdBy)"
        }
        let width = myImageView.frame.size.width
        myImageView.layer.cornerRadius = width/2
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

