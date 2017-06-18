//
//  AddFamilyViewController.swift
//  ValleybrookCommunityChurch
//
//  Created by Adam Zarn on 6/16/17.
//  Copyright © 2017 Adam Zarn. All rights reserved.
//

import UIKit

class AddFamilyViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var pvc: DirectoryViewController?
    
    @IBOutlet weak var peopleTableView: UITableView!
    @IBOutlet weak var addressTableView: UITableView!
    var pickerView: UIPickerView!
    var dimView: UIView?
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var topStackView: UIStackView!
    @IBOutlet weak var bottomStackView: UIStackView!
    
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var homePhoneTextField: UITextField!
    @IBOutlet weak var familyEmailTextField: UITextField!
    
    @IBOutlet weak var addAddressView: UIView!
    //Add Address View
    @IBOutlet weak var streetTextField: UITextField!
    @IBOutlet weak var line2TextField: UITextField!
    @IBOutlet weak var line3TextField: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var stateTextField: UITextField!
    @IBOutlet weak var zipTextField: UITextField!
    
    @IBOutlet weak var addPersonView: UIView!
    //Add Person View
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var personTypeTextField: UITextField!
    @IBOutlet weak var birthOrderTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    
    var people: [[PersonMO]] = [[],[]]
    var personTypes: [String] = []
    var editingPerson = false
    var indexPathBeingEdited: IndexPath?
    var address: AddressMO = AddressMO(street: "", line2: "", line3: "", city: "", state: "", zip: "")
    var typeOptions = ["", "Husband", "Wife", "Single", "Child"]
    let birthOrderOptions = [1,2,3,4,5,6,7,8,9,10]
    var birthOrders: [Int] = []
    let stateOptions = ["", "IL", "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA", "HI", "ID",
                        "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA", "MI", "MN", "MS", "MO", "MT",
                        "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI",
                        "SC", "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY"]

    var currentTextField: UITextField?
    
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addPersonView.isHidden = true
        addPersonView.isUserInteractionEnabled = false
        addPersonView.layer.cornerRadius = 5
        
        addAddressView.isHidden = true
        addAddressView.isUserInteractionEnabled = false
        addAddressView.layer.cornerRadius = 5
        
        dimView = UIView(frame:UIScreen.main.bounds)
        dimView?.backgroundColor = UIColor(white: 0.4, alpha: 0.5)
        
        peopleTableView.delegate = self
        peopleTableView.dataSource = self
        
        let f = addressTableView.frame.origin
        let s = addressTableView.frame.size
        addressTableView.frame = CGRect(x: f.x, y: f.y, width: s.width, height: 120)
        addressTableView.isScrollEnabled = false
        addressTableView.separatorStyle = .none
        
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 44))
        toolBar.barStyle = .default
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissPickerView))
        
        toolBar.items = [flex, done]
        
        pickerView = UIPickerView(frame: CGRect(x: 0, y: toolBar.frame.size.height, width: screenWidth, height: 200))
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.showsSelectionIndicator = true
        
        let inputView = UIView(frame:CGRect(x: 0, y: 0, width: screenWidth, height: toolBar.frame.size.height + pickerView.frame.size.height))
        inputView.backgroundColor = .clear
        inputView.addSubview(toolBar)
        inputView.addSubview(pickerView)
        
        personTypeTextField.inputView = inputView
        birthOrderTextField.inputView = inputView
        stateTextField.inputView = inputView
        
        let allTextFields = getTextFields(view: self.view)
        for textField in allTextFields {
            textField.autocorrectionType = .no
        }
        
    }
    
    func getTextFields(view: UIView) -> [UITextField] {
        var results = [UITextField]()
        for subview in view.subviews as [UIView] {
            if let textField = subview as? UITextField {
                results += [textField]
            } else {
                results += getTextFields(view: subview)
            }
        }
        return results
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField == phoneTextField || textField == homePhoneTextField {
            
            let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
            let components = (newString as NSString).components(separatedBy: NSCharacterSet.decimalDigits.inverted)
            
            let decimalString = components.joined(separator: "") as NSString
            let length = decimalString.length
            let hasLeadingOne = length > 0 && decimalString.character(at: 0) == (1 as unichar)
            
            if length == 0 || (length > 10 && !hasLeadingOne) || length > 11 {
                let newLength = (textField.text! as NSString).length + (string as NSString).length - range.length as Int
                
                return (newLength > 10) ? false : true
            }
            var index = 0 as Int
            let formattedString = NSMutableString()
            
            if hasLeadingOne {
                formattedString.append("1 ")
                index += 1
            }
            if (length - index) > 3 {
                let areaCode = decimalString.substring(with: NSMakeRange(index, 3))
                formattedString.appendFormat("%@-", areaCode)
                index += 3
            }
            if length - index > 3 {
                let prefix = decimalString.substring(with: NSMakeRange(index, 3))
                formattedString.appendFormat("%@-", prefix)
                index += 3
            }
            
            let remainder = decimalString.substring(from: index)
            formattedString.append(remainder)
            textField.text = formattedString as String
            return false
            
        } else {
            return true
        }
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func addPersonButtonPressed(_ sender: Any) {
        addPersonButtonActions()
    }
    
    @IBAction func editAddressButtonPressed(_ sender: Any) {
        addAddressView.isHidden = false
        
        self.view.addSubview(dimView!)
        self.view.bringSubview(toFront: dimView!)
        
        addAddressView.isHidden = false
        addAddressView.isUserInteractionEnabled = true
        self.view.bringSubview(toFront: addAddressView)
        
        streetTextField.becomeFirstResponder()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if personTypeTextField.text == "Child" {
            birthOrderTextField.isEnabled = true
        } else {
            birthOrderTextField.isEnabled = false
        }
    }
    
    func dismissAddPersonView() {
        self.addPersonView.isHidden = true
        self.addPersonView.isUserInteractionEnabled = false
        dimView?.removeFromSuperview()
        firstNameTextField.text = ""
        personTypeTextField.text = ""
        birthOrderTextField.text = ""
        phoneTextField.text = ""
        emailTextField.text = ""
    }
    
    func dismissAddAddressView() {
        self.addAddressView.isHidden = true
        self.addAddressView.isUserInteractionEnabled = false
        dimView?.removeFromSuperview()
    }
    
    @IBAction func cancelPersonButtonPressed(_ sender: Any) {
        dismissAddPersonView()
    }
    
    @IBAction func submitAddressButtonPressed(_ sender: Any) {
        
        if streetTextField.text == "" &&
            line2TextField.text == "" &&
            line3TextField.text == "" &&
            cityTextField.text == "" &&
            stateTextField.text == "" &&
            zipTextField.text == "" {
            print("Nothing entered")
        } else {
            if streetTextField.text == "" {
                displayAlert(title: "No Street", message: "A valid address must include a street.")
                return
            }
            if cityTextField.text == "" {
                displayAlert(title: "No City", message: "A valid address must include a city.")
                return
            }
            if stateTextField.text == "" {
                displayAlert(title: "No State", message: "A valid address must include a state.")
                return
            }
            if zipTextField.text == "" {
                displayAlert(title: "No Zip Code", message: "A valid address must include a zip code.")
                return
            } else if (zipTextField.text?.length)! < 5 {
                displayAlert(title: "Invalid Zip Code", message: "A zip code must be at least 5 digits long.")
                return
            }
        }
        
        dismissAddAddressView()
        addressTableView.reloadData()
    }
    
    @IBAction func cancelAddressButtonPressed(_ sender: Any) {
        dismissAddAddressView()
    }

    @IBAction func submitPersonButtonPressed(_ sender: Any) {
        
        if !validateNewPerson() {
            return
        }
        
        let name = firstNameTextField.text!
        let type = personTypeTextField.text!
        
        var phone = ""
        if phoneTextField.text! != "" {
            phone = phoneTextField.text!
        }
        
        var email = ""
        if emailTextField.text! != "" {
            email = emailTextField.text!
        }
        
        var birthOrder = 0
        if birthOrderTextField.text! != "" {
            birthOrder = Int(birthOrderTextField.text!)!
        }
        
        if editingPerson {
            
            let ip = indexPathBeingEdited!
            people[ip.section][ip.row] = PersonMO(type: type, name: name, phone: phone, email: email, birthOrder: birthOrder)
        
        } else {
            let newPerson = PersonMO(type: type, name: name, phone: phone, email: email, birthOrder: birthOrder)
            if type != "Child" {
                people[0].insert(newPerson, at: people[0].count)
            } else {
                people[1].insert(newPerson, at: people[1].count)
            }
        }
        
        editingPerson = false
        dismissAddPersonView()
        peopleTableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView == addressTableView {
            return nil
        }
        return ["Adults", "Children"][section]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == addressTableView {
            return 1
        }
        return people[section].count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == addressTableView {
            return 1
        }
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == addressTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddressCell") as! AddressCell
            address.street = streetTextField.text
            address.line2 = line2TextField.text
            address.line3 = line3TextField.text
            address.city = cityTextField.text
            address.state = stateTextField.text
            address.zip = zipTextField.text
            cell.setUpCell(address: address)
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "PersonCell") as! PersonCell
        let person = people[indexPath.section][indexPath.row]
        cell.setUpCell(name: person.name!, type: person.type!, birthOrder: person.birthOrder!, phone: person.phone!, email: person.email!)
        return cell
    }
    
    func displayAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: false, completion: nil)
    }
    
    func displayAlertAndDismiss(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            self.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: false, completion: nil)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == stateTextField {
            if textField.text != "" {
                pickerView.selectRow(stateOptions.index(of: textField.text!)!, inComponent: 0, animated: false)
            } else {
                pickerView.selectRow(0, inComponent: 0, animated: false)
            }
        }
        if textField == personTypeTextField {
            if textField.text != "" {
                pickerView.selectRow(typeOptions.index(of: textField.text!)!, inComponent: 0, animated: false)
            } else {
                pickerView.selectRow(0, inComponent: 0, animated: false)
            }
        }
        if textField == birthOrderTextField {
            if textField.text != "" {
                pickerView.selectRow(birthOrderOptions.index(of: Int(textField.text!)!)!, inComponent: 0, animated: false)
            } else {
                pickerView.selectRow(0, inComponent: 0, animated: false)
            }
        }
        currentTextField = textField
        textField.becomeFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if currentTextField == stateTextField {
            return stateOptions.count
        } else if currentTextField == personTypeTextField {
            return typeOptions.count
        } else {
            return birthOrderOptions.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if currentTextField == stateTextField {
            return stateOptions[row]
        } else if currentTextField == personTypeTextField {
            return typeOptions[row]
        } else {
            return String(describing: birthOrderOptions[row])
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if currentTextField == stateTextField {
            stateTextField.text = stateOptions[row]
        } else if currentTextField == personTypeTextField {
            personTypeTextField.text = typeOptions[row]
        } else {
            birthOrderTextField.text = String(describing: birthOrderOptions[row])
        }
    }
    
    func dismissPickerView() {
        currentTextField?.resignFirstResponder()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cell = self.tableView(tableView, cellForRowAt: indexPath)
        return cell.frame.size.height
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView == peopleTableView {
            let person = people[indexPath.section][indexPath.row]
            addPersonButtonActions()
            if person.type == "Child" {
                birthOrderTextField.isEnabled = true
                birthOrderTextField.text = String(describing: person.birthOrder)
                for i in birthOrders {
                    if birthOrders[i] == person.birthOrder {
                        birthOrders.remove(at: i)
                    }
                }
            }
            firstNameTextField.text = person.name
            personTypeTextField.text = person.type
            emailTextField.text = person.email
            phoneTextField.text = person.phone
            
            var i = 0
            for type in personTypes {
                if type == person.type {
                    personTypes.remove(at: i)
                }
                i = i + 1
            }
            editingPerson = true
            indexPathBeingEdited = indexPath
        }
        
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    @IBAction func submitButtonPressed(_ sender: Any) {
        
        if lastNameTextField.text == "" {
            displayAlert(title: "Missing Last Name", message: "A new family must have a last name.")
            return
        }
        
        if people[0].count == 0 {
            displayAlert(title: "No Adults", message: "A new family must have at least 1 adult.")
            return
        }
        
        if people[0].count == 1 {
            if people[0][0].type == "Husband" {
                displayAlert(title: "Missing Spouse", message: "A husband must have a wife.")
            } else if people[0][0].type == "Wife" {
                displayAlert(title: "Missing Spouse", message: "A wife must have a husband.")
            }
            return
        }
        
        let alert = UIAlertController(title: "Submit", message: "Are you sure you want to continue?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
            let allPeople = self.people[0] + self.people[1]
            let newFamily = FamilyMO(name: self.lastNameTextField.text!, phone: self.homePhoneTextField.text!, email: self.familyEmailTextField.text!, address: self.address, people: allPeople)
            
            if GlobalFunctions.sharedInstance.hasConnectivity() {
                
                FirebaseClient.sharedInstance.addFamily(family: newFamily) { success in
                    if success {
                        self.pvc?.familiesWithSections = []
                        self.pvc?.comingFromUpdate = true
                        self.displayAlertAndDismiss(title: "Success", message: "The new family was added to the database.")
                    } else {
                        self.displayAlert(title: "Failure", message: "The new family was not added to the database.")
                    }
                }
                
            } else {
                self.displayAlert(title: "No Internet Connection", message: "Please establish an internet connection and try again.")
            }
        }))

        alert.addAction(UIAlertAction(title: "No", style: .default, handler: nil))
        self.present(alert, animated: false, completion: nil)
        
    }
    
    func validateNewPerson() -> Bool {
        
        if firstNameTextField.text! == "" {
            displayAlert(title: "No Name", message: "You must enter a first name.")
            return false
        }
        
        if personTypeTextField.text! == "" {
            displayAlert(title: "No Type", message: "Each person must have a type.")
            return false
        }
        
        if (phoneTextField.text?.length)! < 12 && (phoneTextField.text?.length)! > 0 {
            displayAlert(title: "Bad Phone Number", message: "Phone Number must be 12 characters long.")
            return false
        }
        
        if personTypeTextField.text == "Child" && birthOrderTextField.text == "" {
            displayAlert(title: "Missing Birth Order", message: "Children must have a birth order.")
            return false
        }
        
        if personTypeTextField.text != "Child" {
            if personTypes.contains(personTypeTextField.text!) {
                displayAlert(title: "Duplicate Person Type", message: "Families can only contain one \(personTypeTextField.text!).")
                return false
            }
        }
        
        if personTypeTextField.text == "Husband" || personTypeTextField.text == "Wife" {
            if personTypes.contains("Single") {
                displayAlert(title: "Error", message: "Married couples and adult Singles cannot be in the same family.")
                return false
            }
            
        }
        
        if personTypeTextField.text == "Single" {
            if personTypes.contains("Husband") || personTypes.contains("Wife") {
                displayAlert(title: "Error", message: "Married couples and adult Singles cannot be in the same family.")
                return false
            }
        }
        
        if birthOrderTextField.text != "" {
            let birthOrderInt = Int(birthOrderTextField.text!)!
            if birthOrders.contains(birthOrderInt) {
                displayAlert(title: "Bad Birth Order", message: "Birth Order must be unique.")
                return false
            } else {
                birthOrders.append(birthOrderInt)
            }
        }
        personTypes.append(personTypeTextField.text!)
        return true
    }
    
    func addPersonButtonActions() {
        addPersonView.isHidden = false
        
        if personTypeTextField.text != "Child" {
            birthOrderTextField.isEnabled = false
        }
        
        self.view.addSubview(dimView!)
        self.view.bringSubview(toFront: dimView!)
        
        addPersonView.isHidden = false
        addPersonView.isUserInteractionEnabled = true
        self.view.bringSubview(toFront: addPersonView)
        
        firstNameTextField.becomeFirstResponder()
    }
    
}

