//
//  ViewController.swift
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

protocol ScrollView {
  var scrollView: UIScrollView! { get set }
  var heightConstraint: NSLayoutConstraint! { get set }
}

class ViewController: UIViewController, ScrollView {
  // MARK: Outlets
  @IBOutlet weak var scrollView: UIScrollView! {
    didSet { _scrollView = scrollView }
  }
  @IBOutlet weak var heightConstraint: NSLayoutConstraint! {
    didSet { _heightConstraint = heightConstraint }
  }
  
  private let notificationCenter = NSNotificationCenter.defaultCenter()
  var _scrollView: UIScrollView!
  var _heightConstraint: NSLayoutConstraint!
  private var _keyboardIsPresented: Bool = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
  }
  @IBAction func done(segue:UIStoryboardSegue) {
  }
  
}

// MARK: Lifecycle
extension ViewController {
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    notificationCenter.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    notificationCenter.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
  }
  override func viewDidDisappear(animated: Bool) {
    super.viewDidDisappear(animated)
    
    notificationCenter.removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    notificationCenter.removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
    
  }
}
// MARK: Keyboard Notification Handling
extension ViewController {
  func keyboardWillShow(notification: NSNotification) {
    guard let scrollView = _scrollView else { return }
    guard let heightConstraint = _heightConstraint else { return }
    
    let userInfo = notification.userInfo!
    let keyboardEndRect = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
    let duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
    
    if _keyboardIsPresented == false {
      heightConstraint.constant -= keyboardEndRect.height
      scrollView.contentInset.bottom = keyboardEndRect.height
      
      UIView.animateWithDuration(duration, animations: { () -> Void in
        self.view.layoutIfNeeded()
      })
    }
    
    _keyboardIsPresented = true
  }
  
  func keyboardWillHide(notification: NSNotification) {
    guard let scrollView = _scrollView else { return }
    guard let heightConstraint = _heightConstraint else { return }
    
    let userInfo = notification.userInfo!
    let duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
    
    heightConstraint.constant = 0
    scrollView.contentInset.bottom = 0
    
    UIView.animateWithDuration(duration) { () -> Void in
      self.view.layoutIfNeeded()
    }
    
    _keyboardIsPresented = false
  }
}

