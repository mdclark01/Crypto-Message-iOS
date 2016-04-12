//
//  AppDelegate.swift
//  Crypto Message
//
//  Created by Michael Clark on 3/12/15.
//
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        let settings = UIUserNotificationSettings(forTypes: UIUserNotificationType.Alert, categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        return true
    }
    
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        println("Complete");
        getData();
        completionHandler(UIBackgroundFetchResult.NewData)
        
    }
    
    func getData() -> Void{

        
        var getLatestMessage = DatabaseModel()
        
        var theUsersCreds = getLatestMessage.getSessionData() as NSArray
        var token = ""
        for users in theUsersCreds{
            token = users.valueForKey("token") as! String
        }

        var lastestMessageID = getLatestMessage.getLatestMessageID() as NSArray
        var latestID = lastestMessageID[0].valueForKey("id")! as! Int
        
        //http request
        var postRequest = HTTPRequest()
        postRequest.getWithToken("http://cryptomessage.mobi/api/messages/\(latestID)/", token: token){
            response, data, error in
            dispatch_async(dispatch_get_main_queue(),{
                //stop animating
                if error != nil {
                    println("Error Loading JSON Data \(error)")
                }else if let httpResponse = response as? NSHTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        
                        //get data
                        var error: NSError?
                        let jsonObject = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments, error: &error)
                        let deserializedDictionary = jsonObject as! NSArray
                        if deserializedDictionary.count == 0 {
                            println("No New Messages")
                        }else if deserializedDictionary.count > 0 {
                            var tempArray = [Int]()
                            var insertNewConversations = DatabaseModel()
                            for message in deserializedDictionary{
                                var theMessage = message as NSDictionary
                                
                                var convo = message.valueForKey("conversation") as NSDictionary
                                var convoID = convo.valueForKey("id") as Int
                                var name = convo.valueForKey("name") as String
                                
                                var messageSender = message.valueForKey("messageSender") as NSDictionary
                                var senderID = messageSender.valueForKey("id") as Int
                                var senderUsername = messageSender.valueForKey("username") as String
                                
                                var date = message.valueForKey("date") as String
                                var device = message.valueForKey("device") as Int
                                var id = message.valueForKey("id") as Int
                                var owner = message.valueForKey("owner") as Int
                                var text = message.valueForKey("text") as String
                                var key = message.valueForKey("key") as String
                                
                                if !contains(tempArray,convoID){
                                    tempArray.append(convoID)
                                    insertNewConversations.saveNewConversation(convoID, name: name)
                                }
                                
                                //decrypt AES key with RSA
                                var decryptData = RSA()
                                var keyData = decryptData.decryptData(key as String)
                                
                                //decrypt AES Text with text and string
                                var crypt = AES()
                                
                                var decryptedText: String = crypt.decryptData(text as String, encodedKey: keyData)
                                
                                insertNewConversations.saveNewMessage(convoID, date: date, device: device, id: id, senderID: senderID, username: senderUsername, owner: owner, text: decryptedText, key: key)
                            }//end for
                            
                            //alert user new messages 
                            var localNotification:UILocalNotification = UILocalNotification()
                            
                            localNotification.alertAction = "Crypto Message"
                            localNotification.alertBody = "New Message"
                            localNotification.fireDate = NSDate(timeIntervalSinceNow: 1)
                            UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
                            
                        }//end if
                    }
                }//end if
            })
        }//post request
            
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.cryptomessage.Crypto_Message" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as! NSURL
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("Crypto_Message", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("Crypto_Message.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil, error: &error) == nil {
            coordinator = nil
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges && !moc.save(&error) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
        }
    }

}