class PersonCell: UITableViewCell {
    
    @IBOutlet weak var line1: UILabel!
    @IBOutlet weak var line2: UILabel!
    @IBOutlet weak var line3: UILabel!
    
    func setUpCell(name: String, type: String, birthOrder: Int, phone: String, email: String) {
        if type != "Child" {
            self.line1.text = name + ", " + type
        } else {
            var birthOrderString = "st child"
            if birthOrder == 2 {
                birthOrderString = "nd child"
            } else if birthOrder == 3 {
                birthOrderString = "rd child"
            } else if birthOrder > 3 {
                birthOrderString = "th child"
            }
            self.line1.text = name + ", " + String(describing: birthOrder) + birthOrderString
        }
        self.line2.attributedText = GlobalFunctions.sharedInstance.getFormattedString(string1: "Phone: ", string2: phone)
        self.line3.attributedText = GlobalFunctions.sharedInstance.getFormattedString(string1: "Email: ", string2: email)
    }
}

class AddressCell: UITableViewCell {
    
    @IBOutlet weak var line1: UILabel!
    @IBOutlet weak var line2: UILabel!
    @IBOutlet weak var line3: UILabel!
    @IBOutlet weak var line4: UILabel!
    
    func setUpCell(address: AddressMO) {
        
        self.line1.attributedText = GlobalFunctions.sharedInstance.getFormattedString(string1: "Street: ", string2: address.street!)
        self.line2.attributedText = GlobalFunctions.sharedInstance.getFormattedString(string1:"Line 2: ", string2: address.line2!)
        self.line3.attributedText = GlobalFunctions.sharedInstance.getFormattedString(string1:"Line 3: ", string2: address.line3!)
        let cityStateZip = address.city! + ", " + address.state! + " " + address.zip!
        if address.city! != "" && address.state! != "" && address.zip! != "" {
            self.line4.attributedText = GlobalFunctions.sharedInstance.getFormattedString(string1:"City, State, Zip: ", string2: cityStateZip)
        } else {
            self.line4.attributedText = GlobalFunctions.sharedInstance.getFormattedString(string1:"City, State, Zip: ", string2: "")
        }
    }
    
}

