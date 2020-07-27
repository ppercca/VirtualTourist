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

enum Mode {
  case view
  case select
}

class PhotoAlbumViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    var coordinate: CLLocationCoordinate2D!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    var photos = [UIImage]()
    var page: Int = 1
    
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
        configureMap()
        configureCollection()
        configureToolbarItems(mode: .view)
        loadPhotos(page: page)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setToolbarHidden(true, animated: false)
    }
    
    func configureMap() {
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
            if photos.count == 0 {
                newCollection.isEnabled = false
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
        for i in deleteNeededIndexPaths.sorted(by: { $0.item > $1.item }) {
          photos.remove(at: i.item)
        }
        collectionView.deleteItems(at: deleteNeededIndexPaths)
        dictionarySelectedIndecPath.removeAll()
    }
    
    @objc func newCollectionTapped(sender: Any) {
        photos = [UIImage]()
        collectionView.reloadData()
        page += 1
        loadPhotos(page: page)
    }
    
    @objc func selectTapped(sender: Any) {
        mMode = mMode == .view ? .select : .view
    }
    
    func loadPhotos(page: Int) {
        FlickrClient.getPhotos(latitude: coordinate.latitude, longitude: coordinate.longitude, page: page, completion: handlePhotosResponse(photosResponse:error:))
    }
    
    func handlePhotosResponse(photosResponse: FlickrPhotosResponse?,error: Error?) { //
        guard let photosResponse = photosResponse else { return }
        
        if photosResponse.photos.photo.count == 0 {
            self.showFailureMessage(message: "No images were found ", title: "No Images")
        } else {
            for _ in photosResponse.photos.photo {
                self.photos.append(UIImage.init(imageLiteralResourceName: "PlaceholderImage"))
            }
        }
        DispatchQueue.main.async {
            self.collectionView.reloadData()
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
            photos[index] = image
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                if (self.photos.count - 1) == index {
                    print(self.toolbarItems?.count ?? "Holi")
                    self.toolbarItems?[2].isEnabled = true
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


extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell
        if photos.count > 0 {
            cell.imageView.image = photos[indexPath.row]
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
      switch mMode {
      case .view:
        collectionView.deselectItem(at: indexPath, animated: true)
        let item = photos[indexPath.item]
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
