//
//  Message+CoreDataProperties.swift
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

extension Message {

    @NSManaged var text: String?
    @NSManaged var userID: String?
    @NSManaged var timestamp: NSDate?
    @NSManaged var location: Location?

}
