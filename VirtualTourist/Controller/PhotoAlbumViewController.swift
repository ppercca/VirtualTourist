//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Paul Cristian Percca Julca on 7/24/20.
//  Copyright © 2020 Innovatrix. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

enum Mode {
  case view
  case select
}

class PhotoAlbumViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var page: Int = 1
    var blockOperations: [BlockOperation] = []
    
    var pin: Pin!
    var dataController:DataController!
    var fetchedResultsController:NSFetchedResultsController<Photo>!
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "\(String(describing: pin))-photos")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    var dictionarySelectedIndecPath: [IndexPath: Bool] = [:]
    var mMode: Mode = .view {
      didSet {
        switch mMode {
        case .view:
          for (key, value) in dictionarySelectedIndecPath {
            if value {
              collectionView.deselectItem(at: key, animated: true)
            }
          }
          dictionarySelectedIndecPath.removeAll()
          configureToolbarItems(mode: mMode)
          collectionView.allowsMultipleSelection = false
        case .select:
          configureToolbarItems(mode: mMode)
          collectionView.allowsMultipleSelection = true
        }
      }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFetchedResultsController()
        configureMap()
        configureCollection()
        configureToolbarItems(mode: .view)
        if let fetchedObjects = fetchedResultsController.fetchedObjects {
            if fetchedObjects.count == 0 {
                loadPhotos(page: page)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setToolbarHidden(true, animated: false)
    }
    
    // MARK: - Configuration Methods
    
    func configureMap() {
        let coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        mapView.setRegion(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)), animated: true)
    }
    
    func configureCollection() {
        collectionView.delegate = self
        collectionView.dataSource = self
        flowLayout.minimumInteritemSpacing = 3.0
        flowLayout.minimumLineSpacing = 3.0
    }
    
    func configureToolbarItems(mode: Mode) {
        let trash = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteTapped(sender:)))
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let newCollection = UIBarButtonItem(title: "New Collection", style: .plain, target: self, action: #selector(newCollectionTapped(sender:)))
        switch mode {
        case .view:
            let select = UIBarButtonItem(title: "Select", style: .plain, target: self, action: #selector(selectTapped(sender:)))
            self.toolbarItems = [space,space, newCollection, space, select]
            if let fetchedObjects = fetchedResultsController.fetchedObjects {
                if fetchedObjects.count == 0 {
                    newCollection.isEnabled = false
                }
            }
        case .select:
            let select = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(selectTapped(sender:)))
            self.toolbarItems = [trash, space, newCollection, space, select]
            newCollection.isEnabled = false
        }
        navigationController?.setToolbarHidden(false, animated: false)
    }
    
    @objc func deleteTapped(sender: Any) {
        var deleteNeededIndexPaths: [IndexPath] = []
        for (key, value) in dictionarySelectedIndecPath {
          if value {
            deleteNeededIndexPaths.append(key)
          }
        }
        for indexPath in deleteNeededIndexPaths.sorted(by: { $0.item > $1.item }) {
            let photoToDelete = fetchedResultsController.object(at: indexPath)
            dataController.viewContext.delete(photoToDelete)
            try? dataController.viewContext.save()
        }
        dictionarySelectedIndecPath.removeAll()
    }
    
    @objc func newCollectionTapped(sender: Any) {
        if let fetchedObjects = fetchedResultsController.fetchedObjects {
            for fetchedObject in fetchedObjects {
                dataController.viewContext.delete(fetchedObject)
            }
            try? dataController.viewContext.save()
        }
        page += 1
        loadPhotos(page: page)
    }
    
    @objc func selectTapped(sender: Any) {
        mMode = mMode == .view ? .select : .view
    }
    
    func loading(_ value: Bool) {
        if value {
            activityIndicator.startAnimating()
            self.collectionView.alpha = 0.8
        } else {
            self.collectionView.alpha = 1
            activityIndicator.stopAnimating()
        }
    }
    
    // MARK: - Photos Methods
    
    func loadPhotos(page: Int) {
        loading(true)
        FlickrClient.getPhotos(latitude: pin.latitude, longitude: pin.longitude, page: page, completion: handlePhotosResponse(photosResponse:error:))
    }
    
    func handlePhotosResponse(photosResponse: FlickrPhotosResponse?,error: Error?) {
        loading(false)
        guard let photosResponse = photosResponse else { return }
        if photosResponse.photos.photo.count == 0 {
            self.showFailureMessage(message: "No images were found ", title: "No Images")
        } else {
            for _ in photosResponse.photos.photo {
                let photo = Photo(context: dataController.viewContext)
                photo.pin = pin
                photo.image = UIImage.init(imageLiteralResourceName: "PlaceholderImage").jpegData(compressionQuality: 1.0)
                photo.creationDate = Date()
                try? dataController.viewContext.save()
            }
        }
        DispatchQueue.global(qos: .background).async { () -> Void in
            self.loadPhotoImages(photos: photosResponse.photos.photo)
        }
    }
    
    func loadPhotoImages(photos: [FlickrPhoto]){
        var i = 0
        for photo in photos {
            let imageURL = FlickrClient.Endpoints.getPhotoImage(photo.farm, photo.server, photo.id, photo.secret).url
            FlickrClient.requestImageFile(url: imageURL, index: i, completionHandler: handlePhotosImagesResponse(image:error:index:))
            i += 1
        }
    }

    func handlePhotosImagesResponse(image: UIImage? , error: Error?, index: Int) {
        if let image = image {
            if let fetchedObjects = fetchedResultsController.fetchedObjects {
                fetchedObjects[index].image = image.jpegData(compressionQuality: 1.0)
                try? dataController.viewContext.save()

                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                    if (fetchedObjects.count - 1) == index {
                        print(self.toolbarItems?.count ?? "Holi")
                        self.toolbarItems?[2].isEnabled = true
                    }
                }
            }
        }
    }
    
    // MARK: - Error Message Method
    
    func showFailureMessage(message: String, title: String) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertVC, animated: true, completion: nil)
    }

}

