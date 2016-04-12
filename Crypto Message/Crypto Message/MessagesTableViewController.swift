//
//  MessagesTableViewController.swift
//  Crypto Message
//
//  Created by Michael Clark on 3/12/15.
//
//

import UIKit
import AudioToolbox

class MessagesTableViewController: UITableViewController {
    
    var sessionInformation = NSArray()
    var messages = NSArray()
    let simpleTableIdentifier = "Cell"
    var currentMessages = NSArray()
    var covoSelectedForDetail = Int()
    var token = String()
    var timer = NSTimer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var userCreds = DatabaseModel()
        var theUsersCreds = userCreds.getSessionData() as NSArray
        for users in theUsersCreds{
            self.token = users.valueForKey("token") as! String
        }
        
        getUserData()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadTableList:", name: "reloadTableView", object: nil)
        self.timer = NSTimer.scheduledTimerWithTimeInterval(15, target: self, selector: Selector("getNewMessages"), userInfo: nil, repeats: true)
        
        
    }
    
    @IBAction func logout(sender: UIBarButtonItem) {
        var modelData = DatabaseModel()
        var deleteSession = modelData.deleteSession()
        var convoDeleted = modelData.deleteAllConvos()
        if deleteSession {
            let mainView = self.storyboard?.instantiateViewControllerWithIdentifier("Login") as! ViewController
            self.navigationController?.pushViewController(mainView, animated: true)
        }
        
        self.timer.invalidate()
        
    }
    
    func getUserData(){
        var modelData = DatabaseModel()
        self.sessionInformation=[]
        self.currentMessages=[]
        self.sessionInformation = modelData.getSessionData() as NSArray
        self.currentMessages = modelData.getAllConvoData() as NSArray
        
    }
    
    func getNewMessages() {
        var getLatestMessage = DatabaseModel()
        var lastestMessageID = getLatestMessage.getLatestMessageID() as NSArray
        var latestID = 0
        if lastestMessageID.count > 0 {
            latestID = lastestMessageID[0].valueForKey("id")! as! Int
        }
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
                                var theMessage = message as NSDictionary
                                
                                var convo = message.valueForKey("conversation") as NSDictionary
                                var convoID = convo.valueForKey("id") as Int
                                var name = convo.valueForKey("name") as String
                                
                                var messageSender = message.valueForKey("messageSender") as NSDictionary
                                var senderID = messageSender.valueForKey("id") as Int
                                var senderUsername = messageSender.valueForKey("username") as String
                                
                                var date = message.valueForKey("date") as String
                                var device = message.valueForKey("device") as Int
                                var id = message.valueForKey("id") as Int
                                var owner = message.valueForKey("owner") as Int
                                var text = message.valueForKey("text") as String
                                var key = message.valueForKey("key") as String
                                
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
                            NSNotificationCenter.defaultCenter().postNotificationName("reloadTableView", object: nil)

                        }//end if
                    }
                }//end if
            })
        }//post request

    }
    
    func reloadTableList(notification:NSNotification){
        getUserData()
        self.tableView.reloadData()
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return self.currentMessages.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(self.simpleTableIdentifier) as? UITableViewCell
        
        cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: self.simpleTableIdentifier)
        
        var theConvo = self.currentMessages[indexPath.row] as! Conversation
        var idArrayForMax = [Int]()
        var maxID = 0
        var textForPreview = ""
        for singleMessage in theConvo.message{
            let myMessage = singleMessage as Message
            if myMessage.id as Int > maxID{
                maxID = myMessage.id as Int
                textForPreview = myMessage.text as String
            }
        }
        
        
        cell!.textLabel!.text = theConvo.name as String
        cell!.detailTextLabel!.text = textForPreview
        
        return cell!
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.covoSelectedForDetail = self.currentMessages[indexPath.row].valueForKey("id") as! Int
        performSegueWithIdentifier("showDetail", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
             var viewControllerToPassTo: MessageDetailViewController = segue.destinationViewController as! MessageDetailViewController
            viewControllerToPassTo.messageConvoSelected = self.covoSelectedForDetail
            
        }
    }

}
