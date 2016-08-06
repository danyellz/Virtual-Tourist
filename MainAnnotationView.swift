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
    
    var savedPin: PinModel!
    var savedPins = [PinModel]()
    var gestureRecognizer: UILongPressGestureRecognizer? = nil
    var editingPins: Bool = false
    
    @IBOutlet weak var annotationView: MKMapView!
    @IBOutlet weak var pinActionBtn: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        persistedRegion()
        gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(placePinRecognizer))
        annotationView.addGestureRecognizer(gestureRecognizer!)
        annotationView.delegate = self
        fetchedResultsController.delegate = self
        fetchPinsFromModel()
        
        print(savedPins)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "transitionToPinDetail" {
            let barButtomItem = UIBarButtonItem()
            barButtomItem.title = "Done"
            navigationItem.backBarButtonItem = barButtomItem
            
            let pinDetailVC = segue.destinationViewController as! PinDetailView
            let pin = sender as! PinModel
            pinDetailVC.selectedPin = pin
        }
    }
    
    var sharedContext: NSManagedObjectContext{
        return CoreDataStack.sharedInstance().managedObjectContext
    }
    
    func fetchPinsFromModel(){
        do{
            try fetchedResultsController.performFetch()
        }catch{}
        
        let fetchedAnnotations = self.fetchedResultsController.fetchedObjects as! [PinModel]
        annotationView.addAnnotations(fetchedAnnotations)
        savedPins = fetchedAnnotations
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
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        let storedMapVals = [
            "lat" : annotationView.region.center.latitude,
            "lon" : annotationView.region.center.longitude,
            "latD" : annotationView.region.span.latitudeDelta,
            "lonD" : annotationView.region.span.longitudeDelta
        ]
        
        NSKeyedArchiver.archiveRootObject(storedMapVals, toFile: mapRegionPersist)
    }
    
    
    @IBAction func beginEditingAnnotations(sender: AnyObject) {
        self.editingPins = true
        pinActionBtn.title = "Done"
        
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        let coordinate = view.annotation?.coordinate
        
        if editingPins == false {
            mapView.deselectAnnotation(view.annotation!, animated: true)
            let annotation = view.annotation as! PinModel
            performSegueWithIdentifier("transitionToPinDetail", sender: annotation)
            
        }else {
            
            for pin in savedPins {
                print("Deleting pin...")
                if pin.latitude == (coordinate!.latitude) {
                    self.sharedContext.deleteObject(pin)
                    
                dispatch_async(dispatch_get_main_queue()) {
                    CoreDataStack.sharedInstance().saveContext()
                }
                }
            }
        }
    }
    
    func persistedRegion() {
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(mapRegionPersist) as? [String : AnyObject] {
            
            let latitude = regionDictionary["lat"] as! CLLocationDegrees
            let longitude = regionDictionary["lon"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let longitudeDelta = regionDictionary["latD"] as! CLLocationDegrees
            let latitudeDelta = regionDictionary["lonD"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            
            annotationView.setRegion(savedRegion, animated: true)
        }
    }
    
    var mapRegionPersist: String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
        return url.URLByAppendingPathComponent("mapRegion").path!
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject object: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type{
        case .Insert:
            annotationView.addAnnotation(object as! PinModel)
            fetchPinsFromModel()
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
