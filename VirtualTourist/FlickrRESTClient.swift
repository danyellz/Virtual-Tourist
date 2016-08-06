//
//  RequestClient.swift
//  VirtualTourist
//
//  Created by TY on 6/6/16.
//  Copyright © 2016 Ty Daniels. All rights reserved.
//

import Foundation

class FlickrRESTClient: NSObject {
    
    var session: NSURLSession
    
    override init(){
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    func taskForGetMethod(var method: String, parameters: [String : AnyObject]?, completionHandler:(result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        method += FlickrRESTClient.escapedParameters(parameters)
        let url = NSURL(string: method)!
        print(url)
        
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = session.dataTaskWithRequest(request) {(data, response, error) in
            
        guard error == nil else {
            let userInfo = [NSLocalizedDescriptionKey: "There was an error with the GET request: \(error)"]
            completionHandler(result: nil, error: NSError(domain: "taskForGetMethod", code: 1, userInfo: userInfo))
            
            return
            }
        guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
            if let response = response as? NSHTTPURLResponse {
                let userInfo = [NSLocalizedDescriptionKey: "Your request returned an invalid response w/ code: \(response.statusCode)"]
                completionHandler(result: nil, error: NSError(domain: "taskForGetMethod", code: 1, userInfo: userInfo))
            }else if let response = response{
                let userInfo = [NSLocalizedDescriptionKey: "Your request returned an invalud response: \(response)"]
                completionHandler(result: nil, error: NSError(domain: "taskForGetMethod", code: 1, userInfo: userInfo))
            }else{
                let userInfo = [NSLocalizedDescriptionKey: "Your request returned an invalud response w/o code!"]
                completionHandler(result: nil, error: NSError(domain: "taskForGetMethod", code: 1, userInfo: userInfo))
                }
            return
            }
            
            guard let data = data else{
                print("No Flickr data was retrieved during your request!")
                
                return
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                FlickrRESTClient.convertDataWithCompletionHandler(data, completionHandlerForConvertData: completionHandler)
            }
        }
        task.resume()
        
        return task
    }
    
    class func convertDataWithCompletionHandler(data: NSData, completionHandlerForConvertData: (result: AnyObject!, error: NSError?) -> Void) {
        
        var parsedResult: AnyObject?
        do{
            let dataString = NSString(data: data, encoding: NSUTF8StringEncoding)
            print("Data to parse: \(dataString)")
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
            
        }catch{
            let userInfo = [NSLocalizedDescriptionKey: "Could not parse the JSON: '\(error)'"]
            completionHandlerForConvertData(result: nil, error: NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandlerForConvertData(result: parsedResult, error: nil)
        
        print(parsedResult)
    }
    
    func getImageDataTask(image: ImgModel, completionHandler: (data: NSData?,
        errorString: String?) -> Void) {
        
        if let imageURL = NSURL(string: image.url!){
            taskForImageData(imageURL) {data, error in
            if error != nil{
                completionHandler(data: nil, errorString: "Error downloading \(error)")
            }else{
                completionHandler(data: data, errorString: nil)
            }
        }
    }
    }
    
    func taskForImageData(url: NSURL, completionHandler: (imageData: NSData?, error: NSError?) -> Void) -> NSURLSessionTask{
        print("Image url: \(url)")
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError{
                completionHandler(imageData: nil, error: error)
            }else{
                completionHandler(imageData: data, error: nil)
            }
        }
        task.resume()
        return task
    }

    /* Helper function: Given a dictionary of parameters, convert to a string for a url */
    class func escapedParameters(parameters: [String : AnyObject]?) -> String {
        
        guard let parameters = parameters else {
            return ""
        }
        
        var urlVars = [String]()
        for (key, value) in parameters {
            /* Check if key is a string value */
            let stringValue = "\(value)"
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    class func sharedInstance() -> FlickrRESTClient{
        struct Static{
            static let instance = FlickrRESTClient()
        }
        return Static.instance
    }
    
}