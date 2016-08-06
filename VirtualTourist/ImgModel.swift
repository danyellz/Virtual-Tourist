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
    @NSManaged var id : String?
    @NSManaged var path: String?
    @NSManaged var pin: PinModel?
    
    var loadUpdateHandler: (() -> Void)?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String: AnyObject], context: NSManagedObjectContext){
        let entity = NSEntityDescription.entityForName("Image", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        url = (dictionary[Keys.URL] as? String)
        
    }
    
    override func prepareForDeletion() {
        super.prepareForDeletion()
        let usedPath = pathForIdentifier(id!)
        if let pathToRm = usedPath {
            if NSFileManager.defaultManager().fileExistsAtPath(pathToRm) {
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(pathToRm)
                    print("Removing \(pathToRm)")
                }catch {
                    print("Could not remove item at path \(pathToRm)")
                }
            }else {
                print("There is not a photo at this path!")
            }
        }
    }
    
    var image: UIImage? {
        
        get {
            return FlickrRequestClient.sharedInstance().retrieveImageForStorage(id)
        }
        set{
            print("Saving image data!")
            FlickrRequestClient.sharedInstance().saveImage(newValue, withURL: self.id!)
            self.loadUpdateHandler?()
    }
}

    func pathForIdentifier(identifier: String) -> String? {
        let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(identifier)
        
        return fullURL.path!
    }
    
}