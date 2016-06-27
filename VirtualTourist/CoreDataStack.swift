//
//  CoreDataStack.swift
//  VirtualTourist
//
//  Created by TY on 6/6/16.
//  Copyright © 2016 Ty Daniels. All rights reserved.
//

import Foundation
import CoreData

private let SQLITE_REF = "VirtualTourist.sqlite"

class CoreDataStack{
    
    //Create a sharedInstance to be instantiated in outside controllers
    class func sharedInstance() -> CoreDataStack{
        struct Static{
            static let instance = CoreDataStack()
        }
        
        return Static.instance
    }
    
    //Build the path to user documents directory
    lazy var appDocsDir: NSURL = {
        let docsDir = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return docsDir[docsDir.count-1]
    }()
    
    lazy var imgDocsDirectory: NSURL = {
        
        let imgsDirectory = CoreDataStack.sharedInstance().appDocsDir.URLByAppendingPathComponent("storeImages")
        let imgPath = imgsDirectory.path!
        
        var isDirectory: ObjCBool = ObjCBool(false)
        if NSFileManager.defaultManager().fileExistsAtPath(imgPath, isDirectory: &isDirectory){
            if !isDirectory{
                print("This directory has already been persisted!")
                abort()
            }
        }else {
            
            var error: NSError? = nil
            do{
                try NSFileManager.defaultManager().createDirectoryAtPath(imgPath, withIntermediateDirectories: false, attributes: nil)
                print("Image directory: \(imgsDirectory)")
            }catch var pathError as NSError{
                error = pathError
                if let error = error {
                    print("Error creating imgPath: \(error)")
                    abort()
                }
            }catch{
                
                fatalError()
            }
        }
        
        return imgsDirectory
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let object = NSBundle.mainBundle().URLForResource("Model", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: object)!
    }()
    
    lazy var persistentStoreCoord: NSPersistentStoreCoordinator? = {
        let coordinator : NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.appDocsDir.URLByAppendingPathComponent(SQLITE_REF)
        
        print(url)
        do{
            try coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        }catch{
            
            var dic = [String : AnyObject]()
            dic[NSLocalizedDescriptionKey] = "Error to init data in the store coord!"
            dic[NSLocalizedFailureReasonErrorKey] = "Failed"
            dic[NSUnderlyingErrorKey] = error as! NSError
            
            let wrappedError = NSError(domain: "ERROR_DOMAIN", code: 9999, userInfo: dic)
            NSLog("\(wrappedError)", "\(wrappedError.userInfo)")
        }
        
        return coordinator
    }()
    
    lazy var  managedObjectContext: NSManagedObjectContext = {
    
        let coordinator = self.persistentStoreCoord
        var mOC = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        mOC.persistentStoreCoordinator = coordinator
        
        return mOC
    }()
    
    func saveContext(){
        if managedObjectContext.hasChanges{
            do{
                try managedObjectContext.save()
                
            }catch {
            let error = error as NSError
            NSLog("Error during saveContext(): \(error), \(error.userInfo)")
            }
        }
    }
}
