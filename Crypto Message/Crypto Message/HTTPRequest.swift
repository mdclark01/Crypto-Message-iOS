//
//  HTTPRequest.swift
//  Crypto Message
//
//  Created by Michael Clark on 3/12/15.
//
//

import Foundation

class HTTPRequest {
    
    func post(urlForPost:String, jsonString:NSString, completionHandler: (response:NSURLResponse!, data: NSData!, error:NSError!) -> Void) -> Void{
        
        var urlString = urlForPost
        
        let url = NSURL(string: urlString)
        
        let urlRequest = NSMutableURLRequest(URL: url!, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: 5.0)
        
        urlRequest.HTTPMethod = "POST"
        let body = "\(jsonString)".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion:false)
        urlRequest.HTTPBody = body
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let queue = NSOperationQueue()
        NSURLConnection.sendAsynchronousRequest(urlRequest,
            queue: queue){
                response, data , error in
                completionHandler(response:response, data: data, error:error)
            }
        }
    
    func postWithToken(urlForPost:String, jsonString:NSString, token:String, completionHandler: (response:NSURLResponse!, data: NSData!, error:NSError!) -> Void) -> Void{
        
        var urlString = urlForPost
        
        let url = NSURL(string: urlString)
        
        let urlRequest = NSMutableURLRequest(URL: url!, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: 5.0)
        
        urlRequest.HTTPMethod = "POST"
        let body = "\(jsonString)".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion:false)
        urlRequest.HTTPBody = body
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.addValue("Token \(token)", forHTTPHeaderField: "Authorization")
        
        let queue = NSOperationQueue()
        NSURLConnection.sendAsynchronousRequest(urlRequest,
            queue: queue){
                response, data , error in
                completionHandler(response:response, data: data, error:error)
        }
    }
    
    func getWithToken(urlForGet:String, token:String, completionHandler: (response:NSURLResponse!, data: NSData!, error:NSError!) -> Void) -> Void{
        
        var urlString = urlForGet
        
        let url = NSURL(string: urlString)
        
        let urlRequest = NSMutableURLRequest(URL: url!, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: 5.0)
        
        urlRequest.HTTPMethod = "GET"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.addValue("Token \(token)", forHTTPHeaderField: "Authorization")
        
        let queue = NSOperationQueue()
        NSURLConnection.sendAsynchronousRequest(urlRequest,
            queue: queue){
                response, data , error in
                completionHandler(response:response, data: data, error:error)
        }
    }
    
}//end class