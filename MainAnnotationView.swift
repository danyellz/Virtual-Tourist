//
//  MainAnnotationView.swift
//  VirtualTourist
//
//  Created by TY on 6/7/16.
//  Copyright © 2016 Ty Daniels. All rights reserved.
//
import UIKit
import MapKit
import CoreData

class MainAnnotationView: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate{
    
    var savedPin: PinModel? = nil
    var gestureRecognizer: UILongPressGestureRecognizer? = nil
    
    @IBOutlet weak var annotationView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

//        let annotationView = MKAnnotationView()
//        let pin = annotationView.annotation as! PinModel
        gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(placePinRecognizer))
        annotationView.addGestureRecognizer(gestureRecognizer!)
        annotationView.delegate = self
        fetchedResultsController.delegate = self
        
        fetchPinsFromModel()
    }
    
    var sharedContext: NSManagedObjectContext{
        return CoreDataStack.sharedInstance().managedObjectContext
    }
    
    func fetchPinsFromModel(){
        do{
            try fetchedResultsController.performFetch()
        }catch{
        }
        annotationView.addAnnotations(self.fetchedResultsController.fetchedObjects as! [PinModel])
    }
    
    func startDownloadAtPlacedPin(pin: PinModel){
        FlickrRequestClient.sharedInstance().fetchPhotosAtPin(pin, completionHandler: {(totalFetched, error) -> Void in
            print("Initial fetch complete!: \(totalFetched)")
        })
    }
    
    func placePinRecognizer(gesture: UILongPressGestureRecognizer) {
    
        let point: CGPoint = gesture.locationInView(annotationView)
        let coordinate: CLLocationCoordinate2D = annotationView.convertPoint(point, toCoordinateFromView: annotationView)
        
        switch gesture.state {
        case .Began:
            let annotation = PinModel(annotationLat: coordinate.latitude, annotationLon: coordinate.longitude, context: sharedContext)
            print(annotation)
            
            startDownloadAtPlacedPin(annotation)
            
            annotationView.addAnnotation(annotation)
            CoreDataStack.sharedInstance().saveContext()
        default:
            return
        }
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key:"latitude", ascending: true)]
        
        let fetchedResultsController =
            NSFetchedResultsController(fetchRequest: fetchRequest,
                                       managedObjectContext: self.sharedContext,
                                       sectionNameKeyPath: nil,
                                       cacheName: nil)
        
        return fetchedResultsController
    }()
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier("pin") as? MKPinAnnotationView
        
        if annotationView == nil{
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
        }else{
            annotationView?.annotation = annotation
        }
        
        return annotationView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation!, animated: true)
        
        //let annotation = view.annotation as! PinModel
        performSegueWithIdentifier("transitionToPinDetail", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "transitionToPinDetail" {
            
            segue.destinationViewController as! PinDetailView
            //let pin = sender as! PinModel
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject object: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type{
        case .Insert:
            annotationView.addAnnotation(object as! PinModel)
        case .Delete:
            annotationView.removeAnnotation(object as! PinModel)
        case .Update:
            annotationView.removeAnnotation(object as! PinModel)
            annotationView.addAnnotation(object as! PinModel)
        default:
            break
        }

    }
}
