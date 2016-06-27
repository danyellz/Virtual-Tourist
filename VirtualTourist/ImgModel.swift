//
//  MovieModel.swift
//  VirtualTourist
//
//  Created by TY on 6/13/16.
//  Copyright © 2016 Ty Daniels. All rights reserved.
//

import UIKit
import CoreData

@objc(ImgModel)

class ImgModel: NSManagedObject {
    
    struct Keys{
        static let URL = "url_m"
    }
    @NSManaged var url: String?
    @NSManaged var pin: PinModel?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String: AnyObject], context: NSManagedObjectContext){
        
        let entity = NSEntityDescription.entityForName("Image", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        url = dictionary[Keys.URL] as? String
        
        print("Retrieved images for pin: \(url)")
    }
    
    var image: UIImage? {
        
        get {
            return FlickrRequestClient.sharedInstance().retrieveImageForStorage(url!)
        }
        set{
            print("Saving image data!")
            FlickrRequestClient.sharedInstance().saveImage(newValue, withURL: url!)
        }
    }
    
}