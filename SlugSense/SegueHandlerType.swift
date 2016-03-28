//
//  SegueHandlerType.swift
//  SlugSense
//
//  Created by Rigil Stratsoft on 3/23/16.
//  Copyright © 2016 Sean Rada. All rights reserved.
//

import UIKit
import Foundation

protocol SegueHandlerType {
    
    
    /**
     We expect
     the `SegueIdentifier` mapping to be an enum case to `String` mapping.
     
     For example:
     
     enum SegueIdentifier: String {
     case ShowAccount
     case ShowHelp
     ...
     }
     */
    
    // Associated type as enum
    associatedtype SegueIdentifier : RawRepresentable
    
}


extension SegueHandlerType where Self: UIViewController , SegueIdentifier.RawValue == String {
    
    
    func performSegueWithIdentifier(segueIdentifier: SegueIdentifier, sender: AnyObject){
        performSegueWithIdentifier(segueIdentifier.rawValue, sender: sender)
    }
    
    
    func segueIdentifierWithSegue(segue: UIStoryboardSegue) -> SegueIdentifier {
        
        guard let identifier = segue.identifier,
            segueIdentifier =  SegueIdentifier(rawValue: identifier) else {
               
                 fatalError("Couldn't handle segue identifier \(segue.identifier) for view controller of type \(self.dynamicType).")
        }
        
        return segueIdentifier
    }
}