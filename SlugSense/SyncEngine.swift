//
//  SyncEngine.swift
//  SyncEngine
//
//  Created by Sean Rada on 8/30/15.
//  Copyright (c) 2015 Rigil Corp. All rights reserved.
//

import Foundation
import CoreData

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PATCH = "PATCH"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

class SyncEngine: NSObject, NSURLSessionTaskDelegate {
    
    /**The time interval between sync ticks.  The default is 30 seconds*/
    var interval: NSTimeInterval = 30
    
    /**A mutable array of currently active NSURLSessions*/
    var trackedSessions = [SessionTracker]()
    
    /**A mutable array of Requests that currently have an active NSURLSession*/
    var requests = [Request]()
    
    /** Username and password credentials for connections*/
    var credentials: NSURLCredential?
    
    private var timer: NSTimer?
    
    /**Singleton*/
    static let sharedEngine = SyncEngine()
    
    //MARK: - Public Methods
    
    /**Returns the progress of all the current tracked sessions that HAVE received a response*/
    @objc func currentSessionProgress() -> Float {
        var totalExpected: Float = 0;
        var totalReceived: Float = 0;
        for trackedSession in trackedSessions {
            if trackedSession.expectedContentLength != nil {
                totalExpected += Float(trackedSession.expectedContentLength!)
                totalReceived += Float((trackedSession.receivedData?.length)!)
            }
        }
        return totalExpected/totalReceived
    }
    
