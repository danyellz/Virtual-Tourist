//
//  PinDetailView.swift
//  VirtualTourist
//
//  Created by TY on 6/17/16.
//  Copyright © 2016 Ty Daniels. All rights reserved.
//

/*Referenced https://stackoverflow.com/questions/12656648/uicollectionview-performing-updates-using-performbatchupdates 
 to get the solution for NSFetchResultsController delegate methods. */

import UIKit
import MapKit
import CoreData

class PinDetailView: UIViewController, MKMapViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var deleteBtn: UIButton!
    @IBOutlet weak var loadBtn: UIButton!
    
    var selectedPin: PinModel!
    var nSBlockOp: [NSBlockOperation] = []
    
    var selectedForDelete = [ImgModel]()
    var selectedIndexes = [NSIndexPath]()
    
    var insertedIndex: [NSIndexPath]!
    var updatedIndex: [NSIndexPath]!
    var deletedIndex: [NSIndexPath]!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(selectedPin)
        
        mapView.delegate = self
        mapView.centerCoordinate = selectedPin.coordinate
        mapView.addAnnotation(selectedPin)
        mapView.userInteractionEnabled = false
        
        deleteBtn.hidden = true
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
        }catch{
            let fetchError = error as NSError
            print("Fetch error: \(fetchError)")
        }
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
                self.saveContext()
        }

        FlickrRequestClient.sharedInstance().getNewGeoImgs(self.selectedPin)
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
        
        fetchedResultsController.delegate = self
        
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
        
        configureUI(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    func configureUI(cell: ImageCollectionCell, atIndexPath indexPath: NSIndexPath) {
        
        let imageController = fetchedResultsController.objectAtIndexPath(indexPath) as! ImgModel
        
        if let image = imageController.image{
            print("Images already exist in cells...")
            imageController.loadUpdateHandler = nil
            cell.flickrImageView.image = image
            print("Image.image \(image)")
            self.saveContext()
            cell.indicatorView.stopAnimating()
        }else {
            print("Adding new images to cells...")
            cell.indicatorView.startAnimating()
            cell.flickrImageView.image = nil
            
            imageController.loadUpdateHandler = {[unowned self] () -> Void in
                dispatch_async(dispatch_get_main_queue(), {
                    self.collectionView.reloadItemsAtIndexPaths([indexPath])
                })
            }
            
            if cell.flickrImageView.image == nil {
                let currentImage = UIImage(named: "positive.png")
                let nextImage = UIImage(named: "negative.png")
                let crossFade = CABasicAnimation(keyPath:"contents")
                crossFade.duration = 2
                crossFade.fromValue = currentImage!.CGImage
                crossFade.toValue = nextImage!.CGImage
                cell.flickrImageView.layer.addAnimation(crossFade, forKey:"animateContents")
                cell.flickrImageView.image = nextImage
            }else {
                cell.indicatorView.stopAnimating()
            }
        }
    }
    

    @IBAction func deleteSelectedImgs(sender: AnyObject) {
        for selectedItems in selectedIndexes {
            selectedForDelete.append(fetchedResultsController.objectAtIndexPath(selectedItems) as! ImgModel)
        }
        
        for cell in selectedForDelete {
            sharedContext.deleteObject(cell)

        }
        
        deleteBtn.hidden = true
        loadBtn.hidden = false
        
        saveContext()
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath){

            let cell = collectionView.cellForItemAtIndexPath(indexPath) as! ImageCollectionCell
            print(cell)
        
        if let selectedIndex = selectedIndexes.indexOf(indexPath) {
            cell.layer.borderWidth = 0
            cell.layer.borderColor = UIColor.clearColor().CGColor
            selectedIndexes.removeAtIndex(selectedIndex)
        }else {
            cell.layer.borderWidth = 2;
            cell.layer.borderColor = UIColor.redColor().CGColor
            selectedIndexes.append(indexPath)
        }
        
            if selectedIndexes.count > 0 {
                loadBtn.hidden = true
                deleteBtn.hidden = false
            }else {
                loadBtn.hidden = false
                deleteBtn.hidden = true
            }
    }

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        nSBlockOp.removeAll(keepCapacity: false)
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        
        switch type {
        case .Insert:
            nSBlockOp.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertSections(NSIndexSet(index: sectionIndex))
                    }
                    })
            )
        case .Delete:
            nSBlockOp.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteSections(NSIndexSet(index: sectionIndex))
                    }
                    })
            )
        default:
            nSBlockOp.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadSections(NSIndexSet(index: sectionIndex))
                    }
                    })
            )
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type {
        case .Insert:
            nSBlockOp.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertItemsAtIndexPaths([newIndexPath!])
                    }
                    })
            )
        case .Delete:
            nSBlockOp.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteItemsAtIndexPaths([indexPath!])
                    }
                    })
            )
        case .Update:
            nSBlockOp.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadItemsAtIndexPaths([indexPath!])
                    }
                    })
            )
        case .Move:
            nSBlockOp.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.moveItemAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
                    }
                    })
            )
        }
    }
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        collectionView.performBatchUpdates({ () -> Void in
            for blockOperation in self.nSBlockOp {
                blockOperation.start()
            }
            }, completion: { (finished) -> Void in
                self.nSBlockOp.removeAll(keepCapacity: false)
        })
        
    }
    
}
