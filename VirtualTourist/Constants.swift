//
//  Constants.swift
//  VirtualTourist
//
//  Created by TY on 6/6/16.
//  Copyright © 2016 Ty Daniels. All rights reserved.
//

import Foundation
import CoreLocation

//TODO: Add map view extension

extension CoreDataStack{
    struct Constants{
        
    }
}

extension FlickrRequestClient{
    
    struct BaseRefs{
        static let APIKey = "dafcfff1bb07a3926db9bfb2e1825767"
        static let SearchMethod = "flickr.photos.search"
        static let BaseURL: String = "https://api.flickr.com/services/rest/"
    }
    
    struct DLCount {
        static let MaxQueueCount = 3
    }
    
    struct TotalPages {
        static let MaxPages = 21
    }
    
    struct FlickrKeys{
        static let Method = "method"
        static let APIKey = "api_key"
        static let Extras = "extras"
        static let SafeSearch = "safe_search"
        static let Format = "format"
        static let Lat = "lat"
        static let Lon = "lon"
        static let Page = "page"
        static let PerPage = "per_page"
        static let NoJSON = "nojsoncallback"
    }
    
    struct FlickrValues{
        static let URL_M = "url_m"
        static let JSON = "json"
        static let Pages = "pages"
        static let NoJSONCB = "1"
        static let SafeSearch = "1"
    }
    
    struct ResponseKeys{
        static let Photos = "photos"
        static let Photo = "photo"
        static let Pages = "pages"
    }
    
}
