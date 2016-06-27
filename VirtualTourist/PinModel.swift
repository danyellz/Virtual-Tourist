//
//  PinCoreModel.swift
//  VirtualTourist
//
//  Created by TY on 6/7/16.
//  Copyright © 2016 Ty Daniels. All rights reserved.
//

import CoreData
import MapKit

@objc(PinModel)

class PinModel: NSManagedObject, MKAnnotation {
    
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber
    @NSManaged var images: [ImgModel]

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(annotationLat: Double, annotationLon: Double, context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        latitude = NSNumber(double: annotationLat)
        longitude = NSNumber(double: annotationLon)
    }
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude as Double, longitude: longitude as Double)
    }
    
}
