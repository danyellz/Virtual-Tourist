//
//  FlickrParamConvenience.swift
//  VirtualTourist
//
//  Created by TY on 6/6/16.
//  Copyright © 2016 Ty Daniels. All rights reserved.
//

import Foundation
import CoreLocation

extension FlickrRequestClient{
    
    //A dictionary of base parameters to build upon for Flickr API requests
    func baseParameters() -> NSMutableDictionary {
        let result = [
            FlickrKeys.APIKey : BaseRefs.APIKey,
            FlickrKeys.Method : BaseRefs.SearchMethod,
            FlickrKeys.SafeSearch : FlickrValues.SafeSearch,
            FlickrKeys.Extras : FlickrValues.URL_M,
            FlickrKeys.Format : FlickrValues.JSON,
            FlickrKeys.NoJSON : FlickrValues.NoJSONCB
        ] as NSMutableDictionary
        
        print("JSONresultingstring: \(result)")
        return result
    }
    
    //Limiting agent for lat/long API requests and paginate the number of returned results
    func paginateImageLocationSearch(coordinate: CLLocationCoordinate2D, page: Int, perPage total: Int) -> [String: AnyObject] {
        let mutableParameters = baseParameters()
        
        //Assign paramters to API call
        mutableParameters.setValue(coordinate.latitude, forKey: FlickrKeys.Lat)
        mutableParameters.setValue(coordinate.longitude, forKey: FlickrKeys.Lon)
        mutableParameters.setValue(page, forKey: FlickrKeys.Page)
        mutableParameters.setValue(total, forKey: FlickrKeys.PerPage)
        
        let parameters: NSDictionary = mutableParameters
        
        print(parameters)
        return parameters as! [String: AnyObject]
    }
}
