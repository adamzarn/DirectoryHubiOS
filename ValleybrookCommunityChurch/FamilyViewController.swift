//
//  FamilyViewController.swift
//  ValleybrookCommunityChurch
//
//  Created by Adam Zarn on 6/6/17.
//  Copyright © 2017 Adam Zarn. All rights reserved.
//

import UIKit
import MessageUI

class FamilyViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate {
    
    @IBOutlet weak var myTableView: UITableView!
    
    var family: Family?
    var info: [[[String]]] = []
    let sections = ["Home Number", "Family Email", "Address", "Contact Info", "Children"]
    var adults: [Person] = []
    var children: [Person] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let address = family?.familyToAddress
        let people = family?.familyToPerson?.allObjects as! [Person]
        
        if family?.phone == "" {
            info.append([])
        } else {
           info.append([[(family?.phone!)!]])
        }
        
        if family?.email == "" {
            info.append([])
        } else {
            info.append([[(family?.email!)!]])
        }
        
        let addressLines = getAddressLines(address: address!)
        if addressLines.count == 0 {
            info.append([])
        } else {
            info.append([getAddressLines(address: address!)])
        }
        
        for person in people {
            if person.type != "Child" {
                adults.append(person)
            } else {
                children.append(person)
            }
        }
        
        adults.sort { $0.type! < $1.type! }
        children.sort { $0.birthOrder! < $1.birthOrder! }
        
        var allAdultLines: [[String]] = []
        for adult in adults {
            var adultLines: [String] = []
            adultLines.append(adult.name!)
            if adult.phone != "" {
                adultLines.append(adult.phone!)
            }
            if adult.email != "" {
                adultLines.append(adult.email!)
            }
            
            if adultLines.count > 1 && adult.type != "Single" || adultLines.count > 0 && adult.type == "Single" {
                allAdultLines.append(adultLines)
            }
        }
        info.append(allAdultLines)
        
        var allChildrenLines: [[String]] = []
        for child in children {
            var childrenLines: [String] = []
            childrenLines.append(child.name!)
            if child.phone != "" {
                childrenLines.append(child.phone!)
            }
            if child.email != "" {
                childrenLines.append(child.email!)
            }
            allChildrenLines.append(childrenLines)
        }
        info.append(allChildrenLines)
        
        for item in info {
            print(item)
        }
        
        if getFamilyStatus(people: people) == "Single" {
            
            var firstName = ""
            for person in people {
                print(person.name!)
                print(person.type!)
                if person.type == "Single" {
                    firstName = person.name!
                }
            }
            
            title = firstName + " " + (family?.name)!
            
        } else {
            
            let name = (family?.name!)!
            title = "The " + name + " Family"

        }
        
