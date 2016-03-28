//
//  Request+CoreDataProperties.swift
//  SyncEngine
//
//  Created by Sean Rada on 11/12/15.
//  Copyright © 2015 Rigil Corp. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Request {

    @NSManaged var data: NSData?
    @NSManaged var headers: NSData?
    @NSManaged var httpMethod: String?
    @NSManaged var identifier: String?
    @NSManaged var url: String?

}
