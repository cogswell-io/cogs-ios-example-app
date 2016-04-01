//
//  NotificationsVC.swift
//  GambitDemo
//

/**
 * Copyright (C) 2016 Aviata Inc. All Rights Reserved.
 * This code is licensed under the Apache License 2.0
 *
 * This license can be found in the LICENSE.txt at or near the root of the
 * project or repository. It can also be found here:
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * You should have received a copy of the Apache License 2.0 license with this
 * code or source file. If not, please contact support@cogswell.io
 */

import UIKit
import GambitSDK

class NotificationsVC: ViewController {
  
  // MARK: Outlets
  @IBOutlet weak var accessKeyField: UITextField!
  @IBOutlet weak var clientSaltField: UITextField!
  @IBOutlet weak var clientSecretField: UITextField!
  @IBOutlet weak var applicationIDField: UITextField!
  @IBOutlet weak var namespaceField: UITextField!
  @IBOutlet weak var attributesTextView: UITextView!
  @IBOutlet weak var deviceToken: UITextField!
  @IBOutlet weak var registerButton: UIButton!
  @IBOutlet weak var unregisterButton: UIButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.readInputFieldsData()
    deviceToken.text = DeviceTokenString
  }
  
  /**
   Send Register Push Request to Cogs Service
   
   - parameter request: GambitRequestPush
   */
  
  private func registerPush(request: GambitRequestPush) {
    let service = GambitService.sharedGambitService
    
    //unregister previous topic if existing
    let prefs = NSUserDefaults.standardUserDefaults()
    if let registeredPush = prefs.valueForKey("registeredPush") as? [String: AnyObject] {
      let req = GambitRequestPush(
        clientSalt: registeredPush["clientSalt"] as! String,
        clientSecret: registeredPush["clientSecret"] as! String,
        UDID: registeredPush["UDID"] as! String,
        accessKey: registeredPush["accessKey"] as! String,
        attributes: registeredPush["attributes"] as! [String: AnyObject],
        environment: registeredPush["env"] as! String,
        platformAppID: registeredPush["appID"] as! String,
        namespace: registeredPush["namespace"] as! String
      )
      prefs.removeObjectForKey("registeredPush")
      prefs.synchronize()
      
      service.unregisterPush(req, completionHandler: self.completionHandler)
    }
    
    let dict = [
      "clientSalt" : request.clientSalt,
      "clientSecret" : request.clientSecret,
      "UDID" : request.UDID,
      "accessKey" : request.accessKey,
      "attributes" : request.attributes,
      "env" : request.environment,
      "appID" : request.platformAppID,
      "namespace" : request.namespace
    ]
    prefs.setValue(dict, forKey: "registeredPush")
    
    service.registerPush(request, completionHandler: self.completionHandler)
  }
  
  /**
   Send Unregister Push Request to Cogs Service
   
   - parameter request: GambitRequestPush
   */
  
  private func unregisterPush(request: GambitRequestPush) {
    let service = GambitService.sharedGambitService
    
    service.unregisterPush(request, completionHandler: self.completionHandler)
  }
  
  
  private func completionHandler(data: NSData?, response: NSURLResponse?, error: NSError?) {
    do {
      guard let data = data else {
        dispatch_async(dispatch_get_main_queue()) {
          var msg = "Request Failed"
          if let er = error {
            msg += ": \(er.localizedDescription)"
          }
          self.openAlertWithMessage(message: msg, title: "Error")
        }
        return
      }
      
      let json: JSON = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
      print(json)
      let pushResponse = try GambitResponsePush(json: json)
      
      dispatch_async(dispatch_get_main_queue()) {
        self.successfulRequestResponse(pushResponse.message)
      }
      
    } catch {
      dispatch_async(dispatch_get_main_queue()) {
        self.openAlertWithMessage(message: "\(error)", title: "Error")
      }
    }
    
    dispatch_async(dispatch_get_main_queue()) {
      self.view.userInteractionEnabled = true
    }
  }
  
  private func successfulRequestResponse(msg: String) {
    openAlertWithMessage(message: msg, title: "API Response")
  }
  
  private func openAlertWithMessage(message msg: String, title: String) {
    let actionCtrl = UIAlertController(title: title, message: msg, preferredStyle: .Alert)
    let action = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
    actionCtrl.addAction(action)
    
    self.presentViewController(actionCtrl, animated: true, completion: nil)
  }
  
  @IBAction func sendRequest(sender: UIButton) {
    guard let accessKey = accessKeyField.text where !accessKey.isEmpty else {
      openAlertWithMessage(message: "Please fill in all required fields", title: "Error")
      return
    }
    guard let clientSalt = clientSaltField.text where !clientSalt.isEmpty else {
      openAlertWithMessage(message: "Please fill in all required fields", title: "Error")
      return
    }
    guard let clientSecret = clientSecretField.text where !clientSecret.isEmpty else {
      openAlertWithMessage(message: "Please fill in all required fields", title: "Error")
      return
    }
    guard let applicationID = applicationIDField.text where !applicationID.isEmpty else {
      openAlertWithMessage(message: "Please fill in all required fields", title: "Error")
      return
    }
    guard let namespace = namespaceField.text where !namespace.isEmpty else {
      openAlertWithMessage(message: "Please fill in all required fields", title: "Error")
      return
    }
    guard let token = deviceToken.text where !token.isEmpty else {
      openAlertWithMessage(message: "Please fill in all required fields", title: "Error")
      return
    }
    
    self.writeInputFieldsData()
    
    do {
      let jsonAtts = try NSJSONSerialization
        .JSONObjectWithData(attributesTextView.text.dataUsingEncoding(NSUTF8StringEncoding)!, options: .AllowFragments)
      guard let attributes = jsonAtts as? [String: AnyObject] else { return }

      
      let request = GambitRequestPush(
        clientSalt: clientSalt,
        clientSecret: clientSecret,
        UDID: token,
        accessKey: accessKey,
        attributes: attributes,
        environment: Environment,
        platformAppID: applicationID,
        namespace: namespace
      )
      
      view.userInteractionEnabled = false
      if sender.isEqual(self.registerButton) {
        self.registerPush(request)
      } else {
        self.unregisterPush(request)
      }
    }
    catch {
      openAlertWithMessage(message: "Invalid Attributes JSON", title: "Error")
    }
  }
  
  // MARK: Utilities
  private func writeInputFieldsData(){
    let prefs = NSUserDefaults.standardUserDefaults()
    prefs.setValue(self.accessKeyField.text, forKey: "accessKey")
    prefs.setValue(self.clientSaltField.text, forKey: "clientSalt")
    prefs.setValue(self.clientSecretField.text, forKey: "clientSecret")
    prefs.setValue(self.namespaceField.text, forKey: "namespaceName")
    prefs.setValue(self.attributesTextView.text, forKey: "attributesList")
    prefs.setValue(self.applicationIDField.text, forKey: "applicationID")
    
    prefs.synchronize()
  }
  
  private func readInputFieldsData(){
    let prefs = NSUserDefaults.standardUserDefaults()
    if let accessKey = prefs.stringForKey("accessKey") {
      self.accessKeyField.text = accessKey
    }
    if let clientSalt = prefs.stringForKey("clientSalt") {
      self.clientSaltField.text = clientSalt
    }
    if let clientSecret = prefs.stringForKey("clientSecret") {
      self.clientSecretField.text = clientSecret
    }
    if let applicationID = prefs.stringForKey("applicationID") {
      self.applicationIDField.text = applicationID
    }
    if let namespaceName = prefs.stringForKey("namespaceName") {
      self.namespaceField.text = namespaceName
    }
    if let attributesList = prefs.stringForKey("attributesList") {
      self.attributesTextView.text = attributesList
    }
  }

  
  
}
