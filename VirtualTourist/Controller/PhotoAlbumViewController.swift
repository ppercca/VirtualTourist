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

class PhotoAlbumViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    var coordinate: CLLocationCoordinate2D!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
//    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    var photos = [UIImage]()
    var page: Int = 1
    override func viewDidLoad() {
        super.viewDidLoad()
        loadPin()
//        newCollectionButton.isEnabled = false
        loadPhotos(page: page) {
//            DispatchQueue.main.async {
//                self.collectionView.reloadData()
//            }
        }
        collectionViewInit()
        
//        let trash = nil //UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteTapped(sender:)))
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let newCollection = UIBarButtonItem(title: "New Collection", style: .plain, target: self, action: #selector(newCollectionTapped(sender:)))
        newCollection.isEnabled = false
//        let select = nil //UIBarButtonItem(title: "Select", style: .plain, target: self, action: #selector(selectTapped(sender:)))
        
        self.toolbarItems = [space, newCollection, space]
        navigationController?.setToolbarHidden(false, animated: false)
    }
    
    @IBAction func deleteTapped(sender: Any) {
//        showDeleteAlert()
    }
    
    @IBAction func newCollectionTapped(sender: Any) {
//        let newText = textView.attributedText.mutableCopy() as! NSMutableAttributedString
//        newText.addAttribute(.font, value: UIFont(name: "OpenSans-Bold", size: 22) as Any, range: textView.selectedRange)
//
//        let selectedTextRange = textView.selectedTextRange
//
//        textView.attributedText = newText
//        textView.selectedTextRange = selectedTextRange
//        note.attributedText = textView.attributedText
//        ((try? dataController?.viewContext.save()) as ()??)
    }
    
    @IBAction func selectTapped(sender: Any) {
//        showDeleteAlert()
    }
    
    func loadPin() {
        let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
        mapView.setRegion(region, animated: true)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
    
    func collectionViewInit() {
        collectionView.delegate = self
        collectionView.dataSource = self
        flowLayout.minimumInteritemSpacing = 3.0
        flowLayout.minimumLineSpacing = 3.0
    }
    
    func loadPhotos(page: Int, completion: () -> Void) {
        FlickrClient.getPhotos(latitude: coordinate.latitude, longitude: coordinate.longitude, page: page, completion:
        handlePhotosResponse(photosResponse:error:))
        completion()
        
    }
    
    func handlePhotosResponse(photosResponse: FlickrPhotosResponse?,error: Error?) {
        guard let photosResponse = photosResponse else { return }
        if photosResponse.photos.photo.count == 0 {
            showFailureMessage(message: "No images were found ", title: "No Images")
        }
        for _ in photosResponse.photos.photo {
            self.photos.append(UIImage.init(imageLiteralResourceName: "PlaceholderImage"))
        }
        collectionView.reloadData()
        var i = 0
        for photo in photosResponse.photos.photo {
            let imageURL = FlickrClient.Endpoints.getPhotoImage(photo.farm, photo.server, photo.id, photo.secret).url
            FlickrClient.requestImageFile(url: imageURL) { (image, error) in
                self.photos[i] = image!
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                    if (photosResponse.photos.photo.count - 1) == i {
//                        self.newCollectionButton.isEnabled = true
                        DispatchQueue.main.async {
                            print(self.toolbarItems?.count ?? "Holi")
                            self.toolbarItems?[1].isEnabled = true
                        }
                    }
                }
                i += 1
            }
        }
    }
    
    // MARK: - Error Message Method
    
    func showFailureMessage(message: String, title: String) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertVC, animated: true, completion: nil)
    }
    
    @IBAction func newCollectionButtonTapped(_ sender: Any) {
        loadPhotos(page: page + 1) {
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
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
        print("numberOfItemsInSection photos.count + \(photos.count)")
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell
//        print("cellForItemAt photos.count + \(photos.count)")
        if photos.count > 0 {
            cell.imageView.image = photos[indexPath.row]
        }
        return cell
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
