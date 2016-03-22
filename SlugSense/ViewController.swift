//
//  ViewController.swift
//  SlugSense
//
//  Created by Sean Rada on 2/22/16.
//  Copyright © 2016 Sean Rada. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet var map: MKMapView?
    
    @IBOutlet weak var bottomView: UIView!
    
    var didShowUserLocation = false

    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Setup bottom view
        self.bottomView.backgroundColor = Theme.redColor()
        
        self.title = "Location Title"
        
        
        //Ask for user location permission
        if (CLLocationManager.locationServicesEnabled())
        {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }
        
        map?.delegate = self
        
        //Show Slug Line locations
        let locations = DataManager.sharedManager.locations
        for location in locations {
            print("location \(location)")
            let pin = SlugPointAnnotation()
            pin.coordinate = CLLocationCoordinate2D(latitude: location.latitude!.doubleValue, longitude: location.longitude!.doubleValue)
            pin.title = location.name
            pin.location = location
            map?.addAnnotation(pin)
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - <MKMapViewDelegate>
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        
        if didShowUserLocation == false {
            
            let userLocation = map?.userLocation
            
            let region = MKCoordinateRegionMakeWithDistance(
                userLocation!.coordinate, 2000, 2000)
            
            map?.setRegion(region, animated: true)
            
            didShowUserLocation = true
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        print("map delegate")
        
        //keep default view for user location
        if annotation.isKindOfClass(MKUserLocation) {
            return nil
        }
        
        let annotationID = "annotationView"
        
        var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(annotationID)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationID)
        }
        
        annotationView?.image = UIImage(named: "pin")
        annotationView?.annotation = annotation
        
        return annotationView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        print("selected")
        
        let slugAnnotation = view.annotation as! SlugPointAnnotation
        self.title = slugAnnotation.location?.name
        
    }
    
}

