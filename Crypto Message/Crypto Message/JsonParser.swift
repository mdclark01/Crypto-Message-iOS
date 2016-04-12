//
//  JsonParser.swift
//  Crypto Message
//
//  Created by Michael Clark on 3/12/15.
//
//

import Foundation

class JsonParser{
    
    func ParseJson(data: NSData) -> NSDictionary?{
        var error: NSError?
        
        let jsonObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments, error: &error)
        
        if error == nil{
            let deserializedDictionary = jsonObject as! NSDictionary
            return deserializedDictionary
        }else{
            println("An error happened while deserialzing JSON data")
            return nil
        }
    }
    
    func SerialzeJson(dictForPost:NSDictionary)->NSString?{
        //serialize data to json
        var error:NSError?
        let jsonData = NSJSONSerialization.dataWithJSONObject(dictForPost, options: nil, error: &error )
        
        if let data = jsonData{
            if data.length > 0 && error == nil{
                //json as string
                var jsonData = NSString(data: data, encoding: NSUTF8StringEncoding)!
                return jsonData
            }else if data.length == 0 && error == nil{
                println("No data was returned after serialization")
            }else if error != nil{
                println("An error happened = \(error)")
            }
        }
        return nil
    }
    
}//end class