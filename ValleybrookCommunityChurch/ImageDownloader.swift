//
//  ImageDownloader.swift
//  ValleybrookCommunityChurch
//
//  Created by Adam Zarn on 7/14/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import AlamofireImage
import FirebaseStorage

var imageCache: [String: UIImage] = [:]

extension UIImageView {
    
    func loadImage(from groupUID: String) {
        if let image = imageCache[groupUID] {
            self.image = image
        } else {
            let imageRef = Storage.storage().reference(withPath: "/\(groupUID).jpg")
            imageRef.getMetadata { (metadata, error) -> () in
                if let metadata = metadata {
                    let downloadUrl = metadata.downloadURL()
                    Alamofire.request(downloadUrl!, method: .get).responseImage { response in
                        guard let image = response.result.value else {
                            return
                        }
                        imageCache[groupUID] = image
                        self.image = image
                    }
                }
            }
        }
    }
    
}
