//
//  FlickrRequestClient.swift
//  VirtualTourist
//
//  Created by TY on 6/6/16.
//  Copyright © 2016 Ty Daniels. All rights reserved.
//

import UIKit
import CoreLocation
import CoreFoundation
import CoreData

class FlickrRequestClient: NSObject {
    
    private var memoryCache = NSCache()
    
    var session: NSURLSession
    var pin: PinModel? = nil
    
    override init(){
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    let flickrClient = FlickrRESTClient.sharedInstance()
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStack.sharedInstance().managedObjectContext
    }
    
    func saveContext() {
        CoreDataStack.sharedInstance().saveContext()
    }
    
    func fetchPhotosAtPin(pin: PinModel, completionHandler:((numberFetched: Int?, error: NSError?) -> Void)){
        
        print("Fetching photos at pin location")
        
        fetchPhotosAtGeo(pin.coordinate, fromPage: 1, total: 21){ (json, error) in
            if let error = error{
                print("Error during fetch in fetchPhotosAtGeo: \(error)")
                return
            }
        
        var jsonError: NSError? = nil
            var result: (photoURLs: [String], pages: Int)?
        do{
            result = try self.getImagesFromJSON(json!)
            print(result)
        }catch let error as NSError {
            jsonError = error
            result = nil
            
        }catch{
            fatalError()
        }
        if let jsonError = jsonError{
            print(jsonError)
            return
            }
        
        let retrievedPhotos = result!.photoURLs.count
            for url in result!.photoURLs {
                let photoDic = [
                    ImgModel.Keys.URL: url
                ]
                
                //Append photos to pin instance in CoreData
                let photoAddedToModel = ImgModel(dictionary: photoDic, context: self.sharedContext)
                photoAddedToModel.pin = pin
                let randomInt = NSInteger(arc4random_uniform(100000) + 1)
                photoAddedToModel.id = String(randomInt)
            }
            
            self.getPinImageData(pin)
            
            self.saveContext()
            completionHandler(numberFetched: retrievedPhotos, error: nil)
        }
        
    }
    
    
    func fetchPhotosAtGeo(coordinate: CLLocationCoordinate2D, fromPage page: Int, total: Int, completionHandler:((jsonResponse: AnyObject!, error: NSError?) -> Void)) {
        
        print("Fetching json at geo with parameters")
        let parameters = paginateImageLocationSearch(coordinate, page: page, perPage: total)
        
        flickrClient.taskForGetMethod(FlickrRequestClient.BaseRefs.BaseURL, parameters: parameters) {(result, error) -> Void in
            if let error = error{
                completionHandler(jsonResponse: nil, error: error)
                return
            }
            completionHandler(jsonResponse: result, error: nil)
        }
    }
    
    func getPinImageData(pin: PinModel){
        for image in pin.images {
            FlickrRESTClient.sharedInstance().getImageDataTask(image) {(data, errorString) in
                guard let data = data else{
                    print("Error with getPinImageData: \(errorString)")
                    return
                }
                
                let photo = UIImage(data: data)
                image.image = photo!
                self.saveContext()
            }
        }
    }
    
    func retrieveImageForStorage(url: String?) -> UIImage? {
        print("Retrieving image data!")
        if url == nil || url! == "" {
            return nil
        }
        let path = pathForIdentifier(url!)
        print("Path: \(path)")
        if let image = memoryCache.objectForKey(path) as? UIImage {
            return image
        }
        if let data = NSData(contentsOfFile: path){
            return UIImage(data: data)
        }
        return nil
    }
    
    func saveImage(image: UIImage?, withURL url: String) {
        let path = pathForIdentifier(url)
        print("Path\(path)")
        
        if image == nil {
            memoryCache.removeObjectForKey(path)
            
            do{
                try NSFileManager.defaultManager().removeItemAtPath(url)
            }catch{}
            
            return
        }
        
        memoryCache.setObject(image!, forKey: path)
        let data = UIImagePNGRepresentation(image!)!
        data.writeToFile(path, atomically: true)
        
        print("ImageFile:\(image)")
    }
    
    func pathForIdentifier(identifier: String) -> String {
        let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(identifier)
        return fullURL.path!
    }
    
    class func errorForJSONInterpreting(json: AnyObject!) -> NSError {
        let userInfo = [NSLocalizedDescriptionKey : "Could not interpret json: \(json)"]
        return  NSError(domain: ErrorDomains.ServerError, code: ServerErrorCodes.JSONParsingError, userInfo: userInfo)
    }
    
    struct ServerErrorCodes {
        static let UnexpectedError = 1
        static let JSONParsingError = 2
        static let SkipDataError = 3
        static let UdacityJSONParsingError = 4
    }
    
    struct ErrorDomains {
        static let ClientError = "ClientError"
        static let ServerError = "ServerError"
    }
    
    class func sharedInstance() -> FlickrRequestClient{
        struct Static{
            static let instance = FlickrRequestClient()
        }
        
        return Static.instance
    }

}

extension FlickrRequestClient{
    func getImagesFromJSON(json: AnyObject!) throws -> (photoURLs:[String], pages: Int) {
        print("Iniitializing getImagesFromJSON")
        if let photoInfo = json[ResponseKeys.Photos] as? NSDictionary{
            if let pages = photoInfo[FlickrValues.Pages] as? Int{
                
                if let photoList = photoInfo[ResponseKeys.Photo] as? NSArray {
                    var result:[String] = [String]()
                    for item in photoList{
                        if let url = item[FlickrValues.URL_M] as? String {
                            result.append(url)
                        }
                    }
            
                    return (result, pages)
                }
            }
        }
        //TODO: Add json error checking
        throw FlickrRequestClient.errorForJSONInterpreting(json)
    }
}
