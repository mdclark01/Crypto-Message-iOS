//
//  User.swift
//  Crypto Message
//
//  Created by Michael Clark on 3/12/15.
//
//

import Foundation
import CoreData
@objc(User)
class User: NSManagedObject {

    @NSManaged var username: String
    @NSManaged var password: String
    @NSManaged var token: String

}