    /**Begins the tick.  Any parameters added to the queue will have their NSURLSession started*/
    func beginSync() {
        //Reset current timer
        if timer != nil {
            if timer!.valid {
                timer!.invalidate()
            }
        }
        
        timer = NSTimer.scheduledTimerWithTimeInterval(interval, target: self, selector: #selector(SyncEngine.tick), userInfo: nil, repeats: true)
        self.tick()
    }
    
    /**Stars an NSURLSession with the given parameters*/
    @objc func sendData(data: NSData?, toURL url: NSURL, httpMethod: String, headers: Dictionary<String, String>?, completion: (returnedJSON: AnyObject?, success: Bool, responseStatusCode: Int) -> Void) {
        
        //Create Session
        let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        if headers != nil {
            sessionConfiguration.HTTPAdditionalHeaders = headers
        }
        
        //Create Request
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = httpMethod
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = data
        if headers != nil {
            for key in Array(headers!.keys) {
                request.setValue(headers![key], forHTTPHeaderField: key)
            }
        }
        
        let sessionTracker = SessionTracker(configuration: sessionConfiguration, delegate: self, delegateQueue: NSOperationQueue.mainQueue())
        let task = sessionTracker.session.dataTaskWithRequest(request)
        sessionTracker.completionHandler = {
            (returnedData: NSData?, success: Bool, responseStatusCode: Int) in
            
            //Convert NSData? to JSON
            var jsonObject: AnyObject? = nil;
            
            if  returnedData != nil {
                
                do {
                    jsonObject = try NSJSONSerialization.JSONObjectWithData(returnedData!, options: NSJSONReadingOptions.MutableContainers)
                    
                    print("SyncEngine - returned json: \(NSString(data: returnedData!, encoding: NSUTF8StringEncoding)!)")
                    
                } catch {
                    
                    //Print error
                    let nserror = error as NSError
                    print("SyncEngine - Unresolved json error \(nserror), \(nserror.userInfo)")
                    print("SyncEngine - Data response: \(NSString(data: returnedData!, encoding:NSUTF8StringEncoding))")
                }
                
            }
            
            //Remove session from sessions array
            for (index, trackedSession) in self.trackedSessions.enumerate().reverse() {
                if (trackedSession === sessionTracker) {
                    self.trackedSessions.removeAtIndex(index)
                    break
                }
            }
            
            //Check if session had an associated Request object and delete the Request
            let fetchRequest = NSFetchRequest(entityName: "Request")
            var fetched = try! self.managedObjectContext.executeFetchRequest(fetchRequest) as! [Request]
            
            var deletedRequest = false
            for i in 0 ..< fetched.count {
                let fetchedRequest = fetched[i]
                
                //Check if the original request data and url matches
                if data != nil && fetchedRequest.data != nil {
                    if data!.isEqualToData(fetchedRequest.data!) && url.absoluteString == fetchedRequest.url! {
                        self.managedObjectContext.deleteObject(fetched[i])
                        deletedRequest = true
                        break
                    }
                    
                } else if data == nil && fetchedRequest.data == nil && fetchedRequest.url! == url.absoluteString {
                    self.managedObjectContext.deleteObject(fetched[i])
                    deletedRequest = true
                    break
                }
                
            }
            
            if deletedRequest {
                print("SyncEngine - deleted old Request")
                self.saveContext()
            }
            
            //Call Completion Handler
            completion(returnedJSON: jsonObject, success: true, responseStatusCode: responseStatusCode)
        }
        
        //Add session to the sessions array to track all of the active sessions
        trackedSessions.append(sessionTracker)
        
        task.resume()
        
    }
    
    /**Creates a NSURLSession with the given parameters that will begin the next time the interval timer ticks.*/
    func addToQueue(data: NSData, urlString: String, httpMethod: HTTPMethod, headers: Dictionary<String, String>, identifier: String) {
        
        let fetchRequest = NSFetchRequest(entityName: "Request")
        
        let fetched = try! self.managedObjectContext.executeFetchRequest(fetchRequest) as! [Request]
        
        //Check if a request already exists in the queue with the same identifier
        //If one does exist, delete it, and then add the recent one
        var deleteObject: Request? = nil
        for request in fetched {
            if request.identifier == identifier {
                deleteObject = request
                break
            }
        }
        if deleteObject != nil {
            self.managedObjectContext.deleteObject(deleteObject!)
        }
        
        let headerData = NSKeyedArchiver.archivedDataWithRootObject(headers)
        
        let newRequest = NSEntityDescription.insertNewObjectForEntityForName("Request", inManagedObjectContext: self.managedObjectContext) as! Request
        newRequest.data = data
        newRequest.url = urlString
        newRequest.headers = headerData
        newRequest.identifier = identifier
        newRequest.httpMethod = self.httpMethodToString(httpMethod)
        
    }
    
    //MARK: - Private Methods
    
    func tick() {
        
        print("SyncEngine - tick")
        //Add a new session for each Request saved
        let fetchRequest = NSFetchRequest(entityName: "Request")
        let fetchedObjects = try! self.managedObjectContext.executeFetchRequest(fetchRequest) as! [Request]
        for request in fetchedObjects {
            
            //Only start another session for  request if it hasn't been done already.
            //This could happen if the session nsurlrequest takes longer than the set interval
            if !requests.contains(request) {
                //Add request to requests
                requests.append(request)
                let headerDict = NSKeyedUnarchiver.unarchiveObjectWithData(request.headers!) as! Dictionary<String, String>
                self.sendData(request.data, toURL: NSURL(string: request.url!)!, httpMethod: request.httpMethod!, headers: headerDict, completion: { (returnedJSON, success, responseStatusCode) -> Void in
                    
                    //Remove request from active requests because the session has completed
                    for (index, request) in self.requests.enumerate() {
                        if  request == self.requests[index] {
                            self.requests.removeAtIndex(index)
                            break
                        }
                    }
                })
            }
            
        }
        
        if fetchedObjects.count <= 0 {
            self.stopSync()
        }
    }
    
    private func stopSync() {
        print("SyncEngine - stop sync")
        if timer != nil {
            if timer!.valid {
                timer!.invalidate()
            }
        }
    }
    
    private func httpMethodToString(httpMethod: HTTPMethod) -> String {
        switch httpMethod {
        case .GET:
            return "GET"
            
        case .POST:
            return "POST"
            
        case .PATCH:
            return "PATCH"
            
        case .PUT:
            return "PUT"
            
        case .DELETE:
            return "DELETE"
        }
    }
    
    //MARK: - <NSURLSessionDataDelegate>
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        print("SyncEngine - didReceiveResponse: \(response) expected length: \(response.expectedContentLength)")
        for trackedSession in trackedSessions {
            if trackedSession.session === session {
                trackedSession.expectedContentLength = response.expectedContentLength
                trackedSession.receivedData = NSMutableData()
                break
            }
        }
        completionHandler(.Allow)
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        print("SyncEngine - didReceiveData")
        for trackedSession in trackedSessions {
            if trackedSession.session === session {
                trackedSession.receivedData!.appendData(data)
                break
            }
        }
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        print("SyncEngine - didCompleteWithError: \(error)")
        for trackedSession in trackedSessions {
            if trackedSession.session === session {
                var statusCode = 0
                if task.response != nil {
                    if task.response!.isKindOfClass(NSHTTPURLResponse) {
                        let nshttpurlResponse = task.response! as! NSHTTPURLResponse
                        statusCode = nshttpurlResponse.statusCode
                    }
                }
                trackedSession.completionHandler(data: trackedSession.receivedData, success: (error == nil) ? true : false, responseStatusCode: statusCode)
                break
            }
        }
    }
    
    //MARK: - <NSURLSessionTaskDelegate>
    
    func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        
        print("SyncEngine - did receive challenge")
        
        if challenge.previousFailureCount == 0 {
            
            if self.credentials != nil {
                challenge.sender?.useCredential(self.credentials!, forAuthenticationChallenge: challenge)
                completionHandler(NSURLSessionAuthChallengeDisposition.UseCredential, self.credentials)
            } else {
                print("SyncEngine - received authentication challenge while credentials are nil")
                completionHandler(NSURLSessionAuthChallengeDisposition.CancelAuthenticationChallenge, nil)
            }
            
        } else {
            
            self.stopSync()
            completionHandler(NSURLSessionAuthChallengeDisposition.CancelAuthenticationChallenge, nil)
            
        }
    }
    
    // MARK: - Core Data stack
    
    private lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.rigil.SwiftCoreData" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    private lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("RequestQueue", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("RequestQueue.sqlite")
        var failureReason = "SyncEngine - There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "SyncEngine - Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("SyncEngine - Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    private lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("SyncEngine - Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    
}
