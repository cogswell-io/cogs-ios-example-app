//
//  AppDelegate.swift
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

var DeviceTokenString: String = ""
var Environment: String = "production"

extension NSURL {
  func getKeyVals() -> Dictionary<String, String>? {
    var results = [String:String]()
    let keyValues = self.query?.componentsSeparatedByString("&")
    if keyValues?.count > 0 {
      for pair in keyValues! {
        let kv = pair.componentsSeparatedByString("=")
        if kv.count > 1 {
          results.updateValue(kv[1], forKey: kv[0])
        }
      }
      
    }
    return results
  }
}

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  
  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    // Override point for customization after application launch.
    sleep(3)
    
        /// set API_BASE_URL
    GambitSDK.GambitService.sharedGambitService.baseURL = "https://api.cogswell.io/"
    
    // Register the supported interaction types.
    let types: UIUserNotificationType = [.Badge, .Sound, .Alert]
    let mySettings = UIUserNotificationSettings(forTypes: types, categories: nil)
    
    UIApplication.sharedApplication().registerUserNotificationSettings(mySettings)
    
    // Register for remote notifications
    UIApplication.sharedApplication().registerForRemoteNotifications()
    
    
    return true
  }
  
  func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
    
    if let queryString = url.getKeyVals() {
      print(queryString)
      
      let prefs = NSUserDefaults.standardUserDefaults()
      prefs.setValue(queryString["access_key"], forKey: "accessKey")
      prefs.setValue(queryString["client_salt"], forKey: "clientSalt")
      prefs.setValue(queryString["client_secret"], forKey: "clientSecret")
      prefs.setValue(queryString["campaign_id"], forKey: "campaignID")
      prefs.setValue(queryString["event_name"], forKey: "eventName")
      prefs.setValue(queryString["namespace"], forKey: "namespaceName")
      prefs.setValue(queryString["application_id"], forKey: "applicationID")
      
      prefs.synchronize()
    }
    return true
  }
  
  func applicationWillResignActive(application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
  }
  
  func applicationDidEnterBackground(application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    application.applicationIconBadgeNumber = 0
  }
  
  func applicationWillEnterForeground(application: UIApplication) {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
  }
  
  func applicationDidBecomeActive(application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }
  
  func applicationWillTerminate(application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }
  
  
  /**
   Request Message payload per message id from Cogs service
   
   - parameter request: GambitRequestMessage
   */
  func gambitMessage(request: GambitRequestMessage) {
    let service = GambitService.sharedGambitService
    
    service.message(request) { data, response, error in
      do {
        guard let data = data else {
          // handle missing data response error
          dispatch_async(dispatch_get_main_queue()) {
            var msg = "Request Failed"
            if let er = error {
              msg += ": \(er.localizedDescription)"
            }
            print(msg)
          }
          return
        }
        
        let json: JSON = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        let msgResponse = try GambitMessageResponse(json: json)
        
        dispatch_async(dispatch_get_main_queue()) {
          let alertController = UIAlertController(title: "Message Response", message: "\(msgResponse)", preferredStyle: UIAlertControllerStyle.Alert)
          alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
          self.window?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
        }

//        let parsedData = try GambitResponseEvent(json: json)
      }
      catch let error as NSError {
        dispatch_async(dispatch_get_main_queue()) {
          print("Error: \(error)")
          
          if error.code == 1 {
            if let data = data {
              self.printErrorData(data)
            }
          }
        }
      }
    }
  }
  private func printErrorData(data: NSData) {
    do {
      let json: JSON = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
      if let jsonString = json["message"] as? String {
        let msgJSON = try NSJSONSerialization.JSONObjectWithData(jsonString.dataUsingEncoding(NSUTF8StringEncoding)!, options: .AllowFragments)
        dispatch_async(dispatch_get_main_queue()) {
          let alertController = UIAlertController(title: "Message Response", message: "\(msgJSON)", preferredStyle: UIAlertControllerStyle.Alert)
          alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
          self.window?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
        }
      }
    } catch {
      
    }
  }
  
  // MARK: Notifications
  
  func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
    let deviceTokenString =
      deviceToken.description.stringByReplacingOccurrencesOfString("<", withString: "")
      .stringByReplacingOccurrencesOfString(">", withString: "")
        .stringByReplacingOccurrencesOfString(" ", withString: "")
    
    
    #if DEBUG
      Environment = "dev"
    #else
      Environment = "production"
    #endif
    
    DeviceTokenString = deviceTokenString
    print("Environment: \(Environment)")
    
    print("My Token is: \(deviceTokenString)")
  }
  
  func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
    print("Fail to get token: \(error.localizedDescription)")
  }
  
  func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
    
    dispatch_async(dispatch_get_main_queue()) {
      let alertController = UIAlertController(title: "Push Payload", message: "\(userInfo)", preferredStyle: UIAlertControllerStyle.Alert)
      var msgRequest: GambitRequestMessage?
      
      if let msgID = userInfo["aviata_gambit_message_id"] as? String {
        let prefs = NSUserDefaults.standardUserDefaults()
        if let accessKey = prefs.stringForKey("accessKey"),
          clientSalt = prefs.stringForKey("clientSalt"),
          clientSecret = prefs.stringForKey("clientSecret"),
          namespaceName = prefs.stringForKey("namespaceName"),
          attributesList = prefs.stringForKey("attributesList")
        {
          do {
            let jsonAtts = try NSJSONSerialization
              .JSONObjectWithData(attributesList.dataUsingEncoding(NSUTF8StringEncoding)!, options: .AllowFragments)
            
            msgRequest = GambitRequestMessage(accessKey: accessKey, clientSalt: clientSalt, clientSecret: clientSecret, token: msgID, namespace: namespaceName, attributes: jsonAtts as! [String: AnyObject])
          }
          catch {
            print("Attributes Error! Invalid Attributes JSON.")
          }

        }
      } else {
        print("missing message ID")
      }
      let action = UIAlertAction(title: "View Message", style: UIAlertActionStyle.Cancel) { _ in
        if msgRequest != nil {
          self.gambitMessage(msgRequest!)
        }
      }
      alertController.addAction(action)
      
      self.window?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
    }
  }
  
}

