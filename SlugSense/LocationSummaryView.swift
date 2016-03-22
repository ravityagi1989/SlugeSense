//
//  LocationSummaryView.swift
//  SlugSense
//
//  Created by Sean Rada on 2/23/16.
//  Copyright © 2016 Sean Rada. All rights reserved.
//

import UIKit

class LocationSummaryView: UIView {

    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        print("summary frame \(self.frame)")
        self.backgroundColor = UIColor.blueColor()
    }
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
