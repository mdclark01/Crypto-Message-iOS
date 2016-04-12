//
//  ViewController.swift
//  Crypto Message
//
//  Created by Michael Clark on 3/12/15.
//
//

import UIKit

class ViewController: UIViewController {
    
    var userDict = NSMutableDictionary()
    var token = String()
    
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    
    @IBAction func login(sender: UIButton) {
        //add user to dictionary for proccessing
        self.userDict.setValue(self.username.text, forKey: "username")
        self.userDict.setValue(self.password.text, forKey: "password")
        
        //serialize dict
        var serialzeJson = JsonParser()
        var jsonStringForPost = serialzeJson.SerialzeJson(self.userDict)
        
        //show activity
        var actInd : UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRectMake(0,0, self.view.frame.width, 800)) as UIActivityIndicatorView
        actInd.backgroundColor = UIColor(red:(28/255), green:(69/255) , blue:(90/255), alpha:0.5)
        actInd.center = self.view.center
        actInd.hidesWhenStopped = true
        actInd.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.WhiteLarge
        view.addSubview(actInd)
        actInd.startAnimating()
        
        //http request
        var postRequest = HTTPRequest()
        postRequest.post("http://cryptomessage.mobi/api/login/", jsonString: jsonStringForPost!){
            response, data, error in
            dispatch_async(dispatch_get_main_queue(),{
                //stop animating
                actInd.stopAnimating()
                if error != nil {
                    println("Error Loading JSON Data \(error)")
                }else if let httpResponse = response as? NSHTTPURLResponse {
                    
                    if httpResponse.statusCode == 200 {
                        var parseTheJson = JsonParser()
                        var json = parseTheJson.ParseJson(data)!
                        self.token = json.valueForKey("token") as! String
                        
                        //DELETE THIS AND UNCOMMENT self.generatePublicKeyPair when done with colan1
//                        var modelData = DatabaseModel()
//                        modelData.saveUserSession(self.username.text, password: self.password.text, token: self.token)
//                        self.getMessageData()
                        
                        //generate public and private key pairs and register device
                        self.generatePublicKeyPair()
                        
                    }else{
                        self.alert("Error", message: "Usern Name or Password Incorrect")
                    }
                }//end if
            })
        }//post request

    }
    
    @IBAction func backgroundTap(sender: UIControl){
        username.resignFirstResponder()
        password.resignFirstResponder()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // if user already in database then someone is alredy logged in
        var modelData = DatabaseModel()
        var userData = modelData.getSessionData()
        if userData.count > 0{
            performSegueWithIdentifier("messages", sender: self)
        }
    }
    
    func generatePublicKeyPair(){
        var genKeys = RSA()
        var keys = genKeys.generateKeys()
        if keys.result == 0 {
            //NEED TO PASS PUBLIC KEY TO REGISTERDEVICE FUNCTION
            //if key pair generation is successful then register device
            self.registerDevice(keys.publicKey64)
        }
    }
    
    
    func registerDevice(publicKey64:String){
        var jsonStringForPost = "{ \"publicKey\":\"\(publicKey64)\"}"
        
        //show activity
        var actInd : UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRectMake(0,0, self.view.frame.width, 800)) as UIActivityIndicatorView
        actInd.backgroundColor = UIColor(red:(28/255), green:(69/255) , blue:(90/255), alpha:0.5)
        actInd.center = self.view.center
        actInd.hidesWhenStopped = true
        actInd.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.WhiteLarge
        view.addSubview(actInd)
        actInd.startAnimating()
        
        //http request
        var postRequest = HTTPRequest()
        postRequest.postWithToken("http://cryptomessage.mobi/api/createdevice/", jsonString: jsonStringForPost, token: self.token){
            response, data, error in
            dispatch_async(dispatch_get_main_queue(),{
                //stop animating
                actInd.stopAnimating()
                if error != nil {
                    println("Error Loading JSON Data \(error)")
                }else if let httpResponse = response as? NSHTTPURLResponse {
                    
                    if httpResponse.statusCode == 201 {
                        //clear fields
                        
                        var saveTheUser = DatabaseModel()
                        saveTheUser.saveUserSession(self.username.text, password: self.password.text, token: self.token)
                        
                        //clear the form
                        self.username.text = ""
                        self.password.text = ""
                        
                        self.getMessageData()
                        
                    }else{
                        self.alert("Error", message: "Could Not Register Device")
                    }
                }//end if
            })
        }//post request
    
    }
    
    func getMessageData(){
        
        //show activity
        var actInd : UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRectMake(0,0, self.view.frame.width, 800)) as UIActivityIndicatorView
        actInd.backgroundColor = UIColor(red:(28/255), green:(69/255) , blue:(90/255), alpha:0.5)
        actInd.center = self.view.center
        actInd.hidesWhenStopped = true
        actInd.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.WhiteLarge
        view.addSubview(actInd)
        actInd.startAnimating()
        
        //http request
        var postRequest = HTTPRequest()
        postRequest.getWithToken("http://cryptomessage.mobi/api/messages/0/", token: self.token){
            response, data, error in
            dispatch_async(dispatch_get_main_queue(),{
                //stop animating
                if error != nil {
                    actInd.stopAnimating()
                    println("Error Loading JSON Data \(error)")
                }else if let httpResponse = response as? NSHTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        
                        //get data
                        var error: NSError?
                        let jsonObject = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments, error: &error)
                        let deserializedDictionary = jsonObject as! NSArray

                        var tempArray = [Int]()
                        var insertNewConversations = DatabaseModel()
                        for message in deserializedDictionary{
                            var theMessage = message as! NSDictionary
                        
                            var convo = message.valueForKey("conversation") as! NSDictionary
                                var convoID = convo.valueForKey("id") as! Int
                                var name = convo.valueForKey("name") as! String

                            var messageSender = message.valueForKey("messageSender") as! NSDictionary
                                var senderID = messageSender.valueForKey("id") as! Int
                                var senderUsername = messageSender.valueForKey("username") as! String
                            
                            var date = message.valueForKey("date") as! String
                            var device = message.valueForKey("device") as! Int
                            var id = message.valueForKey("id") as! Int
                            var owner = message.valueForKey("owner") as! Int
                            var text = message.valueForKey("text") as! String
                            var key = message.valueForKey("key") as! String
                            
                            if !contains(tempArray,convoID){
                                tempArray.append(convoID)
                                insertNewConversations.saveNewConversation(convoID, name: name)
                            }
                            
                            //decrypt AES key with RSA
                            var decryptData = RSA()
                            var keyData = decryptData.decryptData(key as String)
                            
                            //decrypt AES Text with text and string
                            var crypt = AES()
                            
                            var decryptedText: String = crypt.decryptData(text as String, encodedKey: keyData)
                            
                            insertNewConversations.saveNewMessage(convoID, date: date, device: device, id: id, senderID: senderID, username: senderUsername, owner: owner, text: decryptedText, key: key)
                            
                        }
                        
                        actInd.stopAnimating()
                        
                        //Show Messages
                        self.performSegueWithIdentifier("messages", sender: self)
                        
                    }
                }//end if
            })
        }//post request
    }
    
    override func viewWillAppear(animated: Bool) {
        super.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func textFieldShouldReturn(textField: UITextField!) -> Bool // called when 'return' key pressed. return NO to ignore.
    {
        self.view.endEditing(true)
        return true
    }

    func alert(title:String, message:String){
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        
        let OKAction = UIAlertAction(title: "Ok", style: .Default) { (action) in
            //do somethign here
        }
        alertController.addAction(OKAction)
        
        self.presentViewController(alertController, animated: true) {
            // just present the contorller
        }
        
    }//end alert
    
}

