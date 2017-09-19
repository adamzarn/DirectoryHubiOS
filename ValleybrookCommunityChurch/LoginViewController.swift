//
//  LoginViewController.swift
//  ValleybrookCommunityChurch
//
//  Created by Adam Zarn on 9/12/17.
//  Copyright © 2017 Adam Zarn. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let defaults = UserDefaults.standard
    
    @IBOutlet weak var aiv: UIActivityIndicatorView!
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    //Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = GlobalFunctions.shared.themeColor()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setUpView()
        subscribeToKeyboardNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        unsubscribeFromKeyboardNotifications()
    }
    
    //IBActions
    
    @IBAction func createAccountButtonPressed(_ sender: Any) {
        
        let canc = storyboard?.instantiateViewController(withIdentifier: "CreateAccountNavigationController") as! MyNavigationController
        
        self.present(canc, animated: false, completion: nil)
        
    }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        aiv.startAnimating()
        aiv.isHidden = false
        
        if emailTextField.text == "" || passwordTextField.text == "" {
            displayAlert(title: "Error", message: "You must provide an email and password to login.")
            return
        }
        
        Auth.auth().signIn(withEmail: emailTextField.text!, password: passwordTextField.text!) { (user, error) in
            if let user = user {
                self.defaults.set(self.emailTextField.text! as String, forKey: "lastEmail")
                self.defaults.set(self.passwordTextField.text! as String, forKey: "lastPassword")
                if GlobalFunctions.shared.hasConnectivity() {
                    FirebaseClient.shared.getUserData(uid: user.uid) { (user, error) in
                        let myNC = self.storyboard?.instantiateViewController(withIdentifier: "DirectoryNavigationController") as! MyNavigationController
                        let groupsVC = myNC.topViewController as! GroupsViewController
                        groupsVC.user = user
                        self.present(myNC, animated: true, completion: nil)
                    }
                } else {
                    self.displayAlert(title: "No Internet Connectivity", message: "Establish an Internet Connection and try again.")
                }
            } else {
                self.displayAlert(title: "Error", message: (error?.localizedDescription)!)
            }
        }
        
    }
    
    @IBAction func forgotPasswordButtonPressed(_ sender: Any) {
        let alert = UIAlertController(title: "Send Reset Email", message: "Would you like a password reset email to be sent to the address below?", preferredStyle: .alert)
        
        let submitAction = UIAlertAction(title: "Yes", style: .default) { (_) in
            if let field = alert.textFields?[0] {
                
                let secondAlert = UIAlertController(title: "", message: "", preferredStyle: .alert)
                secondAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                
                if field.text != "" {
                    Auth.auth().sendPasswordReset(withEmail: field.text!) { error in
                        if let errorMessage = error?.localizedDescription {
                            secondAlert.title = "Email Not Sent"
                            secondAlert.message = errorMessage
                            self.present(secondAlert, animated: false, completion: nil)
                        } else {
                            secondAlert.title = "Email Sent"
                            secondAlert.message = "Come back here when you've reset your password."
                            self.present(secondAlert, animated: false, completion: nil)
                        }
                    }
                } else {
                    secondAlert.title = "No Email"
                    secondAlert.message = "You must provide an email address."
                    self.present(secondAlert, animated: false, completion: nil)
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alert.addTextField { (textField) in
            textField.placeholder = "Email"
            textField.text = self.emailTextField.text
        }
        
        alert.addAction(submitAction)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    //Helper methods
    
    func setUpView() {
        aiv.isHidden = true
        if let email = defaults.value(forKey: "lastEmail") {
            emailTextField.text = email as? String
        }
        if let password = defaults.value(forKey: "lastPassword") {
            passwordTextField.text = password as? String
        }
    }
    
    func displayAlert(title: String, message: String) {
        self.aiv.isHidden = true
        self.aiv.stopAnimating()
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: false, completion: nil)
    }
    
    //Adjusting keyboard methods
    
    func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(LoginViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow,object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LoginViewController.keyboardWillHide),name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    }
    
    func keyboardWillShow(notification: Notification) {
        view.frame.origin.y = (-1*getKeyboardHeight(notification: notification))/2
    }
    
    func keyboardWillHide(notification: Notification) {
        view.frame.origin.y = 0
    }
    
    func getKeyboardHeight(notification: Notification) -> CGFloat {
        let userInfo = notification.userInfo!
        let keyboardSize = userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.cgRectValue.height
    }
    
    //Text Field Delegate Methods
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}

