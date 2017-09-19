//
//  CreateGroupViewController.swift
//  ValleybrookCommunityChurch
//
//  Created by Adam Zarn on 9/13/17.
//  Copyright © 2017 Adam Zarn. All rights reserved.
//

import UIKit
import Firebase

class CreateGroupViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var aiv: UIActivityIndicatorView!
    
    @IBOutlet weak var groupNameTextField: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var stateTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var submitButton: UIBarButtonItem!
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var manageAdministratorsButton: UIButton!
    var statePicker: UIPickerView!
    
    var currentTextField: UITextField?
    
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    
    var user: User!
    var groupToEdit: Group?
    var delegate: PresentingViewController?
    
    var profilePictureImageData: Data?
    
    //Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.barTintColor = GlobalFunctions.shared.themeColor()
        self.navigationController?.navigationBar.isTranslucent = false
        submitButton.tintColor = GlobalFunctions.shared.themeColor()
        
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 44))
        toolBar.barStyle = .default
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
        
        toolBar.items = [flex, done]
        
        statePicker = UIPickerView(frame: CGRect(x: 0, y: toolBar.frame.size.height, width: screenWidth, height: 150))
        statePicker.delegate = self
        statePicker.dataSource = self
        statePicker.showsSelectionIndicator = true
        
        let stateInputView = UIView(frame:CGRect(x: 0, y: 0, width: screenWidth, height: toolBar.frame.size.height + statePicker.frame.size.height))
        stateInputView.backgroundColor = .clear
        stateInputView.addSubview(statePicker)
        
        stateTextField.inputView = statePicker
        stateTextField.inputAccessoryView = toolBar
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setUpView()
        aiv.isHidden = true
        aiv.stopAnimating()
    }
    
    func dismissKeyboard() {
        currentTextField?.resignFirstResponder()
    }
    
    //IBActions
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func submitButtonPressed(_ sender: Any) {
        aiv.isHidden = false
        aiv.startAnimating()
        if groupNameTextField.text == "" {
            displayAlert(title: "No Group Name", message: "You must provide a name for your group.")
        } else if cityTextField.text == "" {
            displayAlert(title: "No City", message: "You must provide a city for your group.")
        } else if stateTextField.text == "" {
            displayAlert(title: "No State", message: "You must provide a state for your group.")
        } else if passwordTextField.text == "" {
            displayAlert(title: "No Password", message: "You must provide a password for your group.")
        } else {
            createGroup()
        }
    }

    
    //Helper methods
    
    func setUpView() {
        aiv.isHidden = true
        
        if let groupToEdit = groupToEdit {
            
            self.title = "Edit Group"
            submitButton.title = "SUBMIT CHANGES"
            manageAdministratorsButton.isEnabled = true
            manageAdministratorsButton.isHidden = false
            
            groupNameTextField.text = groupToEdit.name
            cityTextField.text = groupToEdit.city
            stateTextField.text = groupToEdit.state
            passwordTextField.text = groupToEdit.password
            if groupToEdit.profilePicture.isEmpty {
                profilePictureImageView.image = UIImage(named: "ImageThumbnail.png")
            } else {
                profilePictureImageView.image = UIImage(data: groupToEdit.profilePicture)
            }
        
        } else {
            
            self.title = "Create Group"
            submitButton.title = "SUBMIT"
            manageAdministratorsButton.isEnabled = false
            manageAdministratorsButton.isHidden = true
            
        }
        
    }
    
    func displayAlert(title: String, message: String) {
        self.aiv.isHidden = true
        self.aiv.stopAnimating()
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: false, completion: nil)
    }
    
    //Text Field Delegate methods
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func createGroup() {
        
        var newGroup: Group!
        
        let groupName = groupNameTextField.text!
        let city = cityTextField.text!
        let state = stateTextField.text!
        let password = passwordTextField.text!
        
        if let groupToEdit = groupToEdit {
            newGroup = Group(uid: groupToEdit.uid, name: groupName, city: city, state: state, password: password, admins: groupToEdit.admins, users: groupToEdit.users, createdBy: groupToEdit.createdBy, createdByUid: groupToEdit.createdByUid, profilePicture: groupToEdit.profilePicture)
        } else {
            let userUid = (Auth.auth().currentUser?.uid)!
            newGroup = Group(uid: "", name: groupName, city: city, state: state, password: password, admins: [Member(uid: userUid, name: Auth.auth().currentUser?.value(forKey: "displayName") as! String)], users: [], createdBy: Auth.auth().currentUser?.value(forKey: "displayName") as! String, createdByUid: userUid, profilePicture: Data())
            if let image = profilePictureImageData {
                newGroup.profilePicture = image
            }
        }
        
        if GlobalFunctions.shared.hasConnectivity() {
            
            FirebaseClient.shared.createGroup(userUid: user.uid, userGroups: user.groups, group: newGroup) { (success, message, updatedUserGroups) -> () in
                self.aiv.isHidden = true
                self.aiv.stopAnimating()
                if let success = success, let message = message, let updatedUserGroups = updatedUserGroups {
                    if success {
                        let alert = UIAlertController(title: "Success!", message: message as String,  preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default) { (_) in
                            self.user.groups = updatedUserGroups
                            self.delegate?.user = self.user
                            self.dismiss(animated: true, completion: nil)
                        })
                        self.present(alert, animated: false, completion: nil)
                    } else {
                        self.displayAlert(title: "Error", message: "We were unable to complete your request. Please try again.")
                    }
                } else {
                    self.displayAlert(title: "Error", message: "We were unable to complete your request. Please try again.")
                }
            }
            
        } else {
            
            self.displayAlert(title: "No Internet Connectivity", message: "Establish an Internet Connection and try again.")
            
        }

    }
    
    @IBAction func uploadPhoto(_ sender: Any) {
        aiv.isHidden = false
        aiv.startAnimating()
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        self.present(picker, animated: true, completion: nil)
    }

    @IBAction func removePhoto(_ sender: Any) {
        profilePictureImageView.image = UIImage(named: "ImageThumbnail.png")
        profilePictureImageData = nil
        groupToEdit?.profilePicture = Data()
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        profilePictureImageData = UIImageJPEGRepresentation(image, 0.0)
        
        if groupToEdit != nil {
            groupToEdit?.profilePicture = profilePictureImageData!
        }
        
        profilePictureImageView.image = UIImage(data: profilePictureImageData!)
        
    }

    @IBAction func manageAdministratorsButtonPressed(_ sender: Any) {
        let manageAdminsVC = storyboard?.instantiateViewController(withIdentifier: "ManageAdministratorsViewController") as! ManageAdministratorsViewController
        manageAdminsVC.groupToEdit = self.groupToEdit
        self.navigationController?.pushViewController(manageAdminsVC, animated: true)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return GlobalFunctions.shared.getStates().count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return GlobalFunctions.shared.getStates()[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        stateTextField.text = GlobalFunctions.shared.getStates()[row]
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        if textField == stateTextField {
            if textField.text != "" {
                statePicker.selectRow(GlobalFunctions.shared.getStates().index(of: textField.text!)!, inComponent: 0, animated: false)
            } else {
                statePicker.selectRow(0, inComponent: 0, animated: false)
                textField.text = GlobalFunctions.shared.getStates()[0]
            }
        }
        currentTextField = textField
        textField.becomeFirstResponder()
    }


}

    
