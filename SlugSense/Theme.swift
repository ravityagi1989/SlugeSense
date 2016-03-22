//
//  Theme.swift
//  SlugSense
//
//  Created by Rigil Stratsoft on 3/21/16.
//  Copyright © 2016 Sean Rada. All rights reserved.
//

import Foundation
import UIKit

class Theme {
    
    // MARK: - Public class methods
    
    class func redColor() -> UIColor {
        return UIColor(red: 250.0/255.0, green: 66.0/255.0, blue: 70.0/255.0, alpha: 1.0)
    }
    
    class func blueColor() -> UIColor {
        return UIColor(red: 45.0/255.0, green: 59.0/255.0, blue: 108.0/255.0, alpha: 1.0)
    }
    
    
    
    
}


// Extention on UIImage

extension UIImage {
    
    /// Provide mapping b/w enum cases and string represntation of images
    enum AssetIdentifier: String {
        //Use enumeration just to pass image identifier so that we don't have to unwrap the return value in code
        
        case Location = "location"
        case Pin      = "pin"
        case Wheel    = "wheel"
 
    }
  
    convenience init!(assetIdentifier: AssetIdentifier) {
        self.init(named: assetIdentifier.rawValue)
    }
}