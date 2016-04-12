//
//  Conversation.swift
//  Crypto Message
//
//  Created by Michael Clark on 3/26/15.
//
//

import Foundation
import CoreData

@objc(Conversation)

class Conversation: NSManagedObject {

    @NSManaged var id: NSNumber
    @NSManaged var name: String
    @NSManaged var message: NSSet

}
