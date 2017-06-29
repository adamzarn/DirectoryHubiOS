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
    @IBOutlet weak var switchChurchesButton: UIBarButtonItem!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var families: [Family] = []
    var filteredFamilies: [Family] = []
    var sections = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]
    var familiesWithSections: [[Family]] = []
    var filteredFamiliesWithSections: [[Family]] = []
    var churches: [(name: String, location: String, password: String)] = []
    var filteredChurches: [(name: String, location: String, password: String)] = []
    let screenSize = UIScreen.main.bounds
    @IBOutlet weak var toolbar: UIToolbar!

    @IBOutlet weak var lastUpdatedItem: UIBarButtonItem!
    var loadingLabel: UILabel!
    @IBOutlet weak var aiv: UIActivityIndicatorView!
    
    var churchesTable = false
    
    let searchController = UISearchController(searchResultsController: nil)
    
    let versionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        myTableView.setContentOffset(CGPoint(x:0,y:searchController.searchBar.frame.size.height), animated: false)
        
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.barTintColor = GlobalFunctions.shared.color(r: 220, g: 111, b: 104)
        myTableView.sectionIndexColor = GlobalFunctions.shared.color(r: 220, g: 111, b: 104)
        lastUpdatedItem.tintColor = GlobalFunctions.shared.color(r: 220, g: 111, b: 104)
        
        searchController.delegate = self
        searchController.searchBar.delegate = self
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.definesPresentationContext = false
        searchController.hidesNavigationBarDuringPresentation = false
        myTableView.tableHeaderView = searchController.searchBar
        
        loadingLabel = UILabel()
        view.addSubview(loadingLabel)
        
        setLoadingPosition()
        
        self.navigationController?.navigationBar.isTranslucent = false
        self.toolbar.isTranslucent = false
        
        if let church = appDelegate.defaults.value(forKey: "church") {
            if church as! String != "" {
                churchesTable = false
                if let lastUpdateTime = appDelegate.defaults.value(forKey: "lastUpdated") {
                    lastUpdatedItem.title = "Last Updated: \(lastUpdateTime)"
                }
                allowAccessToDirectory()
            }
        } else {
            churchesTable = true
            setUpChurchesView()
            loadChurches()
        }
        
    }
    
    func allowAccessToDirectory() {
        
        setLoadingPosition()
        
        self.title = "Directory"
        switchChurchesButton.tintColor = .white
        switchChurchesButton.isEnabled = true
        addFamilyButton.tintColor = .white
        addFamilyButton.isEnabled = true
    
        toolbar.isUserInteractionEnabled = false
        loadingLabel.text = "Loading Directory..."
        searchController.searchBar.placeholder = "Search by Last Name"
        
        myTableView.isHidden = true
        aiv.startAnimating()
        updateData()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    
    
    func updateData() {
        
        if GlobalFunctions.shared.hasConnectivity() {
            appDelegate.removeData()
            
            let church = appDelegate.defaults.value(forKey: "church") as! String
            FirebaseClient.shared.updateData(church: church) { (success, error) -> () in
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
        myTableView.setContentOffset(CGPoint(x:0,y:searchController.searchBar.frame.size.height), animated: false)
        aiv.stopAnimating()
        aiv.isHidden = true
        loadingLabel.isHidden = true
        loadingLabel.text = "Loading Directory..."

    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if churchesTable {
            if searchController.isActive && searchController.searchBar.text != "" {
                return filteredChurches.count
            }
            return churches.count
        }

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
        if churchesTable {
            return 1
        }
        return sections.count
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if churchesTable {
            return nil
        }
        return sections
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if churchesTable {
            return nil
        }
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
        
        if churchesTable {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TwoLine") as! TwoLineCell
            if searchController.isActive && searchController.searchBar.text != "" {
                cell.setUpCell(church: filteredChurches[indexPath.row])
            } else {
                cell.setUpCell(church: churches[indexPath.row])
            }
            return cell
        }
        
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
        
        if churchesTable {
            
            var churchName = ""
            var password = ""
            if searchController.isActive && searchController.searchBar.text != "" {
                churchName = filteredChurches[indexPath.row].name
                password = filteredChurches[indexPath.row].password
                searchController.searchBar.text = ""
                searchController.isActive = false
                searchController.dismiss(animated: false, completion: nil)
            } else {
                churchName = churches[indexPath.row].name
                password = churches[indexPath.row].password
            }
            
            let alertController = UIAlertController(title: "Password Required", message: "Enter the password to access the Directory for \(churchName).", preferredStyle: .alert)
            
            let submitAction = UIAlertAction(title: "Submit", style: .default) { (_) in
                if let field = alertController.textFields?[0] {

                    if password == field.text {
                        self.churchesTable = false
                        self.appDelegate.defaults.setValue(churchName, forKey: "church")
                        self.allowAccessToDirectory()
                    } else {
                        let alert = UIAlertController(title: "Incorrect Password", message: "Please try again.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alert, animated: false, completion: nil)
                        self.myTableView.deselectRow(at: indexPath, animated: false)
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
            myTableView.deselectRow(at: indexPath, animated: false)
            
        } else {
        
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
    }
    
    @IBAction func addFamilyButtonPressed(_ sender: Any) {

        let alertController = UIAlertController(title: "Password Required", message: "Enter the administrator password to add a family to the Directory.", preferredStyle: .alert)
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { (_) in
            if let field = alertController.textFields?[0] {
                if GlobalFunctions.shared.hasConnectivity() {
                    
                    let church = self.appDelegate.defaults.value(forKey: "church") as! String
                    FirebaseClient.shared.getAdminPassword(church: church) { (password, error) -> () in
                        
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
                        
                        let church = self.appDelegate.defaults.value(forKey: "church") as! String
                        FirebaseClient.shared.getAdminPassword(church: church) { (password, error) -> () in
                            
                            if let password = password {
                                
                                if field.text == password {
                
                                    FirebaseClient.shared.deleteFamily(church: church, uid: familyToDelete.uid!) { success in
                    
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
        
        if churchesTable {
            
            filteredChurches = churches.filter { church in
                return (church.name.lowercased().contains(searchText.lowercased()))
            }
            
            filteredChurches.sort { $0.name < $1.name }
            myTableView.reloadData()
            
        } else {
            
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
    
    @IBAction func switchChurches(_ sender: Any) {
        
        let alert = UIAlertController(title: "Switch Churches", message: "You will need this directory's password to access it again. Are you sure you want to continue?" , preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
            self.churchesTable = true
            if self.churches.count == 0 {
                self.setUpChurchesView()
                self.loadChurches()
            } else {
                self.setUpChurchesView()
                self.myTableView.reloadData()
                self.myTableView.setContentOffset(CGPoint(x:0,y:self.searchController.searchBar.frame.size.height), animated: false)
            }
            self.appDelegate.defaults.setValue("", forKey: "church")
            self.appDelegate.defaults.setValue("", forKey: "lastUpdated")
        }))
        
        alert.addAction(UIAlertAction(title: "No", style: .default, handler: nil))
        self.present(alert, animated: false, completion: nil)
        
    }
    
    func setUpChurchesView() {
        self.title = "Select a Church"
        
        lastUpdatedItem.title = ""
        switchChurchesButton.tintColor = .clear
        switchChurchesButton.isEnabled = false
        addFamilyButton.tintColor = .clear
        addFamilyButton.isEnabled = false
        
        churchesTable = true
        searchController.searchBar.placeholder = "Search for a Church"
        
    }
    
    func setLoadingPosition() {
        let w = screenSize.width
        let h = screenSize.height
        
        let navBarHeight = self.navigationController?.navigationBar.frame.height
        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        
        let centerY = h/2 - navBarHeight! - statusBarHeight
        
        aiv.frame = CGRect(x: w/2 - 10, y: centerY - 10, width: 20, height: 20)
        loadingLabel.frame = CGRect(x: 0, y: centerY + 20, width: w, height: 20)
        loadingLabel.textAlignment = .center
    }
    
    func loadChurches() {
        
        setLoadingPosition()
        
        churchesTable = true
        myTableView.isHidden = true
        aiv.isHidden = false
        aiv.startAnimating()
        loadingLabel.isHidden = false
        loadingLabel.text = "Loading Churches..."
        
        lastUpdatedItem.title = "Directory App Version \(versionNumber)"
        
        FirebaseClient.shared.getChurches { (churches, error) -> () in
            if let churches = churches {
                var sortedChurches = churches
                sortedChurches.sort { $0.name < $1.name }
                self.churches = sortedChurches
                self.myTableView.reloadData()
                self.myTableView.setContentOffset(CGPoint(x:0,y:self.searchController.searchBar.frame.size.height), animated: false)
                self.myTableView.isHidden = false
                self.aiv.isHidden = true
                self.aiv.stopAnimating()
                self.loadingLabel.isHidden = true
            } else {
                print(error!)
            }
        }
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
    
    func setUpCell(church: (name: String, location: String, password: String)) {
        header.attributedText = GlobalFunctions.shared.bold(string: church.0)
        line2.text = church.1
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

