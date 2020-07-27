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

class TravelLocationsMapViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    var coordinate: CLLocationCoordinate2D!
    var locations = [CLLocationCoordinate2D]()
    var dataController:DataController!
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    var pins:  [[Double]] = [[-2.197755516486268, -74.66919744058595]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if UserDefaults.standard.bool(forKey: "HasLaunchedBefore") {
            zoomLevel()
        }
        let myLongPress: UILongPressGestureRecognizer = UILongPressGestureRecognizer()
        myLongPress.addTarget(self, action: #selector(recognizeLongPress(_:)))
        mapView.addGestureRecognizer(myLongPress)
        
        createPointAnnotations()
        UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        createPointAnnotations()
    }
        
    func zoomLevel() {
        let zoomCenterCoordinate = CLLocationCoordinate2D(latitude: UserDefaults.standard.double(forKey: "zoomCenterLatitude"), longitude: UserDefaults.standard.double(forKey: "zoomCenterLongitude"))
        let zoomSpanCoordinate = MKCoordinateSpan(latitudeDelta: UserDefaults.standard.double(forKey: "distanceSpanLatitude"), longitudeDelta: UserDefaults.standard.double(forKey: "distanceSpanLongitude"))
        let region = MKCoordinateRegion(center: zoomCenterCoordinate, span: zoomSpanCoordinate)
        mapView.setRegion(region, animated: true)
    }
    
    func createPointAnnotations() {
        mapView.removeAnnotations(mapView.annotations)
        for pin in pins {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: pin[0], longitude: pin[1])
            mapView.addAnnotation(annotation)
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
        pins.append([annotation.coordinate.latitude, annotation.coordinate.longitude])
        print("Long Press was detected")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let controller = segue.destination as! PhotoAlbumViewController
        controller.coordinate = coordinate
        print("Prepare Coordinate  \(String(describing: controller.coordinate))")
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Ok", style: .plain, target: nil, action: nil)
    }

}

extension TravelLocationsMapViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"

        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView

        if pinView == nil {
             pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
             pinView!.canShowCallout = true
             pinView!.pinTintColor = .red
//             pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
         }
         else {
             pinView!.annotation = annotation
         }
        
        return pinView
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view:  MKAnnotationView){
        coordinate = view.annotation?.coordinate
        print("Coordinate  \(String(describing: coordinate))")
        performSegue(withIdentifier: "openPhotoAlbum", sender: self)
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        UserDefaults.standard.set(mapView.region.center.latitude, forKey: "zoomCenterLatitude")
        UserDefaults.standard.set(mapView.region.center.longitude, forKey: "zoomCenterLongitude")
        UserDefaults.standard.set(mapView.region.span.latitudeDelta, forKey: "distanceSpanLatitude")
        UserDefaults.standard.set(mapView.region.span.longitudeDelta, forKey: "distanceSpanLongitude")
    }
}
