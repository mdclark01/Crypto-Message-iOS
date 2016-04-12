//
//  RegisterViewController.swift
//  Crypto Message
//
//  Created by Michael Clark on 3/12/15.
//
//

import UIKit

class RegisterViewController: UIViewController {

    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var passwordCheck: UITextField!
    
    var newUserDict = NSMutableDictionary()
    
    @IBAction func createAccount(sender: UIButton) {
        
        if self.password.text == self.passwordCheck.text && self.username.text != "" && self.password.text != "" {
            
            //add user to dictionary for proccessing
            self.newUserDict.setValue(self.username.text, forKey: "username")
            self.newUserDict.setValue(self.password.text, forKey: "password")
            
            //serialize dict
            var serialzeJson = JsonParser()
            var jsonStringForPost = serialzeJson.SerialzeJson(self.newUserDict)
            
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
            postRequest.post("http://cryptomessage.mobi/api/createuser/", jsonString: jsonStringForPost!){
                response, data, error in
                dispatch_async(dispatch_get_main_queue(),{
                    //stop animating
                    actInd.stopAnimating()
                    if error != nil {
                        println("Error Loading JSON Data \(error)")
                    }else if let httpResponse = response as? NSHTTPURLResponse {
                        
                        var parseTheJson = JsonParser()
                        print(parseTheJson.ParseJson(data)!)
                        
                        if httpResponse.statusCode == 201{
                            self.alert("Success", message: "Account Created")
                            //clear fields
                            self.username.text = ""
                            self.password.text = ""
                            self.passwordCheck.text = ""
                        }else{
                            self.alert("Error", message: "Please Try A Different Username")
                        }
                    }//end if
                })
            }//post request
        }else{
            alert("Password", message: "Passwords Dont Match")
        }
        
    }
    
    @IBAction func backgroundTap(sender: UIControl){
        self.username.resignFirstResponder()
        self.password.resignFirstResponder()
        self.passwordCheck.resignFirstResponder()
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
}//end class
