//
//  GlobalFunctions.swift
//  ValleybrookCommunityChurch
//
//  Created by Adam Zarn on 6/9/17.
//  Copyright © 2017 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

class GlobalFunctions: NSObject {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    func hasConnectivity() -> Bool {
        do {
            let reachability = Reachability()
            let networkStatus: Int = reachability!.currentReachabilityStatus.hashValue
            return (networkStatus != 0)
        }
    }
    
    func getFormattedString(string1: String, string2: String) -> NSMutableAttributedString {
        let attrs1 = [NSFontAttributeName : UIFont.italicSystemFont(ofSize: 17), NSForegroundColorAttributeName : UIColor.lightGray]
        let attrs2 = [NSForegroundColorAttributeName : UIColor.black]
        let attributedString1 = NSMutableAttributedString(string:string1, attributes:attrs1)
        let attributedString2 = NSMutableAttributedString(string:string2, attributes:attrs2)
        attributedString1.append(attributedString2)
        return attributedString1
    }
    
    func bold(string: String) -> NSMutableAttributedString {
        let attrs = [NSFontAttributeName : UIFont.boldSystemFont(ofSize: 17)]
        let attributedString = NSMutableAttributedString(string: string, attributes:attrs)
        return attributedString
    }
    
    func italics(string: String) -> NSMutableAttributedString {
        let attrs = [NSFontAttributeName : UIFont.italicSystemFont(ofSize: 17)]
        let attributedString = NSMutableAttributedString(string: string, attributes:attrs)
        return attributedString
    }
    
    func getCurrentDateTime() -> String {
        let date = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let year = calendar.component(.year, from: date)
        var hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        
        let yearString = String(year)
        var minutesString = String(minutes)
        var suffix = ""
        
        if hour == 0 {
            hour = 12
            suffix = "AM"
        } else if hour < 12 {
            suffix = "AM"
        } else if hour == 12 {
            suffix = "PM"
        } else if hour > 12 {
            hour = hour - 12
            suffix = "PM"
        }
        
        if minutes < 10 {
            minutesString = "0\(minutesString)"
        }
        
        return "\(month)/\(day)/\(yearString.substring(from: 2)) \(hour):\(minutesString) \(suffix)"
        
    }

    func themeColor() -> UIColor {
        let color = UIColor(red: 220.0/255.0, green: 111.0/255.0, blue: 104.0/255.0, alpha: 1.0)
        return color
    }
    
    func createMemberDict(members: [Member]) -> [String: String] {
        var dict: [String: String] = [:]
        for member in members {
            dict[member.uid] = member.name
        }
        return dict
    }
    
    func getStates() -> [String] {
        return ["IL", "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA", "HI", "ID",
                            "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY"]
    }
    
    func configureTwoLineTitleView(_ topLine: String, bottomLine: String) -> UIView {
        
        let titleLabel = UILabel(frame: CGRect(x: 0, y: -4, width: 0, height: 0))
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.text = topLine
        titleLabel.sizeToFit()
        
        let subTitleLabel = UILabel(frame: CGRect(x: 0, y: 18, width: 0, height: 0))
        subTitleLabel.backgroundColor = UIColor.clear
        subTitleLabel.textColor = UIColor.white
        subTitleLabel.font = UIFont.systemFont(ofSize: 12)
        subTitleLabel.text = bottomLine
        subTitleLabel.sizeToFit()
        
        let twoLineTitleView = UIView(frame: CGRect(x: 0, y: 0, width: max(subTitleLabel.frame.size.width, titleLabel.frame.size.width), height: 30))
        twoLineTitleView.addSubview(titleLabel)
        twoLineTitleView.addSubview(subTitleLabel)
        let widthDiff: Float = Float(subTitleLabel.frame.size.width - titleLabel.frame.size.width)
        if widthDiff > 0 {
            var frame: CGRect = titleLabel.frame
            frame.origin.x = CGFloat(widthDiff / 2)
            titleLabel.frame = frame.integral
        }
        else {
            var frame: CGRect = subTitleLabel.frame
            frame.origin.x = CGFloat(fabsf(widthDiff) / 2)
            subTitleLabel.frame = frame.integral
        }
        
        return twoLineTitleView
        
    }


    static let shared = GlobalFunctions()
    private override init() {
        super.init()
    }

}
