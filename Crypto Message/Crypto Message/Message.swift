//
//  Message.swift
//  Crypto Message
//
//  Created by Michael Clark on 3/26/15.
//
//

import Foundation
import CoreData
@objc(Message)
class Message: NSManagedObject {

    @NSManaged var owner: NSNumber
    @NSManaged var text: String
    @NSManaged var date: String
    @NSManaged var key: String
    @NSManaged var id: NSNumber
    @NSManaged var device: NSNumber
    @NSManaged var conversation: Conversation
    @NSManaged var sender: MessageSender

}
