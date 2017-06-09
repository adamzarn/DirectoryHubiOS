//
//  LoginViewController.swift
//  ValleybrookCommunityChurch
//
//  Created by Adam Zarn on 6/9/17.
//  Copyright © 2017 Adam Zarn. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var aiv: UIActivityIndicatorView!
    
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        aiv.isHidden = true
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func submitButtonPressed(_ sender: Any) {
        
        aiv.isHidden = false
        aiv.startAnimating()
        
        if GlobalFunctions.sharedInstance.hasConnectivity() {
        
            FirebaseClient.sharedInstance.getPassword { (password, error) -> () in
                
                self.aiv.stopAnimating()
                self.aiv.isHidden = true
                
                if let password = password {

                    if password == self.passwordTextField.text {
                        let navController = self.storyboard?.instantiateViewController(withIdentifier: "DirectoryNavigationController") as! UINavigationController
                        self.present(navController, animated: false, completion: nil)
                        self.defaults.set(true, forKey: "alreadyAuthenticated")
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
            
            self.aiv.stopAnimating()
            self.aiv.isHidden = true
            
            let alert = UIAlertController(title: "No Internet Connection", message: "Please establish an internet connection and try again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: false, completion: nil)
            
        }
        
    }
    
}
