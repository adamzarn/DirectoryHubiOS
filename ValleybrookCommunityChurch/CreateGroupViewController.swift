//
//  CreateGroupViewController.swift
//  ValleybrookCommunityChurch
//
//  Created by Adam Zarn on 9/13/17.
//  Copyright © 2017 Adam Zarn. All rights reserved.
//

import UIKit
import Firebase

class CreateGroupViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var aiv: UIActivityIndicatorView!
    
    @IBOutlet weak var groupNameTextField: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var stateTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var verifyPasswordTextField: UITextField!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var profilePictureImageView: UIImageView!
    
    var profilePictureImageData: Data?
    
    //Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        submitButton.setTitleColor(GlobalFunctions.shared.themeColor(), for: .normal)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setUpView()
    }
    
    override func viewWillLayoutSubviews() {
        aiv.isHidden = true
    }
    
    //IBActions
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func submitButtonPressed(_ sender: Any) {
        aiv.isHidden = false
        aiv.startAnimating()
        if groupNameTextField.text != "" {
            verifyPassword()
        } else {
            displayAlert(title: "No Group Name", message: "You must provide a name for your group.")
        }
    }
    
    //Helper methods
    
    func setUpView() {
        aiv.isHidden = true
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
    
    //Create Account methods
    
    func verifyPassword() {
        if passwordTextField.text! != verifyPasswordTextField.text! {
            self.displayAlert(title: "Password Mismatch", message: "Please make sure that your passwords match.")
        } else {
            createGroup()
        }
    }
    
    func createGroup() {
        
        let groupName = groupNameTextField.text!
        let city = cityTextField.text!
        let state = stateTextField.text!
        let password = passwordTextField.text!
        
        let newGroup = Group(uid: "", name: groupName, city: city, state: state, password: password, admins: [(Auth.auth().currentUser?.uid)!], users: [(Auth.auth().currentUser?.uid)!], createdBy: Auth.auth().currentUser?.value(forKey: "displayName") as! String, profilePicture: profilePictureImageData!)
        
        if GlobalFunctions.shared.hasConnectivity() {
            
            FirebaseClient.shared.createGroup(uid: "", group: newGroup) { (success, message) -> () in
                if let success = success, let message = message {
                    if success {
                        let alert = UIAlertController(title: "Success!", message: message as String,  preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default) { (_) in
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
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        self.present(picker, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: false, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: false, completion: nil)
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        profilePictureImageData = UIImageJPEGRepresentation(image, 0.0)
        
        profilePictureImageView.image = UIImage(data: profilePictureImageData!)
        
    }

}
    
    
