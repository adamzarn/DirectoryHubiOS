//
//  FamilyObjects.swift
//  ValleybrookCommunityChurch
//
//  Created by Adam Zarn on 6/6/17.
//  Copyright © 2017 Adam Zarn. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class EntryMO {
    
    var name: String?
    var phone: String?
    var email: String?
    var address: AddressMO?
    var people: [PersonMO]?
    
    init(name: String, phone: String, email: String, address: AddressMO, people: [PersonMO]) {
        self.name = name
        self.phone = phone
        self.email = email
        self.address = address
        self.people = people
    }
    
}

struct AddressMO {
   
    var street: String?
    var line2: String?
    var line3: String?
    var city: String?
    var state: String?
    var zip: String?
    
    init(street: String, line2: String, line3: String, city: String, state: String, zip: String) {
        self.street = street
        self.line2 = line2
        self.line3 = line3
        self.city = city
        self.state = state
        self.zip = zip
    }

    func toAnyObject() -> AnyObject {
        return ["street": street, "line2": line2, "line3": line3, "city": city, "state": state, "zip": zip] as AnyObject
    }
    
}

struct PersonMO {
    
    var type: String?
    var name: String?
    var phone: String?
    var email: String?
    var birthOrder: Int?
    var uid: String?
    
    init(type: String, name: String, phone: String, email: String, birthOrder: Int, uid: String) {
        self.type = type
        self.name = name
        self.phone = phone
        self.email = email
        self.birthOrder = birthOrder
        self.uid = uid
    }
    
    func toAnyObject() -> AnyObject {
        return ["type": type!, "name": name!, "phone": phone!, "email": email!, "birthOrder": birthOrder!] as AnyObject
    }
    
}

struct Group {
    
    let uid: String
    let name: String
    let city: String
    let state: String
    let password: String
    let admins: [String]
    let users: [String]
    let createdBy: String
    let profilePicture: Data
    
    init(uid: String, name: String, city: String, state: String, password: String, admins: [String], users: [String], createdBy: String, profilePicture: Data) {
        self.uid = uid
        self.name = name
        self.city = city
        self.state = state
        self.password = password
        self.admins = admins
        self.users = users
        self.createdBy = createdBy
        self.profilePicture = profilePicture
    }
    
    func toAnyObject() -> AnyObject {
        return ["name": name,
                "city": city,
                "state": state,
                "password": password,
                "admins": admins,
                "users": users,
                "createdBy": createdBy] as AnyObject
    }
    
}


struct User {
    
    let uid: String
    let name: String
    let groups: [String]
    
    init(uid: String, name: String, groups: [String]) {
        self.uid = uid
        self.name = name
        self.groups = groups
    }
    
    func toAnyObject() -> AnyObject {
        return ["name": name,
                "groups": groups] as AnyObject
    }
    
}

class MyNavigationController: UINavigationController, UIViewControllerTransitioningDelegate {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationBar.barTintColor = GlobalFunctions.shared.themeColor()
        self.navigationBar.tintColor = UIColor.white
        self.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
    }
}
