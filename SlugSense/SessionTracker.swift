//
//  SessionTracker.swift
//  SyncEngine
//
//  Created by Sean Rada on 12/1/15.
//  Copyright © 2015 Rigil Corp. All rights reserved.
//

import UIKit

class SessionTracker: AnyObject {
    
    //Completion block initilized to nil
    var completionHandler:((data: NSData?, success: Bool, responseStatusCode: Int) -> Void)!
    
    var session: NSURLSession!
    
    var receivedData: NSMutableData?
    
    var expectedContentLength: Int64?
    
    convenience init(configuration: NSURLSessionConfiguration, delegate: NSURLSessionDelegate?, delegateQueue queue: NSOperationQueue?) {
        self.init()
        session = NSURLSession(configuration: configuration, delegate: delegate, delegateQueue: queue)
    }
    
}