// MARK: - Map Method

extension PhotoAlbumViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let myPinIdentifier = "PinAnnotationIdentifier"
        let myPinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: myPinIdentifier)
        myPinView.animatesDrop = true
        myPinView.canShowCallout = true
        myPinView.annotation = annotation
        return myPinView
    }
}

// MARK: - Collection Methods

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[0].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let photo = fetchedResultsController.object(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell
        cell.imageView.image = UIImage(data: photo.image!)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
      switch mMode {
      case .view:
        collectionView.deselectItem(at: indexPath, animated: true)
      case .select:
        dictionarySelectedIndecPath[indexPath] = true
      }
    }
      
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
      if mMode == .select {
        dictionarySelectedIndecPath[indexPath] = false
      }
    }
}

extension PhotoAlbumViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = view.frame.size.width
        let columns:CGFloat = 3.0
        let dimension = (width - ((columns - 1) * 3.0)) / columns
        return CGSize(width: dimension, height: dimension * 0.9)
    }

}

// MARK: - NSFetchedResultsControllerDelegate Methods

extension PhotoAlbumViewController:NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertItems(at: [newIndexPath!])
                    }
                })
            )
            break
        case .delete:
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteItems(at: [indexPath!])
                    }
                })
            )
            break
        case .update:
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadItems(at: [indexPath!])
                    }
                })
            )
            break
        case .move:
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.moveItem(at: indexPath!, to: newIndexPath!)
                    }
                })
            )
            break
        default:
                break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let indexSet = IndexSet(integer: sectionIndex)
        switch type {
        case .insert: collectionView.insertSections(indexSet)
        case .delete: collectionView.deleteSections(indexSet)
        case .update, .move:
            fatalError("Invalid change type in controller(_:didChange:atSectionIndex:for:). Only .insert or .delete should be possible.")
        default:
            break
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates({ () -> Void in
            for blockOperation in self.blockOperations {
                blockOperation.start()
            }
            }, completion: { (finished) -> Void in
                self.blockOperations.removeAll(keepingCapacity: false)
        })
    }
    
}
