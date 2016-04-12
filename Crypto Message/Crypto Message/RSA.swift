//
//  RSA.swift
//  Crypto Message
//
//  Created by Michael Clark on 3/24/15.
//
//

import Foundation
import Security

class RSA {
    func generateKeys()->(result:OSStatus, publicKey64:String){
        
        //parameters for key size and key type
        let publicKeyParameters: [String: AnyObject] = [
            kSecAttrIsPermanent:true,
            kSecAttrApplicationTag:"com.cryptomessage.Crypto-Message.Public"
        ]
        
        let privateKeyParameters: [String: AnyObject] = [
            kSecAttrIsPermanent:true,
            kSecAttrApplicationTag:"com.cryptomessage.Crypto-Message.Private"
        ]
        
        let parameters: [String: AnyObject] = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits: 2048,
            (kSecPublicKeyAttrs.takeUnretainedValue() as! String) as String: publicKeyParameters,
            (kSecPrivateKeyAttrs.takeUnretainedValue() as! String) as String: privateKeyParameters
        ]
        
        //generates key pairs in keychain
        var publicKeyPtr, privateKeyPtr: Unmanaged<SecKey>?
        var result = SecKeyGeneratePair(parameters, &publicKeyPtr, &privateKeyPtr)
        
        var thePublicKey = publicKeyPtr?.takeRetainedValue()
        var thePrivateKey = privateKeyPtr?.takeRetainedValue()
        

        
        var emptyStringForDecode = ""
        
        if result == 0 {
            
            //key pair generated

            var dataPtr:Unmanaged<AnyObject>?
            
            var queryForKey:[String: AnyObject] = [
                kSecClass:kSecClassKey,
                kSecAttrKeyType: kSecAttrKeyTypeRSA,
                kSecAttrApplicationTag:"com.cryptomessage.Crypto-Message.Public",
                kSecReturnData:true
            ]
            
            let result  = SecItemCopyMatching(queryForKey, &dataPtr)
            
            
            if result == 0 {
                
                var publicKeyData = dataPtr!.takeRetainedValue() as! NSData
                
                // convert to Base64 string
                let base64PublicKey = publicKeyData.base64EncodedStringWithOptions(nil)
//                println("RSA PUBLIC KEY : \(publicKeyData)")
//                println("RSA PUBLIC KEY 64 : \(base64PublicKey)")
                return (result, base64PublicKey)
            }
            
        }
        