        myTableView.reloadData()
        
    }

    func getFamilyStatus(people: [Person]) -> String {
        for person in people {
            if person.type == "Single" {
                return "Single"
            }
        }
        return "Married"
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return info.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if info.count > 0 {
            if info[section].count == 0 {
                return nil
            }
            return sections[section]
        }
        return nil
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (info[section] as AnyObject).count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cell = self.tableView(tableView, cellForRowAt: indexPath)
        return cell.frame.size.height
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section < 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "OneLineDetailCell")! as! OneLineDetailCell
            cell.setUp(lines: info[indexPath.section][0])
            return cell
        } else if indexPath.section == 2 {
            let addressLines = info[indexPath.section][0]
            switch addressLines.count {
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: "TwoLineDetailCell") as! TwoLineDetailCell
                cell.setUp(lines: addressLines)
                return cell
            case 3:
                let cell = tableView.dequeueReusableCell(withIdentifier: "ThreeLineDetailCell") as! ThreeLineDetailCell
                cell.setUp(lines: addressLines)
                return cell
            case 4:
                let cell = tableView.dequeueReusableCell(withIdentifier: "FourLineDetailCell") as! FourLineDetailCell
                cell.setUp(lines: addressLines)
                return cell
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "TwoLineDetailCell") as! TwoLineDetailCell
                cell.line1.text = "No Address Provided"
                cell.line2.text = ""
                return cell
            }
        } else {
            let personLines = info[indexPath.section][indexPath.row]
            switch personLines.count {
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: "TwoLineDetailCell") as! TwoLineDetailCell
                cell.setUp(lines: personLines)
                return cell
            case 3:
                let cell = tableView.dequeueReusableCell(withIdentifier: "ThreeLineDetailCell") as! ThreeLineDetailCell
                cell.setUp(lines: personLines)
                return cell
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "OneLineDetailCell")! as! OneLineDetailCell
                cell.line1.text = personLines[0]
                return cell
            }
        }
    
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch (indexPath.section) {
            
        case 0:
            
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
            
            actionSheet.addAction(UIAlertAction(title: "Call", style: UIAlertActionStyle.default, handler: { (action) in
                self.callNumber(phoneNumber: self.info[0][0][0])
            }))
                
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
            
            self.present(actionSheet, animated: true, completion: nil)
            
        case 1:
            
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
            
            actionSheet.addAction(UIAlertAction(title: "Email", style: UIAlertActionStyle.default, handler: { (action) in
                let mvc = self.configuredMailComposeViewController(recipients: self.info[indexPath.section][0])
                self.present(mvc, animated: true, completion: nil)
            }))
            
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
            
            self.present(actionSheet, animated: true, completion: nil)
            
        case 2:
            
            let addressString = info[2][0].joined(separator: ", ")
            let formattedAddressString = addressString.replacingOccurrences(of: " ", with: "+")
            
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
            
            if (UIApplication.shared.canOpenURL(NSURL(string:"comgooglemaps://")! as URL)) {
            
                actionSheet.addAction(UIAlertAction(title: "Google Maps", style: UIAlertActionStyle.default, handler: { (action) in
                    let url = NSURL(string: "comgooglemaps://?saddr=&daddr=\(formattedAddressString)&directionsmode=driving")! as URL
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }))
            }
            
            actionSheet.addAction(UIAlertAction(title: "Apple Maps", style: UIAlertActionStyle.default, handler: { (action) in
                let url = NSURL(string: "http://maps.apple.com/maps?saddr=&daddr=\(formattedAddressString)")! as URL
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }))

            actionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
            
            self.present(actionSheet, animated: true, completion: nil)

        case 3, 4:
            
            var peopleArray: [Person]?
            if indexPath.section == 3 {
                peopleArray = adults
            } else {
                peopleArray = children
            }
            
            var person: Person?
            
            for p in peopleArray! {
                if info[indexPath.section][indexPath.row][0] == p.name {
                    person = p
                }
            }
            
            let name = person?.name
            let phone = person?.phone
            let email = person?.email

            var actionSheet: UIAlertController?
            var onlyEmail = false
            if phone! == "" && email! == "" {
                print("1")
                tableView.deselectRow(at: indexPath, animated: true)
                break
            } else if phone! == "" && email! != "" {
                print("2")
                onlyEmail = true
                actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
            } else {
                print("3")
                actionSheet = UIAlertController(title: "How would you like to contact \(name!)?", message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
            }
            
            if phone != "" {
                
                actionSheet?.addAction(UIAlertAction(title: "Call", style: UIAlertActionStyle.default, handler: { (action) in
                    self.callNumber(phoneNumber: phone!)
                }))
                
                actionSheet?.addAction(UIAlertAction(title: "Text", style: UIAlertActionStyle.default, handler: { (action) in
                    let tvc = self.configuredMessageComposeViewController(recipients: [phone!])
                    self.present(tvc, animated: true, completion: nil)
                }))
            }

            
            if email != "" {
                
                var title = "Email"
                if onlyEmail {
                    title = "Email \(name!)"
                }
                
                actionSheet?.addAction(UIAlertAction(title: title, style: UIAlertActionStyle.default, handler: { (action) in
                    let mvc = self.configuredMailComposeViewController(recipients: [email!])
                    self.present(mvc, animated: true, completion: nil)
                }))
                
            }

            actionSheet?.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
            self.present(actionSheet!, animated: true, completion: nil)
            
        default:
            
            break
            
        }

        tableView.deselectRow(at: indexPath, animated: false)
        
    }
    
    func callNumber(phoneNumber: String) {
        
        if let phoneCallURL = URL(string: "tel://\(phoneNumber)") {
            
            let application:UIApplication = UIApplication.shared
            if (application.canOpenURL(phoneCallURL)) {
                application.open(phoneCallURL, options: [:], completionHandler: nil)
            }
        }
    }
    
    func configuredMessageComposeViewController(recipients: [String]) -> MFMessageComposeViewController {
        
        let textMessageVC = MFMessageComposeViewController()
        textMessageVC.messageComposeDelegate = self
        
        textMessageVC.recipients = recipients
        
        return textMessageVC
        
    }
    
    func configuredMailComposeViewController(recipients: [String]) -> MFMailComposeViewController {
        
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        
        mailComposerVC.setToRecipients(recipients)
        
        return mailComposerVC
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }

    func getAddressLines(address: Address) -> [String] {
        var addressLines: [String] = []
        if address.line1 != "" {
            addressLines.append(address.line1!)
        }
        if address.line2 != "" {
            addressLines.append(address.line2!)
        }
        if address.line3 != "" {
            addressLines.append(address.line3!)
        }
        let cityStateZip = getCityStateZip(address: address)
        if cityStateZip != "" {
            addressLines.append(cityStateZip)
        }
        return addressLines
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
    
}

class OneLineDetailCell: UITableViewCell {
   
    @IBOutlet weak var line1: UILabel!
    
    func setUp(lines: [String]) {
        line1.text = lines[0]
    }
    
}


class TwoLineDetailCell: UITableViewCell {
    
    @IBOutlet weak var line1: UILabel!
    @IBOutlet weak var line2: UILabel!
    
    func setUp(lines: [String]) {
        line1.text = lines[0]
        line2.text = lines[1]
    }
    
}

class ThreeLineDetailCell: UITableViewCell {
    
    @IBOutlet weak var line1: UILabel!
    @IBOutlet weak var line2: UILabel!
    @IBOutlet weak var line3: UILabel!
    
    func setUp(lines: [String]) {
        line1.text = lines[0]
        line2.text = lines[1]
        line3.text = lines[2]
    }
    
}

class FourLineDetailCell: UITableViewCell {
    
    @IBOutlet weak var line1: UILabel!
    @IBOutlet weak var line2: UILabel!
    @IBOutlet weak var line3: UILabel!
    @IBOutlet weak var line4: UILabel!
    
    func setUp(lines: [String]) {
        line1.text = lines[0]
        line2.text = lines[1]
        line3.text = lines[2]
        line4.text = lines[3]
    }
    
}
