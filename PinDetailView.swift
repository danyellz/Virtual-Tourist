//
//  PinDetailView.swift
//  VirtualTourist
//
//  Created by TY on 6/17/16.
//  Copyright © 2016 Ty Daniels. All rights reserved.
//

/*Referenced https://stackoverflow.com/questions/12656648/uicollectionview-performing-updates-using-performbatchupdates 
 to get the solution for NSFetchResultsController delegate methods*/

import UIKit
import MapKit
import CoreData

class PinDetailView: UIViewController, MKMapViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var selectedPin: PinModel!
    var imgModel: ImgModel!
    var shouldReloadCollectionView: Bool?
    
    var insertedIndex: [NSIndexPath]!
    var updatedIndex: [NSIndexPath]!
    var deletedIndex: [NSIndexPath]!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(selectedPin)
        
        mapView.delegate = self
        mapView.centerCoordinate = selectedPin.coordinate
        mapView.addAnnotation(selectedPin)
        
        configureCollectionView()
        
        fetchImagesForPin()
    }
    
    func configureCollectionView(){
        let screenSize = UIScreen.mainScreen().bounds
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionViewLayout.itemSize = CGSize(width: screenSize.width/3, height: screenSize.width/3)
        collectionViewLayout.minimumInteritemSpacing = 0
        collectionViewLayout.minimumLineSpacing = 0
        
        collectionView.dataSource = self
        collectionView.setCollectionViewLayout(collectionViewLayout, animated: true)
    }
    
    func fetchImagesForPin(){
        do{
           try fetchedResultsController.performFetch()
        }catch{}
    }
    
    @IBAction func newCollectionBtn(sender: AnyObject) {
        getNewCollection()
    }
    
    func getNewCollection(){
        if let newFetch = self.fetchedResultsController.fetchedObjects{
            for object in newFetch{
                let newImg = object as! ImgModel
                self.sharedContext.deleteObject(newImg)
            }
        }
        FlickrRequestClient.sharedInstance().getNewGeoImgs(selectedPin)
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStack.sharedInstance().managedObjectContext
    }
    
    func saveContext(){
        return CoreDataStack.sharedInstance().saveContext()
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Image")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.selectedPin)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: self.sharedContext,
                                                                  sectionNameKeyPath: nil, cacheName: nil)
        return fetchedResultsController
    }()
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier("pin") as? MKPinAnnotationView
        if pinView == nil{
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
        }else{
            pinView?.annotation = annotation
        }
        return pinView
    }
    
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        print(sectionInfo.numberOfObjects)
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("DetailCell", forIndexPath: indexPath) as! ImageCollectionCell
        let image = fetchedResultsController.objectAtIndexPath(indexPath) as! ImgModel
        
        configureUI(cell, image: image, atIndexPath: indexPath)
        return cell
    }
    
    func configureUI(cell: ImageCollectionCell, image: ImgModel, atIndexPath indexPath: NSIndexPath) {
        
        if image.image != nil{
            image.loadUpdateHandler = nil
            cell.flickrImageView.image = image.image!
            print("Image.image \(image.image!)")
            self.saveContext()
            //addSpinner(cell, activityBool: true)
        }else{
            image.loadUpdateHandler = {[unowned self] () -> Void in
            dispatch_async(dispatch_get_main_queue(), {
            self.collectionView.reloadData()
                })
            }
            cell.flickrImageView.image = image.image
            //addSpinner(cell, activityBool: false)
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath){
        if collectionView.cellForItemAtIndexPath(indexPath) != nil {
            let image = fetchedResultsController.objectAtIndexPath(indexPath) as! ImgModel
            print(image)
        }
    }

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
        insertedIndex = [NSIndexPath]()
        updatedIndex = [NSIndexPath]()
        deletedIndex = [NSIndexPath]()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            insertedIndex.append(newIndexPath!)
        case .Update:
            updatedIndex.append(indexPath!)
        case .Move:
            print("Surprise!")
        case .Delete:
            deletedIndex.append(indexPath!)
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        collectionView.performBatchUpdates({() -> Void in
            for indexPath in self.insertedIndex {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            for indexPath in self.updatedIndex {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            for indexPath in self.deletedIndex {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            },completion: nil)
        
    }
    
    func addSpinner(cellView: UICollectionViewCell, activityBool: Bool){
        
        let activitySpinner = UIActivityIndicatorView.init(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
        activitySpinner.center = cellView.center
        activitySpinner.color = UIColor.whiteColor()
        activitySpinner.startAnimating()
        
        if activityBool == true{
            activitySpinner.startAnimating()
            cellView.addSubview(activitySpinner)
        }else if activityBool == false{
            activitySpinner.stopAnimating()
            cellView.willRemoveSubview(activitySpinner)
        }
    }
    
    func removeSpinner(){
        
    }
    
}
