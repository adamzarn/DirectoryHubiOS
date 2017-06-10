//
//  FirebaseClient.swift
//  ValleybrookCommunityChurch
//
//  Created by Adam Zarn on 6/6/17.
//  Copyright © 2017 Adam Zarn. All rights reserved.
//


import UIKit
import Firebase
import CoreData

class FirebaseClient: NSObject {
    
    let ref = Database.database().reference()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    func addFamily(family: FamilyMO) {
        let directoryRef = self.ref.child("Directory")
        
        let name = family.name!
        let phone = family.phone!
        let email = family.email!
        let address = family.address!
        let people = family.people!
        
        let newFamilyRef = directoryRef.childByAutoId()
        newFamilyRef.child("name").setValue(name)
        newFamilyRef.child("phone").setValue(phone)
        newFamilyRef.child("email").setValue(email)
        
        let addressRef = newFamilyRef.child("Address")
        let newAddress = AddressMO(street: address.street!, line2: address.line2!, line3: address.line3!, city: address.city!, state: address.state!, zip: address.zip!)
        addressRef.setValue(newAddress.toAnyObject())
        
        let peopleRef = newFamilyRef.child("People")
        for person in people {
            let newPersonRef = peopleRef.childByAutoId()
            let newPerson = PersonMO(type: person.type!, name: person.name!, phone: person.phone!, email: person.email!, birthOrder: person.birthOrder!)
            newPersonRef.setValue(newPerson.toAnyObject())
        }
    }
    
    func updateData(completion: @escaping (_ success: DarwinBoolean, _ error: NSString?) -> ()) {
        self.ref.observeSingleEvent(of: .value, with: { snapshot in
            if let familiesData = (snapshot.value! as! NSDictionary)["Directory"] {

                for (_, value) in familiesData as! NSDictionary {
                    
                    let info = value as! NSDictionary
                    
                    let managedObjectContext = self.appDelegate.managedObjectContext
                    
                    let family = NSEntityDescription.insertNewObject(forEntityName: "Family", into: managedObjectContext) as! Family
                    
                    family.name = info.value(forKey: "name") as? String
                    family.phone = info.value(forKey: "phone") as? String
                    family.email = info.value(forKey: "email") as? String
                    
                    let a = info.value(forKey: "Address") as! NSDictionary
                    
                    let address = NSEntityDescription.insertNewObject(forEntityName: "Address", into: managedObjectContext) as! Address
                    
                    address.street = a.value(forKey: "street") as? String
                    address.line2 = a.value(forKey: "line2") as? String
                    address.line3 = a.value(forKey: "line3") as? String
                    address.city = a.value(forKey: "city") as? String
                    address.state = a.value(forKey: "state") as? String
                    address.zip = a.value(forKey: "zip") as? String
                    address.addressToFamily = family
                    
                    let p = info.value(forKey: "People") as! NSDictionary

                    for (_, value) in p {
                        
                        let person = NSEntityDescription.insertNewObject(forEntityName: "Person", into: managedObjectContext) as! Person
                        let source = value as AnyObject
                        person.type = source.value(forKey: "type") as? String
                        person.name = source.value(forKey: "name") as? String
                        person.phone = source.value(forKey: "phone") as? String
                        person.email = source.value(forKey: "email") as? String
                        person.birthOrder = String(describing: source.value(forKey: "birthOrder"))
                        person.personToFamily = family
                        
                    }
                    
                }
                
                self.appDelegate.saveContext()
                
                completion(true, nil)
                
            } else {
                    
                completion(false, "Could not retrieve data")
                    
            }

        })
    }
    
    func getPassword(completion: @escaping (_ password: String?, _ error: NSString?) -> ()) {
        self.ref.observeSingleEvent(of: .value, with: { snapshot in
            if let password = (snapshot.value! as! NSDictionary)["Password"] {
                completion(password as? String, nil)
            } else {
                completion(nil, "Could not retrieve passwor")
            }
        })
    }
    
    static let sharedInstance = FirebaseClient()
    private override init() {
        super.init()
    }
}

