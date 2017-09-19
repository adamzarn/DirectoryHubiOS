//
//  FirebaseClient.swift
//  ValleybrookCommunitygroup
//
//  Created by Adam Zarn on 6/6/17.
//  Copyright © 2017 Adam Zarn. All rights reserved.
//


import UIKit
import Firebase
import FirebaseStorage
import CoreData

class FirebaseClient: NSObject {
    
    let ref = Database.database().reference()
    let storageRef = Storage.storage().reference()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    func createGroup(userUid: String, userGroups: [String], group: Group, completion: @escaping (_ success: Bool?, _ message: NSString?, _ updatedUserGroups: [String]?) -> ()) {
        var groupsRef: DatabaseReference
        var successMessage: NSString!
        var updatedUserGroups: [String] = userGroups
        if group.uid == "" {
            successMessage = "Your group was successfully created."
            groupsRef = self.ref.child("Groups").childByAutoId()
            updatedUserGroups.append(groupsRef.key)
        } else {
            successMessage = "Your group was successfully edited."
            groupsRef = self.ref.child("Groups").child(group.uid)
        }
        groupsRef.setValue(group.toAnyObject()) { (error, ref) -> Void in
            if error != nil {
                completion(false, "error", [])
            } else {
                self.updateUserGroups(userUid: userUid, groups: updatedUserGroups) { (success) -> () in
                    if let success = success {
                        if success {
                            let data = group.profilePicture
                            let imageRef = self.storageRef.child("\(groupsRef.key).jpg")
                            
                            imageRef.putData(data, metadata: nil) { (metadata, error) in
                                guard metadata != nil else {
                                    completion(false, "error", [])
                                    return
                                }
                                completion(true, successMessage, updatedUserGroups)
                            }
                        } else {
                            completion(false, "error", [])
                        }
                    } else {
                        completion(false, "error", [])
                    }
                }
            }
        }
    }
    
    func addEntry(groupUid: String, entry: Entry, completion: @escaping (_ success: Bool?) -> ()) {
        let directoryRef = self.ref.child("Directories").child(groupUid)
        
        let name = entry.name!
        let phone = entry.phone!
        let email = entry.email!
        let address = entry.address!
        let people = entry.people!
        
        var newEntryRef: DatabaseReference!
        if entry.uid == "" {
            newEntryRef = directoryRef.childByAutoId()
        } else {
            newEntryRef = directoryRef.child(entry.uid!)
        }
        
        newEntryRef.child("name").setValue(name) { (error, ref) -> Void in
            if error != nil {
                completion(false)
            }
        }

        newEntryRef.child("phone").setValue(phone) { (error, ref) -> Void in
            if error != nil {
                completion(false)
            }
        }

        newEntryRef.child("email").setValue(email) { (error, ref) -> Void in
            if error != nil {
                completion(false)
            }
        }
        
        let addressRef = newEntryRef.child("Address")
        let newAddress = Address(street: address.street!, line2: address.line2!, line3: address.line3!, city: address.city!, state: address.state!, zip: address.zip!)
        addressRef.setValue(newAddress.toAnyObject()) { (error, ref) -> Void in
            if error != nil {
                completion(false)
            }
        }
        
        let peopleRef = newEntryRef.child("People")
        peopleRef.removeValue()
        for person in people {
            let newPersonRef = peopleRef.childByAutoId()
            let newPerson = Person(type: person.type!, name: person.name!, phone: person.phone!, email: person.email!, birthOrder: person.birthOrder!, uid: "")
            newPersonRef.setValue(newPerson.toAnyObject()) { (error, ref) -> Void in
                if error != nil {
                    completion(false)
                }
            }
        }
        
        completion(true)

    }
    
