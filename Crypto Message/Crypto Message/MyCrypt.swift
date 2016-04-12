//
//  MyCrypt.swift
//  Crypto Message
//
//  Created by Michael Clark on 4/8/15.
//
//

import UIKit

class MyCrypt: NSObject {
    let key = "MySecretPassword"
    
    func encryptString(estring: String) -> NSData {
        var edata = MyRNEncryptor.encryptData(estring.dataUsingEncoding(NSUTF8StringEncoding,         allowLossyConversion: true), password: key, error: nil)
        
        return edata
    }
    
    func decryptData(edata: NSData) -> String {
        
        var pdata = RNDecryptor.decryptData(edata, withPassword: key, error: nil)
        var pstring: String = MyRNEncryptor.stringFromData(pdata)
        return pstring
    }
}