       return (result,emptyStringForDecode)
    }
    
    
    
    func encryptData(plainText:String)->String{
        
        //get refrence to public key 
        
        let queryForKey: [String: AnyObject] = [
            kSecClass: kSecClassKey,
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrApplicationTag: "com.cryptomessage.Crypto-Message.Public",
            kSecReturnRef: true
        ]
        
        var keyPtr: Unmanaged<AnyObject>?
        
        var result = SecItemCopyMatching(queryForKey, &keyPtr)
        
        if result == 0{
            
            var thePublicKey = keyPtr!.takeRetainedValue() as! SecKeyRef
            
            let blockSize = SecKeyGetBlockSize(thePublicKey)
            
            let plainTextData = [UInt8](plainText.utf8)
            let plainTextDataLength = UInt(count(plainText))
            var encryptedData = [UInt8](count: Int(blockSize), repeatedValue: 0)
            var encryptedDataLength = blockSize
            
            result = SecKeyEncrypt(thePublicKey, SecPadding(kSecPaddingNone), plainTextData, plainTextDataLength, &encryptedData, &encryptedDataLength)
            
            if result == 0 {
                
                var encryptedText = NSData(bytes: encryptedData, length: Int(encryptedDataLength))
                var encryptedBase64 = encryptedText.base64EncodedStringWithOptions(nil)
                
                return encryptedBase64
            }

        }
        
        return ""
    }
    
    func decryptData(encryptedString:String)->String{
        
        var encryptedData = NSData(base64EncodedString: encryptedString, options: NSDataBase64DecodingOptions(rawValue: 0))!

        var encryptedDataByteArray = [UInt8](count: encryptedData.length, repeatedValue: 0)
        
        encryptedData.getBytes(&encryptedDataByteArray, length: encryptedData.length * sizeof(UInt8))
        
        var encryptedDataLength: UInt = 256
        
        let queryForKey: [String: AnyObject] = [
            kSecClass: kSecClassKey,
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrApplicationTag: "com.cryptomessage.Crypto-Message.Private",
            kSecReturnRef: true
        ]
        
        var keyPtr: Unmanaged<AnyObject>?
        
        var result = SecItemCopyMatching(queryForKey, &keyPtr)
        
        if result == 0{
            
            var thePrivateKey = keyPtr!.takeRetainedValue() as! SecKeyRef
            
            let blockSize = SecKeyGetBlockSize(thePrivateKey)
            
            var decryptedData = [UInt8](count: Int(blockSize), repeatedValue: 0)
            var decryptedDataLength = blockSize
            
            result = SecKeyDecrypt(thePrivateKey, SecPadding(kSecPaddingNone), encryptedDataByteArray, encryptedDataLength, &decryptedData, &decryptedDataLength)
           
            if result == 0 {
                let decryptedText = String(bytes: decryptedData, encoding:NSUTF8StringEncoding)!
                
                return decryptedText

            }
            
        }
        
        return "nothing returned"
    }
    
    func savePublicKey(publicKeyToSave:String, userName:String)->Bool{

        var decodePublicKey = NSData(base64EncodedString: publicKeyToSave, options: NSDataBase64DecodingOptions(rawValue: 0))!
        
        let publicKeyParameters: [String: AnyObject] = [
            kSecAttrIsPermanent:true,
            kSecAttrApplicationTag:"com.cryptomessage.Crypto-Message.\(userName)",
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass:kSecAttrKeyClassPublic,
            kSecClass:kSecClassKey,
            kSecAttrKeySizeInBits: 2048,
            kSecValueData:decodePublicKey
        ]
        
        var result:OSStatus = SecItemAdd(publicKeyParameters, nil)
        
        println("result from saving public key \(result)")
        
        if result == 0 {
            return true
        }else{
            return false
        }
        
    }
    
    func encryptDataForUserName(aesEncodedString:String, userName:String)->String{
        
        //get refrence to public key
        
        let queryForKey: [String: AnyObject] = [
            kSecClass: kSecClassKey,
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrApplicationTag: "com.cryptomessage.Crypto-Message.\(userName)",
            kSecReturnRef: true
        ]
        
        var keyPtr: Unmanaged<AnyObject>?
        
        var result = SecItemCopyMatching(queryForKey, &keyPtr)
        
        if result == 0{
            
            var thePublicKey = keyPtr!.takeRetainedValue() as! SecKeyRef
            
            let blockSize = SecKeyGetBlockSize(thePublicKey)
            
            
//            var aesKeyData = NSData(base64EncodedString: aesEncodedString, options: NSDataBase64DecodingOptions(rawValue: 0))!
//            
//            var aesKeyDataByteArray = [UInt8](count: aesKeyData.length, repeatedValue: 0)
//            
//            aesKeyData.getBytes(&aesKeyDataByteArray, length: aesKeyData.length * sizeof(UInt8))
            
            
            let plainTextData = [UInt8](aesEncodedString.utf8)
            let plainTextDataLength = UInt(count(aesEncodedString))
            var encryptedData = [UInt8](count: Int(blockSize), repeatedValue: 0)
            var encryptedDataLength = blockSize
            
            result = SecKeyEncrypt(thePublicKey, SecPadding(kSecPaddingNone), plainTextData, plainTextDataLength, &encryptedData, &encryptedDataLength)
            
            if result == 0 {
                
                var encryptedText = NSData(bytes: encryptedData, length: Int(encryptedDataLength))
                var encryptedBase64 = encryptedText.base64EncodedStringWithOptions(nil)
                return encryptedBase64
            }
            
        }
        return ""
    }
    
}




