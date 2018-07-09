//
//  CreateAccountViewController.swift
//  ValleybrookCommunityChurch
//
//  Created by Adam Zarn on 9/12/17.
//  Copyright © 2017 Adam Zarn. All rights reserved.
//

import UIKit
import Firebase

class CreateAccountViewController: UIViewController {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var aiv: UIActivityIndicatorView!
    
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var verifyPasswordTextField: UITextField!
    @IBOutlet weak var submitButton: UIBarButtonItem!

    //Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let textFields = [firstNameTextField, lastNameTextField, emailTextField, passwordTextField, verifyPasswordTextField]
        
        for textField in textFields {
            formatTextField(textField: textField!)
        }
    
        submitButton.tintColor = GlobalFunctions.shared.themeColor()
        self.navigationController?.navigationBar.barTintColor = GlobalFunctions.shared.themeColor()
        self.navigationController?.navigationBar.isTranslucent = false
        
    }
    
    func formatTextField(textField: UITextField) {
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.layer.borderWidth = 1.0
        textField.layer.cornerRadius = 2.0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setUpView()
    }
    
    //IBActions
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func submitButtonPressed(_ sender: Any) {
        aiv.isHidden = false
        aiv.startAnimating()
        if firstNameTextField.text != "" && lastNameTextField.text != "" {
            verifyPassword()
        } else {
            displayAlert(title: "Incomplete Name", message: "You must provide a first and last name.")
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
            createUser()
        }
    }
    
    func createUser() {
        let firstName = firstNameTextField.text?.trimmingCharacters(in: .whitespaces)
        let lastName = lastNameTextField.text?.trimmingCharacters(in: .whitespaces)
        let displayName = "\(firstName!) \(lastName!)"
        let email = emailTextField.text
        let password = passwordTextField.text
        
        if GlobalFunctions.shared.hasConnectivity() {
            
            Auth.auth().createUser(withEmail: email!, password: password!) { (user, error) in
                if let user = user {
                    let changeRequest = user.createProfileChangeRequest()
                    changeRequest.displayName = displayName
                    changeRequest.commitChanges { error in
                        if let error = error {
                            print(error)
                            self.displayAlert(title: "Error", message: "We were unable to create an account for you. Please try again.")
                        } else {
                            let newUser = User(uid: user.uid, name: displayName, groups: [])
                            FirebaseClient.shared.addNewUser(user: newUser) { (success) in
                                if let success = success {
                                    if success {
                                        let groupsNC = self.storyboard?.instantiateViewController(withIdentifier: "DirectoryNavigationController") as! MyNavigationController
                                        let groupsVC = groupsNC.viewControllers[0] as! GroupsViewController
                                        groupsVC.user = newUser
                                        self.present(groupsNC, animated: true, completion: nil)
                                    }
                                } else {
                                    self.displayAlert(title: "Error", message: "We were unable to create an account for you. Please try again.")
                                }
                            }
                        }
                    }
                } else {
                    if email == "" {
                        self.displayAlert(title: "No Email", message: "You must provide an email.")
                    } else {
                        self.displayAlert(title: "Error", message: (error?.localizedDescription)!)
                    }
                }
            }
            
        } else {
            displayAlert(title: "No Internet Connectivity", message: "Establish an Internet Connection and try again.")
        }
        
    }
    
}

