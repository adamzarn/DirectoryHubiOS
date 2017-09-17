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
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    func createGroup(uid: String, group: Group, completion: @escaping (_ success: Bool?, _ message: NSString?) -> ()) {
        var groupsRef: DatabaseReference
        if uid == "" {
            groupsRef = self.ref.child("Groups").childByAutoId()
        } else {
            groupsRef = self.ref.child("Groups").child(uid)
        }
        groupsRef.setValue(group.toAnyObject()) { (error, ref) -> Void in
            if error != nil {
                completion(false, "error")
            } else {
                let data = group.profilePicture
                let storage = Storage.storage()
                let storageRef = storage.reference()
                let imageRef = storageRef.child("\(groupsRef.key).jpg")
                    
                imageRef.putData(data, metadata: nil) { (metadata, error) in
                    guard metadata != nil else {
                        completion(false, "error")
                        return
                    }
                    completion(true, "Your group was successfully created.")
                }
            }
        }
        
    }
    
    func addEntry(groupUid: String, entryUid: String, entry: EntryMO, completion: @escaping (_ success: Bool?) -> ()) {
        let directoryRef = self.ref.child("Directories").child(groupUid)
        
        let name = entry.name!
        let phone = entry.phone!
        let email = entry.email!
        let address = entry.address!
        let people = entry.people!
        
        var newEntryRef: DatabaseReference!
        if entryUid == "" {
            newEntryRef = directoryRef.childByAutoId()
        } else {
            newEntryRef = directoryRef.child(entryUid)
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
        let newAddress = AddressMO(street: address.street!, line2: address.line2!, line3: address.line3!, city: address.city!, state: address.state!, zip: address.zip!)
        addressRef.setValue(newAddress.toAnyObject()) { (error, ref) -> Void in
            if error != nil {
                completion(false)
            }
        }
        
        let peopleRef = newEntryRef.child("People")
        peopleRef.removeValue()
        for person in people {
            let newPersonRef = peopleRef.childByAutoId()
            let newPerson = PersonMO(type: person.type!, name: person.name!, phone: person.phone!, email: person.email!, birthOrder: person.birthOrder!, uid: "")
            newPersonRef.setValue(newPerson.toAnyObject()) { (error, ref) -> Void in
                if error != nil {
                    completion(false)
                }
            }
        }
        
        completion(true)

    }
    
    func updateData(uid: String, completion: @escaping (_ success: Bool, _ error: NSString?) -> ()) {
        self.ref.observeSingleEvent(of: .value, with: { snapshot in
            if let directoriesData = (snapshot.value! as! NSDictionary)["Directories"] {
                if let entriesData = (directoriesData as! NSDictionary)[uid] {
                    for (key, value) in entriesData as! NSDictionary {
                        
                        let info = value as! NSDictionary
                        
                        let managedObjectContext = self.appDelegate.managedObjectContext
                        
                        let entry = NSEntityDescription.insertNewObject(forEntityName: "Entry", into: managedObjectContext) as! Entry
                        
                        entry.name = info.value(forKey: "name") as? String
                        entry.phone = info.value(forKey: "phone") as? String
                        entry.email = info.value(forKey: "email") as? String
                        entry.uid = key as? String
                        
                        let a = info.value(forKey: "Address") as! NSDictionary
                        
                        let address = NSEntityDescription.insertNewObject(forEntityName: "Address", into: managedObjectContext) as! Address
                        
                        address.street = a.value(forKey: "street") as? String
                        address.line2 = a.value(forKey: "line2") as? String
                        address.line3 = a.value(forKey: "line3") as? String
                        address.city = a.value(forKey: "city") as? String
                        address.state = a.value(forKey: "state") as? String
                        address.zip = a.value(forKey: "zip") as? String
                        address.addressToEntry = entry
                        
                        let p = info.value(forKey: "People") as! NSDictionary

                        for (key, value) in p {
                            
                            let person = NSEntityDescription.insertNewObject(forEntityName: "Person", into: managedObjectContext) as! Person
                            let source = value as AnyObject
                            person.type = source.value(forKey: "type") as? String
                            person.name = source.value(forKey: "name") as? String
                            person.phone = source.value(forKey: "phone") as? String
                            person.email = source.value(forKey: "email") as? String
                            person.birthOrder = String(describing: source.value(forKey: "birthOrder")!)
                            person.uid = key as? String
                            person.personToEntry = entry
                            
                        }

                    }
                    
                    self.appDelegate.saveContext()
                    completion(true, nil)
                    
                } else {
                        
                    completion(false, "Could not retrieve data")
                        
                }
            }
        })
    }
    
    func getPassword(group: String, completion: @escaping (_ password: String?, _ error: NSString?) -> ()) {
        self.ref.observeSingleEvent(of: .value, with: { snapshot in
            if let groupsData = (snapshot.value! as! NSDictionary)["Groups"] {
                if let groupData = (groupsData as! NSDictionary)[group] {
                    if let password = (groupData as! NSDictionary)["password"] {
                        completion(password as? String, nil)
                    } else {
                        completion(nil, "Could not retrieve password")
                    }
                }
            }
        })
    }
    
    func getAdminPassword(group: String, completion: @escaping (_ password: String?, _ error: NSString?) -> ()) {
        self.ref.observeSingleEvent(of: .value, with: { snapshot in
            if let groupsData = (snapshot.value! as! NSDictionary)["Groups"] {
                if let groupData = (groupsData as! NSDictionary)[group] {
                    if let password = (groupData as! NSDictionary)["adminPassword"] {
                        completion(password as? String, nil)
                    } else {
                        completion(nil, "Could not retrieve password")
                    }
                }
            }
        })
    }
    
    func deleteEntry(group: String, uid: String, completion: (Bool) -> ()) {
        let directoryRef = self.ref.child(group).child("Directory")
        directoryRef.child(uid).removeValue()
        completion(true)
    }
    
    func getGroups(completion: @escaping (_ groups: [Group]?, _ error: NSString?) -> ()) {
        self.ref.observeSingleEvent(of: .value, with: { snapshot in
            if let groupList = (snapshot.value! as! NSDictionary)["Groups"] {
                var groups: [Group] = []
                for (key, value) in groupList as! NSDictionary {
                    let info = value as! NSDictionary
                    let group = Group(uid: key as! String,
                                      name: info["name"] as! String,
                                      city: info["city"] as! String,
                                      state: info["state"] as! String,
                                      password: info["password"] as! String,
                                      admins: info["admins"] as! [String],
                                      users: info["users"] as! [String],
                                      createdBy: info["createdBy"] as! String,
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
    
    func joinGroup(userUid: String, groupUid: String, groups: [String], users: [String], completion: @escaping (_ success: Bool?) -> ()) {
        
        let userRef = self.ref.child("Users/\(userUid)")
        userRef.child("groups").setValue(groups) { (error, ref) -> Void in
            if error != nil {
                completion(false)
            } else {
                let groupRef = self.ref.child("Groups/\(groupUid)")
                groupRef.child("users").setValue(users) { (error, ref) -> Void in
                    if error != nil {
                        completion(false)
                    } else {
                        completion(true)
                    }
                }
            }
        }
    }
    
    func logout(vc: UIViewController) {
        do {
            try Auth.auth().signOut()
            let loginVC = vc.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
            vc.present(loginVC, animated: false, completion: nil)
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError)")
        }
    }
    
    static let shared = FirebaseClient()
    private override init() {
        super.init()
    }
}

