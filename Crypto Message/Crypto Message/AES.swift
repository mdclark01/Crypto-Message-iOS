//
//  AES.swift
//  Crypto Message
//
//  Created by Michael Clark on 4/8/15.
//
//

import UIKit

class AES: NSObject {
    
    func randomStringWithLength (len : Int) -> NSString {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$&*()"
        
        var randomString : NSMutableString = NSMutableString(capacity: len)
        
        for (var i=0; i < len; i++){
            var length = UInt32 (letters.length)
            var rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
        }
        
        return randomString
    }
    
    func encryptString(estring: String) -> (base64Text:String, base64Key:String){
        
        let key = self.randomStringWithLength(16)
        
        var edata = MyRNEncryptor.encryptData(estring.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true), password: key as String, error: nil)
        
        let encodedText = edata.base64EncodedStringWithOptions(nil)
        let keyData = key.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        let encodedKey = keyData!.base64EncodedStringWithOptions(nil)
        
        return (encodedText, encodedKey)
    }
    
    func decryptData(encryptedEncodedText: String, encodedKey:String) -> String {
        
        let decodedText = NSData(base64EncodedString: encryptedEncodedText, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
        
        let decodedKey = NSData(base64EncodedString: encodedKey, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
        let keyAsString = NSString(data: decodedKey!, encoding: NSUTF8StringEncoding)
        
        var pdata = RNDecryptor.decryptData(decodedText!, withPassword: keyAsString! as String, error: nil)
        var pstring: String = MyRNEncryptor.stringFromData(pdata)
        return pstring
    }
}
