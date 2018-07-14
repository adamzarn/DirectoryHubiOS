//
//  EntryViewController.swift
//  ValleybrookCommunityChurch
//
//  Created by Adam Zarn on 6/6/17.
//  Copyright © 2017 Adam Zarn. All rights reserved.
//

import UIKit
import MessageUI
import Contacts
import Firebase

enum EntrySection: Int {
    case phone = 0
    case email = 1
    case address = 2
    case adults = 3
    case children = 4
}

class EntryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate {
    
    @IBOutlet weak var myTableView: UITableView!
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    @IBOutlet weak var editEntryBarButtonItem: UIBarButtonItem!
    
    var group: Group!
    var entry: Entry?
    var adults: [Person] = []
    var children: [Person] = []
    let sectionTitles = ["Home Number", "Email", "Address", "Contact Info", "Children"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.barTintColor = GlobalFunctions.shared.themeColor()
        self.navigationController?.navigationBar.isTranslucent = false
        
        if let entry = entry, let people = entry.people {
            adults = people.filter { ($0.type ?? "") != PersonType.child.rawValue }
            adults.sort { ($0.type ?? "") < ($1.type ?? "") }
            children = people.filter { $0.type == PersonType.child.rawValue }
            children.sort { ($0.birthOrder ?? 0) < ($1.birthOrder ?? 0) }
        }
        
        myTableView.rowHeight = UITableViewAutomaticDimension
        myTableView.estimatedRowHeight = 60.0
        
        if let people = entry?.people {
            if getEntryStatus(people: people) == "Single" {
                var firstName = ""
                for person in people {
                    if person.type == "Single" {
                        firstName = person.name ?? ""
                    }
                }
                title = firstName + " " + (entry?.name ?? "")
            } else {
                let name = entry?.name ?? ""
                title = "The " + name + " Family"
            }
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if !group.getAdminUids().contains((Auth.auth().currentUser?.uid)!) {
            editEntryBarButtonItem.isEnabled = false
            editEntryBarButtonItem.tintColor = UIColor.clear
        }
        
    }

    func getEntryStatus(people: [Person]) -> String {
        for person in people {
            if person.type == PersonType.single.rawValue {
                return "Single"
            }
        }
        return "Married"
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case EntrySection.phone.rawValue:
            if entry?.phone != nil {
                return sectionTitles[section]
            }
        case EntrySection.email.rawValue:
            if entry?.email != nil {
                return sectionTitles[section]
            }
        case EntrySection.address.rawValue:
            if let address = entry?.address, !address.isEmpty() {
                return sectionTitles[section]
            }
        case EntrySection.adults.rawValue:
            if adults.count > 0 {
                return sectionTitles[section]
            }
        case EntrySection.children.rawValue:
            if children.count > 0 {
                return sectionTitles[section]
            }
        default: return nil
        }
        return nil
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let entry = entry {
            switch section {
                case EntrySection.phone.rawValue:
                    if let phone = entry.phone, !phone.isEmpty { return 1 } else { return 0 }
                case EntrySection.email.rawValue:
                    if let email = entry.email, !email.isEmpty { return 1 } else { return 0 }
                case EntrySection.address.rawValue:
                    if let address = entry.address, !address.isEmpty() { return 1 } else { return 0 }
                case EntrySection.adults.rawValue:
                    return entry.personCount(personTypes: [PersonType.husband,
                                                                     PersonType.wife,
                                                                     PersonType.single])
                case EntrySection.children.rawValue:
                    return entry.personCount(personTypes: [PersonType.child])
                default:
                    return 0
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "EntryDetailCell") as! EntryDetailCell
        cell.removeSubviews()
        switch indexPath.section {
            case EntrySection.phone.rawValue:
                cell.setUp(phone: entry?.phone)
            case EntrySection.email.rawValue:
                cell.setUp(email: entry?.email)
            case EntrySection.address.rawValue:
                cell.setUp(address: entry?.address)
            case EntrySection.adults.rawValue:
                cell.setUp(person: adults[indexPath.row])
            case EntrySection.children.rawValue:
                cell.setUp(person: children[indexPath.row])
            default:
                fatalError("Something went horribly wrong")
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch (indexPath.section) {
            
        case EntrySection.phone.rawValue:
            
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
            
            actionSheet.addAction(UIAlertAction(title: "Call", style: UIAlertActionStyle.default, handler: { (action) in
                if let number = self.entry?.phone {
                    self.callNumber(phoneNumber: number)
                }
            }))
                
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
            
            self.present(actionSheet, animated: true, completion: nil)
            
        case EntrySection.email.rawValue:
            
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
            
            actionSheet.addAction(UIAlertAction(title: "Email", style: UIAlertActionStyle.default, handler: { (action) in
                if let email = self.entry?.email {
                    let mvc = self.configuredMailComposeViewController(recipients: [email])
                    self.present(mvc, animated: true, completion: nil)
                }
            }))
            
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
            
            self.present(actionSheet, animated: true, completion: nil)
            
        case EntrySection.address.rawValue:

            if let address = entry?.address {
                guard let street = address.street else { return }
                let addressString = street + ", " + address.getCityStateZipString()
                
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
            }

        case EntrySection.adults.rawValue, EntrySection.children.rawValue:
            
            var currentPeople: [Person]
            if indexPath.section == EntrySection.adults.rawValue {
                currentPeople = adults
            } else {
                currentPeople = children
            }
            
            let selectedPerson = currentPeople[indexPath.row]
            let name = selectedPerson.name ?? ""
            let lastName = entry?.name ?? ""
            let phone = selectedPerson.phone ?? ""
            let email = selectedPerson.email ?? ""
            
            var actionSheet: UIAlertController?
            var onlyEmail = false

            if phone.isEmpty && !email.isEmpty {
                onlyEmail = true
            }
            
            actionSheet = UIAlertController(title: "\(name) \(lastName)", message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
            
            if !phone.isEmpty {
                
                actionSheet?.addAction(UIAlertAction(title: "Call", style: UIAlertActionStyle.default, handler: { (action) in
                    self.callNumber(phoneNumber: phone)
                }))
                
                actionSheet?.addAction(UIAlertAction(title: "Text", style: UIAlertActionStyle.default, handler: { (action) in
                    let tvc = self.configuredMessageComposeViewController(recipients: [phone])
                    self.present(tvc, animated: true, completion: nil)
                }))
            }

            
            if !email.isEmpty {
                
                var title = "Email"
                if onlyEmail {
                    title = "Email \(name)"
                }
                
                actionSheet?.addAction(UIAlertAction(title: title, style: UIAlertActionStyle.default, handler: { (action) in
                    let mvc = self.configuredMailComposeViewController(recipients: [email])
                    self.present(mvc, animated: true, completion: nil)
                }))
                
            }
            
            actionSheet?.addAction(UIAlertAction(title: "Add to Contacts", style: UIAlertActionStyle.default, handler: { (action) in
                
                let contact = CNMutableContact()
                
                contact.givenName = name
                contact.familyName = lastName
                
                let email = CNLabeledValue(label: CNLabelHome, value: email as NSString)
                contact.emailAddresses = [email]
                
                if self.entry?.phone != "" {
                    contact.phoneNumbers.append(
                        CNLabeledValue(label:CNLabelPhoneNumberMain,
                                       value:CNPhoneNumber(stringValue: (self.entry?.phone)!)
                        ))
                }
                contact.phoneNumbers.append(CNLabeledValue(label:CNLabelPhoneNumberMobile,value:CNPhoneNumber(stringValue:phone)))
                
                if let address = self.entry?.address {
                    let homeAddress = CNMutablePostalAddress()
                    if let street = address.street {
                        homeAddress.street = street
                    }
                    if let city = address.city {
                        homeAddress.city = city
                    }
                    if let state = address.state {
                        homeAddress.state = state
                    }
                    if let zip = address.zip {
                        homeAddress.postalCode = zip
                    }
                    contact.postalAddresses = [CNLabeledValue(label:CNLabelHome, value:homeAddress)]
                }
                
                
                // Saving the newly created contact
                let store = CNContactStore()
                let saveRequest = CNSaveRequest()
                
                if CNContactStore.authorizationStatus(for: .contacts) ==  .notDetermined || CNContactStore.authorizationStatus(for: .contacts) == .denied {
                    store.requestAccess(for: .contacts, completionHandler: { (authorized: Bool, error: Error?) -> Void in
                        if authorized {
                            saveRequest.add(contact, toContainerWithIdentifier:nil)
                            try! store.execute(saveRequest)
                            
                            self.presentNotification(title: "Success", firstName: name, lastName: lastName, message: "was successfully added to Contacts.")
                            
                        } else {
                            
                            self.presentNotification(title: "Permission Denied", firstName: name, lastName: lastName, message: "was not added to Contacts because you denied permission. You must go to Settings and allow access to Contacts to change this.")
                        }
                    })
                } else if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
                    saveRequest.add(contact, toContainerWithIdentifier:nil)
                    try! store.execute(saveRequest)
                    
                    self.presentNotification(title: "Success", firstName: name, lastName: lastName, message: "was successfully added to Contacts.")
                }
                
            }))

            actionSheet?.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
            self.present(actionSheet!, animated: true, completion: nil)
            
        default:
            
            break
            
        }

        tableView.deselectRow(at: indexPath, animated: false)
        
    }
    
    func presentNotification(title: String, firstName: String, lastName: String, message: String) {
        let notification = UIAlertController(title: title, message: "\(firstName) \(lastName) \(message)", preferredStyle: .alert)
        notification.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(notification, animated: false, completion: nil)
    }
    
    func callNumber(phoneNumber: String) {
        
        if let phoneCallURL = URL(string: "tel://\(phoneNumber)") {
            
            let application:UIApplication = UIApplication.shared
            if (application.canOpenURL(phoneCallURL)) {
                application.open(phoneCallURL, options: [:], completionHandler: nil)
            }
        }
    }
    
    func generateInfoBody(subject: Bool) -> String {
        var body = ""
        if (!subject) {
            body = "\(title!)\n\n"
        }
        if let phone = entry?.phone {
            body = body + "Home Phone: " + phone + "\n"
        }
        if let email = entry?.email {
            body = body + "Email: " + email + "\n"
        }
        if entry?.phone != nil || entry?.email != nil {
            body = body + "\n"
        }
        if let address = entry?.address {
            body = body + "Address:" + "\n"
            if let street = address.street {
                body = body + street + "\n"
            }
            if let line2 = address.line2 {
                body = body + line2 + "\n"
            }
            if let line3 = address.line3 {
                body = body + line3 + "\n"
            }
            if !address.getCityStateZipString().isEmpty {
                body = body + address.getCityStateZipString() + "\n"
            }
            body = body + "\n"
        }
        for person in adults {
            if let name = person.name {
                body = body + name + "\n"
            }
            if let phone = person.phone {
                body = body + phone + "\n"
            }
            if let email = person.email {
                body = body + email + "\n"
            }
            body = body + "\n"
        }
        for person in children {
            if let name = person.name {
                body = body + name + "\n"
            }
            if let phone = person.phone {
                body = body + phone + "\n"
            }
            if let email = person.email {
                body = body + email + "\n"
            }
            body = body + "\n"
        }
        return body
    }
    
    func configuredMessageComposeViewController(recipients: [String]) -> MFMessageComposeViewController {
        
        let textMessageVC = MFMessageComposeViewController()
        textMessageVC.messageComposeDelegate = self
        
        textMessageVC.recipients = recipients
        
        return textMessageVC
        
    }
    
    func shareEntryByText() -> MFMessageComposeViewController {
        
        let textMessageVC = MFMessageComposeViewController()
        textMessageVC.messageComposeDelegate = self
        
        textMessageVC.body = generateInfoBody(subject: false)
        
        return textMessageVC
        
    }
    
    func configuredMailComposeViewController(recipients: [String]) -> MFMailComposeViewController {
        
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        
        mailComposerVC.setToRecipients(recipients)
        
        return mailComposerVC
    }
    
    func shareEntryByEmail() -> MFMailComposeViewController {
        
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        
        mailComposerVC.setSubject(title!)
        mailComposerVC.setMessageBody(generateInfoBody(subject: true), isHTML: false)
        
        return mailComposerVC
        
    }
    
    @IBAction func shareEntry(_ sender: Any) {
        
        let actionSheet = UIAlertController(title: "Share Entry", message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Text", style: UIAlertActionStyle.default, handler: { (action) in
            if MFMessageComposeViewController.canSendText() {
                self.present(self.shareEntryByText(), animated: false, completion: nil)
            } else {
                self.displayAlert(title: "Error", message: "This device cannot send texts.")
            }
        }))
        actionSheet.addAction(UIAlertAction(title: "Email", style: UIAlertActionStyle.default, handler: { (action) in
            if MFMailComposeViewController.canSendMail() {
                self.present(self.shareEntryByEmail(), animated: false, completion: nil)
            } else {
                self.displayAlert(title: "Error", message: "This device cannot send mail.")
            }
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        
        self.present(actionSheet, animated: true, completion: nil)

    }
    
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }

    func getAddressLines(address: Address) -> [String] {
        var addressLines: [String] = []
        if address.street != "" {
            addressLines.append(address.street!)
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
    
    @IBAction func editButtonPressed(_ sender: Any) {
        
        let addEntryVC = self.storyboard?.instantiateViewController(withIdentifier: "AddEntryViewController") as! AddEntryViewController
        
        var newPeople: [[Person]] = [[],[]]
        var newPersonTypes: [String] = []
        var newBirthOrders: [Int] = []
        if let people = self.entry?.people {
            for person in people {
                let newPerson = Person(type: person.type!, name: person.name!, phone: person.phone!, email: person.email!, birthOrder: person.birthOrder!, uid: person.uid!)
                if newPerson.type! != PersonType.child.rawValue {
                    newPeople[0].append(newPerson)
                } else {
                    newPeople[1].append(newPerson)
                }
                if !newPersonTypes.contains(newPerson.type!) {
                    newPersonTypes.append(newPerson.type!)
                }
                if !newBirthOrders.contains(newPerson.birthOrder!) {
                    newBirthOrders.append(newPerson.birthOrder!)
                }
            }
        }
        
        addEntryVC.people = newPeople
        addEntryVC.personTypes = newPersonTypes
        addEntryVC.birthOrders = newBirthOrders
        addEntryVC.entryUid = (self.entry?.uid)!
        addEntryVC.group = self.group
        addEntryVC.entry = self.entry
        
        addEntryVC.textFieldValues = [(self.entry?.name)!, (self.entry?.phone)!, (self.entry?.email)!, (self.entry?.address?.street)!, (self.entry?.address?.line2)!, (self.entry?.address?.line3)!, (self.entry?.address?.city)!, (self.entry?.address?.state)!, (self.entry?.address?.zip)!]
        
        self.navigationController?.pushViewController(addEntryVC, animated: true)
        
    }
    
    func displayAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: false, completion: nil)
    }

}

class EntryDetailCell: UITableViewCell {
    
    @IBOutlet weak var stackView: UIStackView!
    
    func removeSubviews() {
        stackView.removeAllArrangedSubviews()
    }
    
    func setUp(phone: String?) {
        addLabel(with: phone)
    }
    
    func setUp(email: String?) {
        addLabel(with: email)
    }
    
    func setUp(address: Address?) {
        addLabel(with: address?.street)
        addLabel(with: address?.line2)
        addLabel(with: address?.line3)
        addLabel(with: address?.getCityStateZipString())
    }
    
    func setUp(person: Person) {
        addLabel(with: person.name)
        addLabel(with: person.phone)
        addLabel(with: person.email)
    }
    
    private func addLabel(with text: String?) {
        if let text = text, !text.trimmingCharacters(in: .whitespaces).isEmpty {
            let label = UILabel()
            label.text = text
            label.heightAnchor.constraint(equalToConstant: 22.0).isActive = true
            stackView.addArrangedSubview(label)
        }
    }
    
}
