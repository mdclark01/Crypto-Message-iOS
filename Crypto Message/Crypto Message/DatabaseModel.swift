//
//  DatabaseModel.swift
//  Crypto Message
//
//  Created by Michael Clark on 3/12/15.
//
//

import UIKit
import CoreData

class DatabaseModel {
    
    //vars
    var appDel = AppDelegate()
    var context = NSManagedObjectContext()
    
    init(){
        appDel = (UIApplication.sharedApplication().delegate as! AppDelegate)
        context = appDel.managedObjectContext!
    }
    
    func saveUserSession(username:String, password:String, token:String) {
        
        var newUser = NSEntityDescription.insertNewObjectForEntityForName("User", inManagedObjectContext: context) as! NSManagedObject
        newUser.setValue(username, forKey: "username")
        newUser.setValue(password, forKey: "password")
        newUser.setValue(token, forKey: "token")
        
        context.save(nil)
        
    }
    
    func getSessionData() -> NSArray{
        var request = NSFetchRequest(entityName: "User")
        request.returnsObjectsAsFaults = false;
        
        var results = context.executeFetchRequest(request, error: nil)
        
        if results?.count > 0 {
            
        }else{
            println("0 Results Returned")
        }
        
        return results!
    }
    
    func deleteSession() -> Bool{
        var request = NSFetchRequest(entityName: "User")
        request.returnsObjectsAsFaults = false;
        
        var results = context.executeFetchRequest(request, error: nil)
        
        if results?.count > 0 {
            let userToRemove: NSArray = results! as NSArray
            context.deleteObject(userToRemove[0] as! NSManagedObject)
            var savingError: NSError?
            if context.save(&savingError){
                println("Deleted User")
                return true
            }else{
                if let error = savingError{
                    println("NOT DELETED")
                }
                return false
            }
        }else{
            println("0 Results Returned cant delete")
            return false
        }
    }
    
    func saveNewConversation(id:Int, name:String) -> Bool {
        
        var newProduct = NSEntityDescription.insertNewObjectForEntityForName("Conversation", inManagedObjectContext: context) as! NSManagedObject
        newProduct.setValue(id, forKey: "id")
        newProduct.setValue(name, forKey: "name")
        
        var savingError: NSError?
        if context.save(&savingError){
            println("Saved New Convo Data")
            return true
        }else{
            if let error = savingError {
                println("Failed to save Convo Data")
            }//end if
            return false
        }//end if
    }//end func
    
    func getAllConvoData() -> NSArray{
        var request = NSFetchRequest(entityName: "Conversation")
        request.returnsObjectsAsFaults = false;
        
        var results = context.executeFetchRequest(request, error: nil)
        
        if results?.count > 0 {
            
        }else{
            println("0 Results Returned")
        }
        
        return results!
    }
    
    func getConvoDataByID(id:Int) -> NSArray{
        var request = NSFetchRequest(entityName: "Conversation")
        request.returnsObjectsAsFaults = false;
        
        let resultsFilter = NSPredicate(format: "id = %i", id)

        request.predicate = resultsFilter
        
        var result = context.executeFetchRequest(request, error: nil)
        
        if result?.count > 0 {
            
        }else{
            println("0 Results Returned")
        }
        
        return result!
    }
    
    func getLatestMessageID() -> NSArray{
        var request = NSFetchRequest(entityName: "Message")
        request.returnsObjectsAsFaults = false;
        request.fetchLimit = 1

        let sortDescriptor = NSSortDescriptor(key: "id", ascending: false)
        let sortDescriptors = [sortDescriptor]
        
        request.sortDescriptors = [sortDescriptor]
        
        var result = context.executeFetchRequest(request, error: nil)
        
        if result?.count > 0 {
            
        }else{
            println("0 Results Returned")
        }
        
        return result!
    }
    
    func saveNewMessage(convoid:Int, date:String, device:Int, id:Int, senderID:Int, username:String, owner:Int, text:String, key:String) -> Bool {
        
        let convoForMessageInsert:NSArray = getConvoDataByID(convoid)
        
        
        var newMessage = NSEntityDescription.insertNewObjectForEntityForName("Message", inManagedObjectContext: context) as! NSManagedObject
        newMessage.setValue(date, forKey: "date")
        newMessage.setValue(device, forKey: "device")
        newMessage.setValue(id, forKey: "id")
        newMessage.setValue(owner, forKey: "owner")
        newMessage.setValue(text, forKey: "text")
        newMessage.setValue(key, forKey: "key")
        newMessage.setValue(convoForMessageInsert[0] as! NSManagedObject, forKey: "conversation")

        
        var newSender = NSEntityDescription.insertNewObjectForEntityForName("MessageSender", inManagedObjectContext: context) as! NSManagedObject
        newSender.setValue(senderID, forKey: "id")
        newSender.setValue(username, forKey: "username")
        newSender.setValue(newMessage, forKey: "message")
        
        
        var savingError: NSError?
        if context.save(&savingError){
            println("Saved Message To Convo")
            return true
        }else{
            if let error = savingError {
                println("Failed to Save Message To Convo")
            }//end if
            return false
        }//end if

    }
    
    func deleteAllConvos() -> Bool{
        var request = NSFetchRequest(entityName: "Conversation")
        request.returnsObjectsAsFaults = false;
        
        var results = context.executeFetchRequest(request, error: nil)
        
        if results?.count > 0 {
            let convosToDelete: NSArray = results! as NSArray
            
            for convo in convosToDelete {
                var convoObject = convo as! Conversation
                context.deleteObject(convoObject as NSManagedObject)
            }

            var savingError: NSError?
            if context.save(&savingError){
                println("Deleted Convos")
                return true
            }else{
                if let error = savingError{
                    println("Convos Not Deleted")
                }
                return false
            }
        }else{
            println("0 Results Returned cant delete convos")
            return false
        }
    }
}
