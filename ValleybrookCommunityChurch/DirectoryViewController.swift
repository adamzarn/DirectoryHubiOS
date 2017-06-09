//
//  ViewController.swift
//  ValleybrookCommunityChurch
//
//  Created by Adam Zarn on 6/6/17.
//  Copyright © 2017 Adam Zarn. All rights reserved.
//

import UIKit
import CoreData

class DirectoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var myTableView: UITableView!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var families: [Family]? = nil
    var keys: [String]? = nil
    var sections = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]
    var familiesWithSections: [[Family]] = []
    let screenSize = UIScreen.main.bounds
    let defaults = UserDefaults.standard
    
    @IBOutlet weak var lastUpdatedItem: UIBarButtonItem!
    @IBOutlet weak var loadingLabel: UILabel!
    @IBOutlet weak var aiv: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let lastUpdateTime = defaults.value(forKey: "lastUpdated") {
            lastUpdatedItem.title = "Last Updated: \(lastUpdateTime)"
        } else {
            lastUpdatedItem.title = ""
        }
        lastUpdatedItem.isEnabled = false
        loadingLabel.text = "Loading..."
        let w = screenSize.width
        let h = screenSize.height
        
        let navBarHeight = self.navigationController?.navigationBar.frame.height
        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        
        let centerY = h/2 - navBarHeight! - statusBarHeight
        
        aiv.frame = CGRect(x: w/2 - 10, y: centerY - 10, width: 20, height: 20)
        loadingLabel.frame = CGRect(x: 0, y: centerY + 20, width: w, height: 20)
        loadingLabel.textAlignment = .center
        
        self.navigationController?.navigationBar.isTranslucent = false
        
        myTableView.isHidden = true
        aiv.startAnimating()
        
        if GlobalFunctions.sharedInstance.hasConnectivity() {
            
            appDelegate.removeData()
        
            FirebaseClient.sharedInstance.updateData { (success, error) -> () in
                if success.boolValue {
                    
                    self.displayData()
                    
                    let lastUpdateTime = self.getCurrentDateTime()
                    self.lastUpdatedItem.title = "Last Updated: \(lastUpdateTime)"
                    self.defaults.setValue(lastUpdateTime, forKey: "lastUpdated")
                    
                } else {
                    print(error!)
                }
                
            }
            
        } else {
            displayData()
        }
    }
    
    func displayData() {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Family")
        
        do {
            families = try self.appDelegate.managedObjectContext.fetch(fetchRequest) as? [Family]
        } catch let e as NSError {
            print("Failed to retrieve record: \(e.localizedDescription)")
            return
        }
        
        families?.sort { $0.name! < $1.name! }
        
        for i in 0...25 {
            var tempArray: [Family] = []
            for family in self.families! {
                if family.name?[0] == self.sections[i] {
                    tempArray.append(family)
                }
            }
            familiesWithSections.append(tempArray)
        }
        
        myTableView.reloadData()
        myTableView.isHidden = false
        aiv.stopAnimating()

    }
    
    func getCurrentDateTime() -> String {
        let date = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let year = calendar.component(.year, from: date)
        var hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        
        let yearString = String(year)
        var minutesString = String(minutes)
        var suffix = ""
        
        if hour == 0 {
            hour = 12
            suffix = "AM"
        } else if hour < 12 {
            suffix = "AM"
        } else if hour == 12 {
            suffix = "PM"
        } else if hour > 12 {
            hour = hour - 12
            suffix = "PM"
        }
        
        if minutes < 10 {
            minutesString = "0\(minutesString)"
        }
        
        return "\(month)/\(day)/\(yearString.substring(from: 2)) \(hour):\(minutesString) \(suffix)"
    
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if familiesWithSections.count > 0 {
            return familiesWithSections[section].count
        }
        return 0
    
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sections
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if familiesWithSections.count > 0 {
            if familiesWithSections[section].count == 0 {
                return nil
            }
            return sections[section]
        }
        return nil

    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let family = familiesWithSections[indexPath.section][indexPath.row]
        let address = family.familyToAddress
        let people = family.familyToPerson?.allObjects as! [Person]
        
        let header = getHeader(family: family, people: people)
        let familyPhone = family.phone
        let familyEmail = family.email
        let addressLine1 = address?.line1
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
        if addressLine1 != "" {
            lineCount += 1
            lines.append(addressLine1!)
        }
        if addressLine2 != "" {
            lineCount += 1
            lines.append(addressLine2!)
        }
        if addressLine3 != "" {
            lineCount += 1
            lines.append(addressLine3!)
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
        
        let fvc = storyboard?.instantiateViewController(withIdentifier: "FamilyViewController") as! FamilyViewController
        
        fvc.family = familiesWithSections[indexPath.section][indexPath.row]
        
        self.navigationController?.pushViewController(fvc, animated: true)
        
        tableView.deselectRow(at: indexPath, animated: false)
    }

}

class OneLineCell: UITableViewCell {
    
    @IBOutlet weak var header: UILabel!
    
    func setUpCell(lines: [String]) {
        header.text = lines[0]
    }
    
}

class TwoLineCell: UITableViewCell {
    
    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var line2: UILabel!
    
    func setUpCell(lines: [String]) {
        header.text = lines[0]
        line2.text = lines[1]
    }
    
}

class ThreeLineCell: UITableViewCell {
    
    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var line2: UILabel!
    @IBOutlet weak var line3: UILabel!
    
    func setUpCell(lines: [String]) {
        header.text = lines[0]
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
        header.text = lines[0]
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
        header.text = lines[0]
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
        header.text = lines[0]
        line2.text = lines[1]
        line3.text = lines[2]
        line4.text = lines[3]
        line5.text = lines[4]
        line6.text = lines[5]
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

