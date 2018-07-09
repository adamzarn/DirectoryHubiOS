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

class Entry {
    
    var uid: String?
    var name: String?
    var phone: String?
    var email: String?
    var address: Address?
    var people: [Person]?
    
    init(uid: String, name: String, phone: String, email: String, address: Address, people: [Person]) {
        self.uid = uid
        self.name = name
        self.phone = phone
        self.email = email
        self.address = address
        self.people = people
    }
    
    func personCount(personTypes: [PersonType]) -> Int {
        var count = 0
        let personTypeValues = personTypes.map { $0.rawValue }
        if let people = self.people {
            for person in people {
                if let type = person.type {
                    if personTypeValues.contains(type) {
                        count += 1
                    }
                }
            }
        }
        return count
    }
    
    func toAnyObject() -> [String : AnyObject] {
        return ["name": name as AnyObject,
                "phone": phone as AnyObject,
                "email": email as AnyObject,
                "Address": (address?.toAnyObject())!,
                "People": peopleToAnyObject(people: people!)] as [String : AnyObject]
    }
    
}

struct Address {
   
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
    
    func getCityStateZipString() -> String {

        if city == "" {
            return ""
        }
        return city! + ", " + state! + " " + zip!
        
    }
    
}

enum PersonType: String {
    case husband = "Husband"
    case wife = "Wife"
    case single = "Single"
    case child = "Child"
}

struct Person {
    
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

func peopleToAnyObject(people: [Person]) -> [String : AnyObject] {
    var peopleObject = [:] as [String:AnyObject]
    for person in people {
        peopleObject[UUID().uuidString] = person.toAnyObject()
    }
    return peopleObject
}

struct Group {
    
    var uid: String
    let name: String
    let lowercasedName: String
    let city: String
    let state: String
    let password: String
    var admins: [Member]
    var users: [Member]
    let createdBy: String
    let lowercasedCreatedBy: String
    let createdByUid: String
    var profilePicture: Data
    
    init(uid: String, name: String, lowercasedName: String, city: String, state: String, password: String, admins: [Member], users: [Member], createdBy: String, lowercasedCreatedBy: String, createdByUid: String, profilePicture: Data) {
        self.uid = uid
        self.name = name
        self.lowercasedName = lowercasedName
        self.city = city
        self.state = state
        self.password = password
        self.admins = admins
        self.users = users
        self.createdBy = createdBy
        self.lowercasedCreatedBy = lowercasedCreatedBy
        self.createdByUid = createdByUid
        self.profilePicture = profilePicture
    }
    
    func toAnyObject() -> AnyObject {
        return ["name": name,
                "lowercasedName": lowercasedName,
                "city": city,
                "state": state,
                "password": password,
                "admins": GlobalFunctions.shared.createMemberDict(members: admins),
                "users": GlobalFunctions.shared.createMemberDict(members: users),
                "createdBy": createdBy,
                "lowercasedCreatedBy": lowercasedCreatedBy,
                "createdByUid": createdByUid] as AnyObject
    }
    
    func getAdminUids() -> [String] {
        var uids: [String] = []
        for member in admins {
            uids.append(member.uid)
        }
        return uids
    }
    
    func getAdminNames() -> [String] {
        var names: [String] = []
        for member in admins {
            names.append(member.name)
        }
        return names
    }
    
    func getUserUids() -> [String] {
        var uids: [String] = []
        for member in users {
            uids.append(member.uid)
        }
        return uids
    }
    
    func getUserNames() -> [String] {
        var names: [String] = []
        for member in users {
            names.append(member.name)
        }
        return names
    }
    
}


struct User {
    
    let uid: String
    let name: String
    var groups: [String]
    
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

struct Member {
    
    let uid: String
    let name: String
    
    init(uid: String, name: String) {
        self.uid = uid
        self.name = name
    }
    
    func toAnyObject() -> AnyObject {
        return [uid: name] as AnyObject
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
