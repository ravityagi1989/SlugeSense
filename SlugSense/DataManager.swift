//
//  DataManager.swift
//  SlugSense
//
//  Created by Sean Rada on 2/23/16.
//  Copyright © 2016 Sean Rada. All rights reserved.
//

import UIKit
import CoreData

class DataManager: NSObject {

    //Singleton
    static let sharedManager = DataManager()
    
    internal lazy var locations: [Location] = {
        let entityDescription = NSEntityDescription.entityForName("Location", inManagedObjectContext: CoreDataManager.sharedManager.managedObjectContext)
        let request = NSFetchRequest(entityName: "Location")
        
        var fetched = try! CoreDataManager.sharedManager.managedObjectContext.executeFetchRequest(request) as! [Location]
        
        return fetched
        
    }()
    
    
}
