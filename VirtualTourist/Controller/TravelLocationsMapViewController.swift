//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by Paul Cristian Percca Julca on 7/22/20.
//  Copyright © 2020 Innovatrix. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController, NSFetchedResultsControllerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    var locations = [CLLocationCoordinate2D]()
    
    var dataController:DataController!
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if UserDefaults.standard.bool(forKey: "HasLaunchedBefore") {
            zoomLevel()
        }
        let myLongPress: UILongPressGestureRecognizer = UILongPressGestureRecognizer()
        myLongPress.addTarget(self, action: #selector(recognizeLongPress(_:)))
        mapView.addGestureRecognizer(myLongPress)
        setupFetchedResultsController()
        createPointAnnotations()
        UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
        createPointAnnotations()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        createPointAnnotations()
        fetchedResultsController = nil
    }
        
    func zoomLevel() {
        let zoomCenterCoordinate = CLLocationCoordinate2D(latitude: UserDefaults.standard.double(forKey: "zoomCenterLatitude"), longitude: UserDefaults.standard.double(forKey: "zoomCenterLongitude"))
        let zoomSpanCoordinate = MKCoordinateSpan(latitudeDelta: UserDefaults.standard.double(forKey: "distanceSpanLatitude"), longitudeDelta: UserDefaults.standard.double(forKey: "distanceSpanLongitude"))
        let region = MKCoordinateRegion(center: zoomCenterCoordinate, span: zoomSpanCoordinate)
        mapView.setRegion(region, animated: true)
    }
    
    func createPointAnnotations() {
        mapView.removeAnnotations(mapView.annotations)
        if let fetchedObjects = fetchedResultsController.fetchedObjects {
            for pin in fetchedObjects {
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
                mapView.addAnnotation(annotation)
            }
        }
    }
    
    @objc private func recognizeLongPress(_ sender: UILongPressGestureRecognizer) {
        if sender.state != UIGestureRecognizer.State.began {
            return
        }
        let annotation = MKPointAnnotation()
        annotation.coordinate = mapView.convert(sender.location(in: mapView), toCoordinateFrom: mapView)
        annotation.title = "title"
        mapView.addAnnotation(annotation)
        
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = annotation.coordinate.latitude
        pin.longitude = annotation.coordinate.longitude
        pin.creationDate = Date()
        try? dataController.viewContext.save()
        print("Long Press was detected  \(annotation.coordinate.latitude) \(annotation.coordinate.longitude)")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let controller = segue.destination as! PhotoAlbumViewController
        let annotation = sender as! MKAnnotation
        controller.dataController = dataController

        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", argumentArray: [annotation.coordinate.latitude, annotation.coordinate.longitude] )
        fetchRequest.predicate = predicate
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            if result.count >= 0 {
                controller.pin = result[0]
            }
        }
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Ok", style: .plain, target: nil, action: nil)
    }
    
}

// MARK: - Map Methods

extension TravelLocationsMapViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"

        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView

        if pinView == nil {
             pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
             pinView!.canShowCallout = true
             pinView!.pinTintColor = .red
         } else {
             pinView!.annotation = annotation
         }
        
        return pinView
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view:  MKAnnotationView){
        print("Coordinate: \(String(describing: view.annotation?.coordinate.latitude)) , \(String(describing: view.annotation?.coordinate.longitude))")
        performSegue(withIdentifier: "openPhotoAlbum", sender: view.annotation)
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        UserDefaults.standard.set(mapView.region.center.latitude, forKey: "zoomCenterLatitude")
        UserDefaults.standard.set(mapView.region.center.longitude, forKey: "zoomCenterLongitude")
        UserDefaults.standard.set(mapView.region.span.latitudeDelta, forKey: "distanceSpanLatitude")
        UserDefaults.standard.set(mapView.region.span.longitudeDelta, forKey: "distanceSpanLongitude")
    }
}
