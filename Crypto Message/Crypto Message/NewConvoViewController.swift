//
//  NewConvoViewController.swift
//  Crypto Message
//
//  Created by Michael Clark on 4/9/15.
//
//

import UIKit

class NewConvoViewController: UIViewController {

    @IBOutlet weak var recipients: UITextField!
    @IBOutlet weak var messageToSend: UITextField!
    
    var token = String()
    var userNameArray = [String]()
    var publicKeys = [String:NSDictionary]()
    var ownerUserName = String()
    var senderID = Int()
    var currentUser = String()
    var userNamesSring = String()
    @IBAction func sendNow(sender: UIButton) {
        
        self.startConvo()
        
    }
    
    @IBAction func getKeys(sender: UIButton) {
        self.userNamesSring = self.recipients.text + "," + self.currentUser
        var userNamesSplit = split(self.userNamesSring) {$0 == ","}
        
        for name in userNamesSplit {
            self.userNameArray.append(name)
        }

        self.getPublicKey()
        
    }
    
    func getPublicKey(){
        for user in self.userNameArray{
            //if user is the owner of the device dont get there public key already have it
            //show activity
            var actInd : UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRectMake(0,0, self.view.frame.width, 800)) as UIActivityIndicatorView
            actInd.backgroundColor = UIColor(red:(28/255), green:(69/255) , blue:(90/255), alpha:0.5)
            actInd.center = self.view.center
            actInd.hidesWhenStopped = true
            actInd.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.WhiteLarge
            view.addSubview(actInd)
            actInd.startAnimating()
            
            //http request
            var getRequest = HTTPRequest()
            getRequest.getWithToken("http://cryptomessage.mobi/api/getdevices/\(user)/", token: self.token){
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
                            let jsonObject:NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments, error: &error) as! NSDictionary
                            self.publicKeys[user] = jsonObject
                            if self.ownerUserName == user {
                                //owner is sender get there id
                                self.senderID = self.publicKeys[user]!.valueForKey("user")! as! Int
                            }
                            //add public keys to keychain
                            let savePublicKey = RSA()
                            savePublicKey.savePublicKey(self.publicKeys[user]!.valueForKey("publicKey")! as! String, userName: user)
                        }
                        actInd.stopAnimating()
                    }//end if
                })
            }//post request
        }
    }
    
    func startConvo(){
        
        
        //show activity
        var actInd : UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRectMake(0,0, self.view.frame.width, 800)) as UIActivityIndicatorView
        actInd.backgroundColor = UIColor(red:(28/255), green:(69/255) , blue:(90/255), alpha:0.5)
        actInd.center = self.view.center
        actInd.hidesWhenStopped = true
        actInd.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.WhiteLarge
        view.addSubview(actInd)
        actInd.startAnimating()
        
        
        var messageToSend = NSMutableDictionary()
        //add user to dictionary for proccessing
        messageToSend.setValue(self.userNamesSring, forKey: "name")
        
        
        
        //serialize dict
        var serialzeJson = JsonParser()
        var jsonStringForPost = serialzeJson.SerialzeJson(messageToSend)
        
        //http request
        var postRequest = HTTPRequest()
        postRequest.postWithToken("http://cryptomessage.mobi/api/createconversation/", jsonString: jsonStringForPost!, token: self.token){
            response, data, error in
            dispatch_async(dispatch_get_main_queue(),{
                //stop animating
                actInd.stopAnimating()
                if error != nil {
                    println("Error Loading JSON Data \(error)")
                }else if let httpResponse = response as? NSHTTPURLResponse {
                    if httpResponse.statusCode == 201 {
                        var error: NSError?
                        let jsonObject:NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments, error: &error) as! NSDictionary
                        self.recipients.text = ""
                        var theID = jsonObject.valueForKey("id") as! Int
                        self.sendTheMessage(theID)
                        
                    }else{
                        println(response)
                    }
                }//end if
            })
        }//post request
    }
    
    func sendTheMessage(convoID:Int){
        for (key, value) in self.publicKeys{
            //show activity
            var actInd : UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRectMake(0,0, self.view.frame.width, 800)) as UIActivityIndicatorView
            actInd.backgroundColor = UIColor(red:(28/255), green:(69/255) , blue:(90/255), alpha:0.5)
            actInd.center = self.view.center
            actInd.hidesWhenStopped = true
            actInd.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.WhiteLarge
            view.addSubview(actInd)
            actInd.startAnimating()
            //RSA ENCRYPTION OF AES KEY
            var crypt = AES()
            var encryptedData = crypt.encryptString(self.messageToSend.text)


            var encryptData = RSA()

            var theEncryptedKey = encryptData.encryptDataForUserName(encryptedData.base64Key, userName: key)


            var messageToSend = NSMutableDictionary()
            //add user to dictionary for proccessing
            messageToSend.setValue(theEncryptedKey, forKey: "key")
            messageToSend.setValue(value.valueForKey("id")!, forKey: "device")
            messageToSend.setValue(self.senderID, forKey: "messageSender")
            messageToSend.setValue(convoID, forKey: "conversation")
            messageToSend.setValue(encryptedData.base64Text, forKey: "text")

            if key == self.ownerUserName {
                messageToSend.setValue(1, forKey: "owner")
            }else{
                messageToSend.setValue(0, forKey: "owner")
            }

            //serialize dict
            var serialzeJson = JsonParser()
            var jsonStringForPost = serialzeJson.SerialzeJson(messageToSend)

            //http request
            var postRequest = HTTPRequest()
            postRequest.postWithToken("http://cryptomessage.mobi/api/messagedetail/", jsonString: jsonStringForPost!, token: self.token){
                response, data, error in
                dispatch_async(dispatch_get_main_queue(),{
                    //stop animating
                    actInd.stopAnimating()
                    if error != nil {
                        println("Error Loading JSON Data \(error)")
                    }else if let httpResponse = response as? NSHTTPURLResponse {
                        if httpResponse.statusCode == 201 {
                            println("Message Sent")
                            self.messageToSend.text = ""
                        }else{
                            var error: NSError?
                            let jsonObject:NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments, error: &error) as! NSDictionary
                            println("Message failed to send")
                            println(jsonObject)
                        }
                    }//end if
                })
            }//post request


        }//end for
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        var userCreds = DatabaseModel()
        var theUsersCreds = userCreds.getSessionData() as NSArray
        for users in theUsersCreds{
            self.token = users.valueForKey("token") as! String
            self.currentUser = users.valueForKey("username") as! String
            self.ownerUserName = self.currentUser
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
