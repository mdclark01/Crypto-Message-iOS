//
//  MessageDetailViewController.swift
//  Crypto Message
//
//  Created by Michael Clark on 3/26/15.
//
//

import UIKit
import AudioToolbox

class CustomTableViewCell : UITableViewCell {
    @IBOutlet weak var senderLeft: UILabel!
    @IBOutlet weak var messageLeft: UILabel!
    @IBOutlet weak var dateLeft: UILabel!

}


class MessageDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var toField: UITextField!
    @IBOutlet weak var messageForSending: UITextField!
    
    var messageConvoSelected = Int()
    var allConvoMessages = [Int:Message]()
    var sortedConvoMessages = [Message]()
    var token = String()
    var userNames = String()
    var userNameArray = [String]()
    var publicKeys = [String:NSDictionary]()
    var ownerUserName = String()
    var senderID = Int()
    var kbHeight: CGFloat!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadMessages()
        self.title = self.userNames
        self.messageForSending.delegate = self
        //get token
        var userCreds = DatabaseModel()
        var theUsersCreds = userCreds.getSessionData() as NSArray
        for users in theUsersCreds{
            self.token = users.valueForKey("token") as! String
            self.ownerUserName = users.valueForKey("username") as! String
            self.ownerUserName = self.ownerUserName.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        }
        //get the public keys for users in convos
        self.getPublicKey()
        
        var nib = UINib(nibName: "messageTblCell", bundle: nil)
        
        tableView.registerNib(nib, forCellReuseIdentifier: "customCell")
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadDetailTableList:", name: "reloadTableView", object: nil)
        
    }
    
    @IBAction func sendMessage(sender: UIButton) {
        
        for (key, value) in publicKeys{
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
            var encryptedData = crypt.encryptString(self.messageForSending.text)

            
            var encryptData = RSA()
            
            var theEncryptedKey = encryptData.encryptDataForUserName(encryptedData.base64Key, userName: key)

            
            var messageToSend = NSMutableDictionary()
            //add user to dictionary for proccessing
            messageToSend.setValue(theEncryptedKey, forKey: "key")
            messageToSend.setValue(value.valueForKey("id")!, forKey: "device")
            messageToSend.setValue(self.senderID, forKey: "messageSender")
            messageToSend.setValue(self.messageConvoSelected, forKey: "conversation")
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
                            self.messageForSending.text = ""
                            self.getNewData()
                        }else{
                            self.alert("Error", message: "Could Not Send Message")
                            println(data)
                        }
                    }//end if
                })
            }//post request

            
        }//end for
    }
    
    func loadMessages(){
        self.sortedConvoMessages.removeAll(keepCapacity: false)
        self.allConvoMessages.removeAll(keepCapacity: false)
        var getAllConvoMessages = DatabaseModel()
        let convo = getAllConvoMessages.getConvoDataByID(self.messageConvoSelected) as NSArray

        for singleConvo in convo{
            let theSingleConvo = singleConvo as! Conversation
            for singleMessage in theSingleConvo.message{
                let theSingleMessage = singleMessage as! Message
                let theMessageID = theSingleMessage.id as Int
                self.allConvoMessages[theMessageID] = theSingleMessage
            }
            
            
            let userNameToAdd = theSingleConvo.name as String
            self.userNames = userNameToAdd
            }
        
        var userNamesSplit = split(self.userNames) {$0 == ","}
        
        for name in userNamesSplit {
            self.userNameArray.append(name)
        }
        
        for (k,v) in Array(self.allConvoMessages).sorted({$0.0 < $1.0}) {
            self.sortedConvoMessages.append(v)
        }

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
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return self.sortedConvoMessages.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:CustomTableViewCell = self.tableView.dequeueReusableCellWithIdentifier("customCell") as! CustomTableViewCell
        
        var theMessage = self.sortedConvoMessages[indexPath.row]
        var theMessageSender = theMessage.sender as MessageSender
        
        if theMessage.owner == 1 {
            cell.messageLeft.text = theMessage.text
            cell.senderLeft.text = theMessageSender.username
            cell.dateLeft.text = theMessage.date
            cell.messageLeft.textAlignment = NSTextAlignment.Right
            cell.senderLeft.textAlignment = NSTextAlignment.Right
            cell.dateLeft.textAlignment = NSTextAlignment.Right
        }else{
            cell.messageLeft.text = theMessage.text
            cell.senderLeft.text = theMessageSender.username
            cell.dateLeft.text = theMessage.date
            cell.messageLeft.textAlignment = NSTextAlignment.Left
            cell.senderLeft.textAlignment = NSTextAlignment.Left
            cell.dateLeft.textAlignment = NSTextAlignment.Left
        }
        
        return cell
    }

    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        textField.resignFirstResponder()
        return true;
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let keyboardSize =  (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
                kbHeight = keyboardSize.height
                self.animateTextField(true)
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        self.animateTextField(false)
    }
    
    func animateTextField(up: Bool) {
        var movement = (up ? -kbHeight : kbHeight)
        
        UIView.animateWithDuration(0.3, animations: {
            self.view.frame = CGRectOffset(self.view.frame, 0, movement)
        })
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillAppear(animated:Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
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
    
    func reloadDetailTableList(notification:NSNotification){
        loadMessages()
        self.tableView.reloadData()
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        let numberOfSections = tableView.numberOfSections()
        let numberOfRows = tableView.numberOfRowsInSection(numberOfSections-1)
        
        if numberOfRows > 0 {
            println(numberOfSections)
            let indexPath = NSIndexPath(forRow: numberOfRows-1, inSection: (numberOfSections-1))
            self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
        }
    }
    
    func getNewData(){
        var getLatestMessage = DatabaseModel()
        var lastestMessageID = getLatestMessage.getLatestMessageID() as NSArray
        var latestID = lastestMessageID[0].valueForKey("id")! as! Int
        
        //http request
        var postRequest = HTTPRequest()
        postRequest.getWithToken("http://cryptomessage.mobi/api/messages/\(latestID)/", token: self.token){
            response, data, error in
            dispatch_async(dispatch_get_main_queue(),{
                //stop animating
                if error != nil {
                    println("Error Loading JSON Data \(error)")
                }else if let httpResponse = response as? NSHTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        
                        //get data
                        var error: NSError?
                        let jsonObject = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments, error: &error)
                        let deserializedDictionary = jsonObject as! NSArray
                        if deserializedDictionary.count == 0 {
                            //no new message data
                        }else if deserializedDictionary.count > 0 {
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
                            }//end for
                            
                            self.loadMessages()
                            
                            self.tableView.reloadData()
                            
                            let numberOfSections = self.tableView.numberOfSections()
                            let numberOfRows = self.tableView.numberOfRowsInSection(numberOfSections-1)
                            
                            if numberOfRows > 0 {
                                println(numberOfSections)
                                let indexPath = NSIndexPath(forRow: numberOfRows-1, inSection: (numberOfSections-1))
                                self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
                            }
                            
                        }//end if
                    }
                }//end if
            })
        }//post request
    }
}
