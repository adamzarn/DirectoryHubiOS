//
//  ViewController.swift
//  ValleybrookCommunityChurch
//
//  Created by Adam Zarn on 6/6/17.
//  Copyright © 2017 Adam Zarn. All rights reserved.
//

import UIKit
import CoreData
import Contacts

class DirectoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UISearchBarDelegate, UISearchControllerDelegate {
    
    @IBOutlet weak var addFamilyButton: UIBarButtonItem!
    @IBOutlet weak var myTableView: UITableView!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var families: [Family] = []
    var filteredFamilies: [Family] = []
    var sections = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]
    var familiesWithSections: [[Family]] = []
    var filteredFamiliesWithSections: [[Family]] = []
    let screenSize = UIScreen.main.bounds
    @IBOutlet weak var toolbar: UIToolbar!

    @IBOutlet weak var lastUpdatedItem: UIBarButtonItem!
    var loadingLabel: UILabel!
    @IBOutlet weak var aiv: UIActivityIndicatorView!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var accessAiv: UIActivityIndicatorView!
    @IBOutlet weak var accessToDirectoryButton: UIButton!
    
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.barTintColor = GlobalFunctions.shared.color(r: 220, g: 111, b: 104)
        myTableView.sectionIndexColor = GlobalFunctions.shared.color(r: 220, g: 111, b: 104)
        
        searchController.delegate = self
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "Search by Last Name"
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.definesPresentationContext = false
        searchController.hidesNavigationBarDuringPresentation = false
        myTableView.tableHeaderView = searchController.searchBar
        
        loadingLabel = UILabel()
        view.addSubview(loadingLabel)
        
        self.navigationController?.navigationBar.isTranslucent = false
        passwordTextField.autocorrectionType = .no
        passwordTextField.isSecureTextEntry = true
        
        if let lastUpdateTime = appDelegate.defaults.value(forKey: "lastUpdated") {
            lastUpdatedItem.title = "Last Updated: \(lastUpdateTime)"
            allowAccessToDirectory()
        } else {
            lastUpdatedItem.title = ""
            accessAiv.isHidden = true
            myTableView.isHidden = true
            aiv.isHidden = true
            loadingLabel.isHidden = true
        }
        
    }
    
    func allowAccessToDirectory() {
        accessAiv.isHidden = true
        passwordTextField.isHidden = true
        accessToDirectoryButton.isHidden = true
    
        lastUpdatedItem.tintColor = GlobalFunctions.shared.color(r: 220, g: 111, b: 104)
        toolbar.isUserInteractionEnabled = false
        loadingLabel.text = "Loading..."
        
        let w = screenSize.width
        let h = screenSize.height
        
        let navBarHeight = self.navigationController?.navigationBar.frame.height
        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        
        let centerY = h/2 - navBarHeight! - statusBarHeight
        
        aiv.isHidden = false
        aiv.frame = CGRect(x: w/2 - 10, y: centerY - 10, width: 20, height: 20)
        loadingLabel.isHidden = false
        loadingLabel.frame = CGRect(x: 0, y: centerY + 20, width: w, height: 20)
        loadingLabel.textAlignment = .center
        
        myTableView.isHidden = true
        aiv.startAnimating()
        updateData()
    }
    
    @IBAction func accessDirectoryButtonPressed(_ sender: Any) {
        
        accessAiv.isHidden = false
        accessAiv.startAnimating()
        accessToDirectoryButton.isHidden = true
        
        if GlobalFunctions.shared.hasConnectivity() {
            
            FirebaseClient.shared.getPassword { (password, error) -> () in
                
                self.accessAiv.stopAnimating()
                self.accessAiv.isHidden = true
                
                if let password = password {
                    
                    if password == self.passwordTextField.text {
                        self.allowAccessToDirectory()
                        self.passwordTextField.resignFirstResponder()
                    } else {
                        let alert = UIAlertController(title: "Incorrect Password", message: "Please try again.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alert, animated: false, completion: nil)
                        self.accessToDirectoryButton.isHidden = false
                    }
                    
                } else {
                    print(error!)
                }
                
            }
            
        } else {
            
            self.accessAiv.stopAnimating()
            self.accessAiv.isHidden = true
            
            let alert = UIAlertController(title: "No Internet Connection", message: "Please establish an internet connection and try again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: false, completion: nil)
            
        }
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    
    
    func updateData() {
        
        if GlobalFunctions.shared.hasConnectivity() {
            appDelegate.removeData()
            FirebaseClient.shared.updateData { (success, error) -> () in
                if success {
                    
                    self.displayData()
                    
                    let lastUpdateTime = GlobalFunctions.shared.getCurrentDateTime()
                    self.lastUpdatedItem.title = "Last Updated: \(lastUpdateTime)"
                    self.appDelegate.defaults.setValue(lastUpdateTime, forKey: "lastUpdated")
                
                } else {
                    print(error!)
                }
            }
        } else {
            displayData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if appDelegate.comingFromUpdate {
            loadingLabel.text = "Updating Directory..."
            loadingLabel.isHidden = false
            aiv.startAnimating()
            aiv.isHidden = false
            myTableView.isHidden = true
            updateData()
        }
        appDelegate.comingFromUpdate = false
        searchController.searchBar.isHidden = false
    }

    func displayData() {
        
        familiesWithSections = []
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Family")
        
        do {
            self.families = try self.appDelegate.managedObjectContext.fetch(fetchRequest) as! [Family]
        } catch let e as NSError {
            print("Failed to retrieve record: \(e.localizedDescription)")
            return
        }
        
        families.sort { $0.name! < $1.name! }
        
        for i in 0...25 {
            var tempArray: [Family] = []
            for family in self.families {
                if family.name?[0] == self.sections[i] {
                    tempArray.append(family)
                }
            }
            familiesWithSections.append(tempArray)
        }
        
        myTableView.reloadData()
        myTableView.isHidden = false
        aiv.stopAnimating()
        aiv.isHidden = true
        loadingLabel.isHidden = true
        loadingLabel.text = "Loading..."

    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if searchController.isActive && searchController.searchBar.text != "" {
            if filteredFamiliesWithSections.count > 0 {
                return filteredFamiliesWithSections[section].count
            }
            return 0
        } else {
            if familiesWithSections.count > 0 {
                return familiesWithSections[section].count
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
        var families = familiesWithSections
        if searchController.isActive && searchController.searchBar.text != "" {
            families = filteredFamiliesWithSections
        }

        if families.count > 0 {
            if families[section].count == 0 {
                return nil
            }
            return sections[section]
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var family = familiesWithSections[indexPath.section][indexPath.row]
        if searchController.isActive && searchController.searchBar.text != "" {
            family = filteredFamiliesWithSections[indexPath.section][indexPath.row]
        }
        
        let address = family.familyToAddress
        let people = family.familyToPerson?.allObjects as! [Person]
        
        let header = getHeader(family: family, people: people)
        
        let familyPhone = family.phone
        let familyEmail = family.email
        let addressStreet = address?.street
        let addressLine2 = address?.line2
        let addressLine3 = address?.line3
        let cityStateZip = getCityStateZip(address: address!)
        let childrenString = getChildrenString(people: people)
        
        var lineCount = 1
        var lines: [String] = [header]
        
        if familyPhone != "" {
            lineCount += 1
            lines.append(familyPhone!)
        }
        if familyEmail != "" {
            lineCount += 1
            lines.append(familyEmail!)
        }
        if addressLine2 != "" {
            lineCount += 1
            lines.append(addressLine2!)
        }
        if addressLine3 != "" {
            lineCount += 1
            lines.append(addressLine3!)
        }
        if addressStreet != "" {
            lineCount += 1
            lines.append(addressStreet!)
        }
        if cityStateZip != "" {
            lineCount += 1
            lines.append(cityStateZip)
        }
        if childrenString != "" {
            lineCount += 1
            lines.append(childrenString)
        }
        
        switch lineCount {
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "OneLine") as! OneLineCell
            cell.setUpCell(lines: lines)
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TwoLine") as! TwoLineCell
            cell.setUpCell(lines: lines)
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ThreeLine") as! ThreeLineCell
            cell.setUpCell(lines: lines)
            return cell
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "FourLine") as! FourLineCell
            cell.setUpCell(lines: lines)
            return cell
        case 5:
            let cell = tableView.dequeueReusableCell(withIdentifier: "FiveLine") as! FiveLineCell
            cell.setUpCell(lines: lines)
            return cell
        case 6:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SixLine") as! SixLineCell
            cell.setUpCell(lines: lines)
            return cell
        case 7:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SevenLine") as! SevenLineCell
            cell.setUpCell(lines: lines)
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "OneLine") as! OneLineCell
            cell.header.text = header
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cell = self.tableView(tableView, cellForRowAt: indexPath)
        return cell.frame.size.height
    }
    
    func getHeader(family: Family, people: [Person]) -> String {
        
        var husbandFirstName = ""
        var wifeFirstName = ""
        var singleFirstName = ""
        
        for person in people {
            if person.type == "Single" {
                singleFirstName = person.name!
            } else if person.type == "Husband" {
                husbandFirstName = person.name!
            } else if person.type == "Wife" {
                wifeFirstName = person.name!
            }
        }
        if singleFirstName != "" {
            return family.name! + ", " + singleFirstName
        } else {
            return family.name! + ", " + husbandFirstName + " & " + wifeFirstName
        }

    }
    
    func getChildrenString(people: [Person]) -> String {
        
        var childrenArray: [Person] = []
        for person in people {
            if person.type == "Child" {
                childrenArray.append(person)
            }
        }
        
        childrenArray.sort { $0.birthOrder! < $1.birthOrder! }
        
        var childrenString = ""
        var i = 0
        
        if childrenArray.count == 2 {
            return childrenArray[0].name! + " & " + childrenArray[1].name!
        }
        
        for child in childrenArray {
            if childrenString == "" {
                childrenString = child.name!
            } else if i == childrenArray.count - 1 {
                childrenString = childrenString + ", & " + child.name!
            } else {
                childrenString = childrenString + ", " + child.name!
            }
            i = i + 1
        }
        
        return childrenString
        
    }
    
    func getCityStateZip(address: Address) -> String {
        
        let city = address.city
        let state = address.state
        let zip = address.zip
        
        if city == "" {
            return ""
        }
        return city! + ", " + state! + " " + zip!
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if searchController.isActive {
            searchController.searchBar.isHidden = true
            searchController.searchBar.resignFirstResponder()
            let fvc = storyboard?.instantiateViewController(withIdentifier: "FamilyViewController") as! FamilyViewController
            fvc.family = filteredFamiliesWithSections[indexPath.section][indexPath.row]
            self.navigationController?.pushViewController(fvc, animated: true)
            searchController.isActive = false
            searchController.searchBar.text = ""
        } else {
            let fvc = storyboard?.instantiateViewController(withIdentifier: "FamilyViewController") as! FamilyViewController
            fvc.family = familiesWithSections[indexPath.section][indexPath.row]
            self.navigationController?.pushViewController(fvc, animated: true)
            tableView.deselectRow(at: indexPath, animated: false)
        }
    }
    
    @IBAction func addFamilyButtonPressed(_ sender: Any) {

        let alertController = UIAlertController(title: "Password Required", message: "Enter the administrator password to add a family to the Directory.", preferredStyle: .alert)
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { (_) in
            if let field = alertController.textFields?[0] {
                if GlobalFunctions.shared.hasConnectivity() {
                    
                    FirebaseClient.shared.getAdminPassword { (password, error) -> () in
                        
                        if let password = password {
                            
                            if password == field.text {
                                let addFamilyVC = self.storyboard?.instantiateViewController(withIdentifier: "AddFamilyViewController") as! AddFamilyViewController
                                addFamilyVC.pvc = self
                                self.navigationController?.pushViewController(addFamilyVC, animated: true)
                            } else {
                                let alert = UIAlertController(title: "Incorrect Password", message: "Please try again.", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                                self.present(alert, animated: false, completion: nil)
                            }
                            
                        } else {
                            print(error!)
                        }
                        
                    }
                    
                } else {
                    
                    let alert = UIAlertController(title: "No Internet Connection", message: "Please establish an internet connection and try again.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: false, completion: nil)
                    
                }

            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Administrator Password"
            textField.isSecureTextEntry = true
        }
        
        alertController.addAction(submitAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        let familyToDelete = familiesWithSections[indexPath.section][indexPath.row]
        let name = familyToDelete.name!
        
        if editingStyle == .delete {
            
            let alertController = UIAlertController(title: "Password Required", message: "Enter the administrator password to remove a family from the Directory.", preferredStyle: .alert)
            
            let submitAction = UIAlertAction(title: "Submit", style: .default) { (_) in
                if let field = alertController.textFields?[0] {
                    
                    if GlobalFunctions.shared.hasConnectivity() {
                        
                        FirebaseClient.shared.getAdminPassword { (password, error) -> () in
                            
                            if let password = password {
                                
                                if field.text == password {
                
                                    FirebaseClient.shared.deleteFamily(uid: familyToDelete.uid!) { success in
                    
                                        if success {
                        
                                            self.displayAlert(title: "Family Deleted", message: "The \(name) family was successfully removed from the database.")
                                            
                                            self.familiesWithSections[indexPath.section].remove(at: indexPath.row)
                                            self.myTableView.reloadData()
                                
                                        } else {
                                            self.displayAlert(title:"Failed to Delete Family", message: "The delete operation failed to complete.")
                                        }
                    
                                    }
                                    
                                } else {
                                    self.displayAlert(title: "Incorrect Password", message: "Please try again.")
                                }
                
                            } else {
                                print("Password not retrieved")
                            }
                        }
                    } else {
                        self.displayAlert(title: "No Internet Connection", message: "Please establish an internet connection and try again.")
                    }
                }
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
            
            alertController.addTextField { (textField) in
                textField.placeholder = "Administrator Password"
                textField.isSecureTextEntry = true
            }
            
            alertController.addAction(submitAction)
            alertController.addAction(cancelAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func displayAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: false, completion: nil)
    }
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        filteredFamilies = families.filter { family in
            return (family.name?.lowercased().contains(searchText.lowercased()))!
        }
        filteredFamiliesWithSections = []
        for i in 0...25 {
            var tempArray: [Family] = []
            for family in self.filteredFamilies {
                if family.name?[0] == self.sections[i] {
                    tempArray.append(family)
                }
            }
            filteredFamiliesWithSections.append(tempArray)
        }

        myTableView.reloadData()
    }

}

class OneLineCell: UITableViewCell {
    
    @IBOutlet weak var header: UILabel!
    
    func setUpCell(lines: [String]) {
        header.attributedText = GlobalFunctions.shared.bold(string: lines[0])
    }
    
}

class TwoLineCell: UITableViewCell {
    
    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var line2: UILabel!
    
    func setUpCell(lines: [String]) {
        header.attributedText = GlobalFunctions.shared.bold(string: lines[0])
        line2.text = lines[1]
    }
    
}

class ThreeLineCell: UITableViewCell {
    
    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var line2: UILabel!
    @IBOutlet weak var line3: UILabel!
    
    func setUpCell(lines: [String]) {
        header.attributedText = GlobalFunctions.shared.bold(string: lines[0])
        line2.text = lines[1]
        line3.text = lines[2]
    }
    
}

class FourLineCell: UITableViewCell {
    
    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var line2: UILabel!
    @IBOutlet weak var line3: UILabel!
    @IBOutlet weak var line4: UILabel!
    
    func setUpCell(lines: [String]) {
        header.attributedText = GlobalFunctions.shared.bold(string: lines[0])
        line2.text = lines[1]
        line3.text = lines[2]
        line4.text = lines[3]
    }
    
}

class FiveLineCell: UITableViewCell {
    
    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var line2: UILabel!
    @IBOutlet weak var line3: UILabel!
    @IBOutlet weak var line4: UILabel!
    @IBOutlet weak var line5: UILabel!
    
    func setUpCell(lines: [String]) {
        header.attributedText = GlobalFunctions.shared.bold(string: lines[0])
        line2.text = lines[1]
        line3.text = lines[2]
        line4.text = lines[3]
        line5.text = lines[4]
    }
    
    
}

class SixLineCell: UITableViewCell {
    
    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var line2: UILabel!
    @IBOutlet weak var line3: UILabel!
    @IBOutlet weak var line4: UILabel!
    @IBOutlet weak var line5: UILabel!
    @IBOutlet weak var line6: UILabel!
    
    func setUpCell(lines: [String]) {
        header.attributedText = GlobalFunctions.shared.bold(string: lines[0])
        line2.text = lines[1]
        line3.text = lines[2]
        line4.text = lines[3]
        line5.text = lines[4]
        line6.text = lines[5]
    }
    
}

class SevenLineCell: UITableViewCell {
    
    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var line2: UILabel!
    @IBOutlet weak var line3: UILabel!
    @IBOutlet weak var line4: UILabel!
    @IBOutlet weak var line5: UILabel!
    @IBOutlet weak var line6: UILabel!
    @IBOutlet weak var line7: UILabel!
    
    func setUpCell(lines: [String]) {
        header.attributedText = GlobalFunctions.shared.bold(string: lines[0])
        line2.text = lines[1]
        line3.text = lines[2]
        line4.text = lines[3]
        line5.text = lines[4]
        line6.text = lines[5]
        line7.text = lines[6]
    }
    
}

extension String {
    
    var length: Int {
        return self.characters.count
    }
    
    subscript (i: Int) -> String {
        return self[Range(i ..< i + 1)]
    }
    
    func substring(from: Int) -> String {
        return self[Range(min(from, length) ..< length)]
    }
    
    func substring(to: Int) -> String {
        return self[Range(0 ..< max(0, to))]
    }
    
    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return self[Range(start ..< end)]
    }
    
}

extension DirectoryViewController: UISearchResultsUpdating {
    func updateSearchResults(for: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
}

