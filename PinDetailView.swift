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
    var runNSBlockOperation: [NSBlockOperation] = []
    
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
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStack.sharedInstance().managedObjectContext
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Image")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "url", ascending: true)]
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
            image.loadUpdateHandler = {[unowned self] () -> Void in
                dispatch_async(dispatch_get_main_queue(), {
                    self.collectionView.reloadItemsAtIndexPaths([indexPath])
                })
            }
            cell.flickrImageView.image = image.image!
            print("Image.image \(image.image!)")
        }else{
            print("Preexisting images in configureCell!")
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath){
        if let cell = collectionView.cellForItemAtIndexPath(indexPath) {
            let image = fetchedResultsController.objectAtIndexPath(indexPath) as! ImgModel
            print(image)
        }
    }

    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        runNSBlockOperation.removeAll(keepCapacity: false)
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
                runNSBlockOperation.append(
                    NSBlockOperation(block: {[weak self] in
                        if let this = self {
                            this.collectionView!.insertItemsAtIndexPaths([newIndexPath!])
                        }
                        })
            )
        case .Update:
                runNSBlockOperation.append(
                    NSBlockOperation(block: {[weak self] in
                        if let this = self {
                            this.collectionView!.reloadItemsAtIndexPaths([indexPath!])
                        }
                        })
            )
        case .Move:
            runNSBlockOperation.append(
                NSBlockOperation(block: {[weak self] in
                    if let this = self{
                        this.collectionView!.moveItemAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
                    }
                    })
            )
        case .Delete:
            runNSBlockOperation.append(
                NSBlockOperation(block: {[weak self] in
                    if let this = self{
                        this.collectionView!.deleteItemsAtIndexPaths([indexPath!])
                    }
                    })
            )
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type{
        case .Insert:
            runNSBlockOperation.append(
                NSBlockOperation(block: {[weak self] in
                if let this = self{
                    this.collectionView!.insertSections(NSIndexSet(index: sectionIndex))
                    }
                    })
            )
        case .Delete:
            runNSBlockOperation.append(
                NSBlockOperation(block: {[weak self] in
                    if let this = self{
                        this.collectionView!.deleteSections(NSIndexSet(index: sectionIndex))
                    }
                    })
            )
        default:
            runNSBlockOperation.append(
                NSBlockOperation(block: {[weak self] in
                    if let this = self{
                        this.collectionView!.reloadSections(NSIndexSet(index: sectionIndex))
                    }
                    })
            )
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        collectionView!.performBatchUpdates({ () -> Void in
            for operation: NSBlockOperation in self.runNSBlockOperation{
                operation.start()
            }
            }, completion: {(finished) -> Void in
                self.runNSBlockOperation.removeAll(keepCapacity: false)
        })
    }
    
}
