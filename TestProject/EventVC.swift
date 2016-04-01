//
//  EventVC.swift
//  Cogs
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

class EventVC: ViewController {
  @IBOutlet weak var accessKeyTextField: UITextField!
  @IBOutlet weak var clientSaltTextField: UITextField!
  @IBOutlet weak var clientSecretTextField: UITextField!
  @IBOutlet weak var campaignIDTextField: UITextField!
  @IBOutlet weak var eventNameTextField: UITextField!
  @IBOutlet weak var namespaceTextField: UITextField!
  @IBOutlet weak var attributesTextView: UITextView!
  @IBOutlet weak var label: UILabel!
  var directive: String?
    
  @IBAction func executeTapped(sender: UIBarButtonItem) {
    
    self.writeInputFieldsData()
    
    do {
      let jsonAtts = try NSJSONSerialization
        .JSONObjectWithData(attributesTextView.text.dataUsingEncoding(NSUTF8StringEncoding)!, options: .AllowFragments)
      
      self.makeRequest(jsonAtts)
    }
    catch {
      openAlertWithMessage(message: "Invalid Attributes JSON.", title: "Attributes Error!")
    }
  }
  
  @IBAction func debugDirectiveSwitched(sender: UISwitch) {
    if sender.on {
      self.directive = "echo-as-message"
    } else {
      self.directive = nil
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.readInputFieldsData()
  }
  
  /**
   Send Event to Cogs Service
   
   - parameter atts: JSON attributes
   */
  
  private func makeRequest(atts: AnyObject) {
    
    guard let accessKey = accessKeyTextField.text else {
      openAlertWithMessage(message: "Please fill in all required fields", title: "Error")
      return
    }
    guard let clientSalt = clientSaltTextField.text else {
      openAlertWithMessage(message: "Please fill in all required fields", title: "Error")
      return
    }
    guard let clientSecret = clientSecretTextField.text else {
      openAlertWithMessage(message: "Please fill in all required fields", title: "Error")
      return
    }
    guard let eventName = eventNameTextField.text else {
      openAlertWithMessage(message: "Please fill in all required fields", title: "Error")
      return
    }
    guard let namespace = namespaceTextField.text else {
      openAlertWithMessage(message: "Please fill in all required fields", title: "Error")
      return
    }
    guard let attributes = atts as? [String: AnyObject] else {
      openAlertWithMessage(message: "Please fill in all required fields", title: "Error")
      return
    }
    
    let request = GambitRequestEvent(
      debugDirective: directive,
      accessKey: accessKey,
      clientSalt: clientSalt,
      clientSecret: clientSecret,
      campaignID: Int(campaignIDTextField.text ?? ""),
      eventName: eventName,
      namespace: namespace,
      attributes: attributes)
    let service = GambitService.sharedGambitService
    
    view.userInteractionEnabled = false
    service.requestEvent(request) { (data, response, error) -> Void in
      do {
        guard let data = data else {
          // handle missing data response error
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
        print("JSON: \(json)")
        let parsedData = try GambitResponseEvent(json: json)
        
        dispatch_async(dispatch_get_main_queue()) {
          self.label.text = "message: \(parsedData.message)"
          self.view.userInteractionEnabled = true
        }
      } catch {
        // handle catched errors
        dispatch_async(dispatch_get_main_queue()) {
          self.openAlertWithMessage(message: "\(error)", title: "Error")
          self.view.userInteractionEnabled = true
        }
      }
    }
  }
  
  // MARK: Utilities
  private func openAlertWithMessage(message msg: String, title: String) {
    let actionCtrl = UIAlertController(title: title, message: msg, preferredStyle: .Alert)
    let action = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
    actionCtrl.addAction(action)
    
    self.presentViewController(actionCtrl, animated: true, completion: nil)
  }
  
  private func writeInputFieldsData(){
    let prefs = NSUserDefaults.standardUserDefaults()
    prefs.setValue(self.accessKeyTextField.text, forKey: "accessKey")
    prefs.setValue(self.clientSaltTextField.text, forKey: "clientSalt")
    prefs.setValue(self.clientSecretTextField.text, forKey: "clientSecret")
    prefs.setValue(self.campaignIDTextField.text, forKey: "campaignID")
    prefs.setValue(self.eventNameTextField.text, forKey: "eventName")
    prefs.setValue(self.namespaceTextField.text, forKey: "namespaceName")
    prefs.setValue(self.attributesTextView.text, forKey: "attributesList")
    
    prefs.synchronize()
  }
  
  private func readInputFieldsData(){
    let prefs = NSUserDefaults.standardUserDefaults()
    if let accessKey = prefs.stringForKey("accessKey") {
      self.accessKeyTextField.text = accessKey
    }
    if let clientSalt = prefs.stringForKey("clientSalt") {
      self.clientSaltTextField.text = clientSalt
    }
    if let clientSecret = prefs.stringForKey("clientSecret") {
      self.clientSecretTextField.text = clientSecret
    }
    if let campaignID = prefs.stringForKey("campaignID") {
      self.campaignIDTextField.text = campaignID
    }
    if let eventName = prefs.stringForKey("eventName") {
      self.eventNameTextField.text = eventName
    }
    if let namespaceName = prefs.stringForKey("namespaceName") {
      self.namespaceTextField.text = namespaceName
    }
    if let attributesList = prefs.stringForKey("attributesList") {
      self.attributesTextView.text = attributesList
    }
  }
}
