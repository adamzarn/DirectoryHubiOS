//
//  GlobalFunctions.swift
//  ValleybrookCommunityChurch
//
//  Created by Adam Zarn on 6/9/17.
//  Copyright © 2017 Adam Zarn. All rights reserved.
//

import Foundation

class GlobalFunctions: NSObject {

    func hasConnectivity() -> Bool {
        do {
            let reachability = Reachability()
            let networkStatus: Int = reachability!.currentReachabilityStatus.hashValue
            return (networkStatus != 0)
        }
    }

    static let sharedInstance = GlobalFunctions()
    private override init() {
        super.init()
    }

}
