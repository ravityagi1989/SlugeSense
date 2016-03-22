//
//  Location+CoreDataProperties.swift
//  SlugSense
//
//  Created by Sean Rada on 2/23/16.
//  Copyright © 2016 Sean Rada. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Location {

    @NSManaged var latitude: NSNumber?
    @NSManaged var longitude: NSNumber?
    @NSManaged var name: String?
    @NSManaged var details: String?
    @NSManaged var uid: NSNumber?
    @NSManaged var ratings: NSManagedObject?
    @NSManaged var messages: NSManagedObject?

}