    func updateDirectory(uid: String, completion: @escaping (_ entries: [Entry]?, _ error: NSString?) -> ()) {
        self.ref.child("Directories").child(uid).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                let directory = (snapshot.value! as! NSDictionary)
                
                var entries: [Entry] = []
                
                for (key, value) in directory {
                    
                    let uid = key as! String
                    
                    let record = value as! NSDictionary
                    let name = record["name"] as! String
                    let email = record["email"] as! String
                    let phone = record["phone"] as! String
                    
                    let addressDict = record["Address"] as! NSDictionary
                    let street = addressDict["street"] as! String
                    let city = addressDict["city"] as! String
                    let state = addressDict["state"] as! String
                    let zip = addressDict["zip"] as! String
                    let line2 = addressDict["line2"] as! String
                    let line3 = addressDict["line3"] as! String
                    
                    let address = Address(street: street, line2: line2, line3: line3, city: city, state: state, zip: zip)
                    
                    var people: [Person] = []
                    let peopleDict = record["People"] as! [String: Any]
                    for (key, value) in peopleDict {
                        let record = value as! NSDictionary
                        let name = record["name"] as! String
                        let birthOrder = record["birthOrder"]! as! Int
                        let email = record["email"] as! String
                        let phone = record["phone"] as! String
                        let type = record["type"] as! String
                        let newPerson = Person(type: type, name: name, phone: phone, email: email, birthOrder: birthOrder, uid: key)
                        people.append(newPerson)
                    }
                    
                    let entry = Entry(uid: uid, name: name, phone: phone, email: email, address: address, people: people)
                    
                    entries.append(entry)
                    
                }
                
                completion(entries, nil)
                
            } else {
                completion(nil, "No Data")
            }
        })
    }
    
    func deleteEntry(groupUid: String, entryUid: String, completion: @escaping (_ success: Bool?) -> ()) {
        let directoryRef = self.ref.child("Directories").child(groupUid).child(entryUid)
        directoryRef.removeValue() { (error, ref) -> Void in
            if error != nil {
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    func deleteGroup(uid: String, completion: @escaping (_ success: Bool?) -> ()) {
        
        let groupRef = self.ref.child("Groups").child(uid)
        let directoryRef = self.ref.child("Directories").child(uid)
        let imageRef = storageRef.child("\(uid).jpg")
        
        groupRef.removeValue() { (error, ref) -> Void in
            if error != nil {
                completion(false)
            } else {
                directoryRef.removeValue() { (error, ref) -> Void in
                    if error != nil {
                        completion(false)
                    } else {
                        imageRef.delete() { (error) -> Void in
                            if error != nil {
                                completion(false)
                            } else {
                                completion(true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func getGroup(groupUid: String, completion: @escaping (_ group: Group?, _ error: NSString?) -> ()) {
        self.ref.child("Groups").child(groupUid).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                if let groupDict = (snapshot.value) {
                    let info = groupDict as! NSDictionary
                    var group: Group!
                    var admins: [Member] = []
                    var users: [Member] = []
                    for (key, value) in info["admins"] as! NSDictionary {
                        let member = Member(uid: key as! String, name: value as! String)
                        admins.append(member)
                    }
                    if let usersDict = info["users"] {
                        for (key, value) in usersDict as! NSDictionary {
                            let member = Member(uid: key as! String, name: value as! String)
                            users.append(member)
                        }
                    }
                    group = Group(uid: groupUid,
                                 name: info["name"] as! String,
                                 city: info["city"] as! String,
                                state: info["state"] as! String,
                             password: info["password"] as! String,
                               admins: admins,
                                users: users,
                            createdBy: info["createdBy"] as! String,
                         createdByUid: info["createdByUid"] as! String,
                       profilePicture: Data())
                    completion(group, nil)
                } else {
                    completion(nil, "Could not retrieve Group")
                }
            } else {
                completion(nil, "Group no longer exists")
            }
        })
    }
    
    func queryGroups(query: String, completion: @escaping (_ groups: [Group]?, _ error: NSString?) -> ()) {
        self.ref.child("Groups").queryOrdered(byChild: "name").queryStarting(atValue: query).queryLimited(toFirst: 10).observeSingleEvent(of: .value, with: { snapshot in
            if let groupsDict = (snapshot.value) {
                var groups: [Group] = []
                for (key, value) in groupsDict as! NSDictionary {
                    let info = value as! NSDictionary
                    var admins: [Member] = []
                    var users: [Member] = []
                    for (key, value) in info["admins"] as! NSDictionary {
                        let member = Member(uid: key as! String, name: value as! String)
                        admins.append(member)
                    }
                    if let usersDict = info["users"] {
                        for (key, value) in usersDict as! NSDictionary {
                            let member = Member(uid: key as! String, name: value as! String)
                            users.append(member)
                        }
                    }
                    let group = Group(uid: key as! String,
                                      name: info["name"] as! String,
                                      city: info["city"] as! String,
                                      state: info["state"] as! String,
                                      password: info["password"] as! String,
                                      admins: admins,
                                      users: users,
                                      createdBy: info["createdBy"] as! String,
                                createdByUid: info["createdByUid"] as! String,
                                      profilePicture: Data())
                    groups.append(group)
                }
                completion(groups, nil)
            } else {
                completion([], "Could not retrieve Group List")
            }
        })
    }
    
    func addNewUser(user: User, completion: @escaping (_ success: Bool?) -> ()) {
        
        let userRef = self.ref.child("Users/\(user.uid)")
        userRef.setValue(user.toAnyObject()) { (error, ref) -> Void in
            if error != nil {
                completion(false)
            } else {
                completion(true)
            }
        }

    }
    
    func getUserData(uid: String, completion: @escaping (_ user: User?, _ error: NSString?) -> ()) {
        self.ref.child("Users").child(uid).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                if let data = snapshot.value {
                    let name = (data as AnyObject).value(forKey: "name") as! String
                    var groups: [String] = []
                    if snapshot.hasChild("groups") {
                        groups = (data as AnyObject).value(forKey: "groups") as! [String]
                    }
                    let user = User(uid: uid, name: name, groups: groups)
                    completion(user, nil)
                } else {
                    completion(nil, "Data could not be retrieved")
                }
            } else {
                completion(nil, "No User")
            }
        })
    }
    
    func joinGroup(userUid: String, groupUid: String, groups: [String], users: [Member], completion: @escaping (_ success: Bool?) -> ()) {
        
        let userRef = self.ref.child("Users/\(userUid)")
        userRef.child("groups").setValue(groups) { (error, ref) -> Void in
            if error != nil {
                completion(false)
            } else {
                let groupRef = self.ref.child("Groups/\(groupUid)")
                groupRef.child("users").setValue(GlobalFunctions.shared.createMemberDict(members: users)) { (error, ref) -> Void in
                    if error != nil {
                        completion(false)
                    } else {
                        completion(true)
                    }
                }
            }
        }
    }
    
    func updateUserGroups(userUid: String, groups: [String], completion: @escaping (_ success: Bool?) -> ()) {
        
        let userRef = self.ref.child("Users/\(userUid)")
        userRef.child("groups").setValue(groups) { (error, ref) -> Void in
            if error != nil {
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    func logout(vc: UIViewController) {
        do {
            try Auth.auth().signOut()
            let loginVC = vc.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
            vc.present(loginVC, animated: true, completion: nil)
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError)")
        }
    }
    
    static let shared = FirebaseClient()
    private override init() {
        super.init()
    }
}

