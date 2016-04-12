//
//  MessageSender.swift
//  Crypto Message
//
//  Created by Michael Clark on 3/26/15.
//
//

import Foundation
import CoreData
@objc(MessageSender)
class MessageSender: NSManagedObject {

    @NSManaged var id: NSNumber
    @NSManaged var username: String
    @NSManaged var message: Message

}
