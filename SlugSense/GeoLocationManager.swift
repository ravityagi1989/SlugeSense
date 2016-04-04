//
//  GeoLocationManager.swift
//  SlugSense
//
//  Created by Rigil Stratsoft on 4/1/16.
//  Copyright © 2016 Sean Rada. All rights reserved.
//

import Foundation
import MapKit
import CoreData

extension CLLocationDistance {
    // 'self' represent distance in meter
    // 1 mile = 1609.34 meters
    var mile: CLLocationDistance      {  return self / 1609.34 }
    
}


class GeoLocationManager: NSObject, CLLocationManagerDelegate {

   
    // Singleton
   static let sharedManager = GeoLocationManager()
   
    // 1/10th of a mile distance
  private let MIN_NOTIFY_DISTACNCE: CLLocationDistance = 0.1
    
   private  var locationManager : CLLocationManager!
 
   var userLocation : CLLocation?
    
    private lazy var locations: [Location] = {
        let entityDescription = NSEntityDescription.entityForName("Location", inManagedObjectContext: CoreDataManager.sharedManager.managedObjectContext)
        let request = NSFetchRequest(entityName: "Location")
        
        var fetched = try! CoreDataManager.sharedManager.managedObjectContext.executeFetchRequest(request) as! [Location]
        
        return fetched
        
    }()
    
   
    
    
    // MARK: Initialization
    
    private override init() {
        super.init()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter =  kCLDistanceFilterNone
        locationManager.requestWhenInUseAuthorization() // ask for user permission to find our location
    }
    
    
    
    // MARK: - Methods
    
    /// start updating user's current location
    func startTracking()  {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        locationManager.startUpdatingLocation()
    }
    
    /// stop updating user's location
    func stopTracking() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        locationManager.stopUpdatingLocation()
        userLocation = nil
    }
    
    
    private func checkAndNotify() {
        
        var shouldNotify = false
        
        for savedLoc in locations  as [Location]{
            
            let fromLoc = CLLocation(latitude:(savedLoc.latitude?.doubleValue)! , longitude: (savedLoc.longitude?.doubleValue)! )
            
            guard let currentDistance  = (userLocation?.distanceFromLocation(fromLoc))?.mile  where currentDistance >=  MIN_NOTIFY_DISTACNCE else{ continue }
            
             shouldNotify = true
             break
        }
        
        
        if shouldNotify {
            
            // notify
            
        }
        
        
    }
    
    // MARK: - <CLLocationManagerDelegate>
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
      
        guard let currentLoc = locations.last where currentLoc.speed < 0 else { return }
        userLocation = CLLocation(latitude: 28.625566, longitude: 77.373255) // Pinnacle Tower
        
         checkAndNotify()
      
    }
    
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
    
    }
    
}