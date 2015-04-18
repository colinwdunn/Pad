//
//  NoteViewController.swift
//  Pad
//
//  Created by Colin Dunn on 4/10/15.
//  Copyright (c) 2015 Colin Dunn. All rights reserved.
//

import UIKit
import CloudKit

protocol NoteDelegate {
    func modifyNote(note: CKRecord)
    func addNote(note: CKRecord)
    func removeNote(note: CKRecord)
}

class NoteViewController: UIViewController {
    var toolbar: UIView!
    let done = UIButton()
    let textView = UITextView()
    var note: CKRecord! {
        didSet {
            if let text = note.objectForKey("Text") as? String {
                textView.text = text
            } else {
                textView.text = nil
            }
        }
    }
    var delegate: NoteDelegate?
    let window = UIScreen.mainScreen().bounds

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.blackColor()
        
        let toolbarHeight:CGFloat = 50
        let padding:CGFloat = 16
        
        textView.backgroundColor = UIColor.whiteColor()
        textView.alwaysBounceVertical = true
        textView.textContainerInset = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        textView.frame = window
        textView.frame.size.height -= toolbarHeight
        textView.keyboardAppearance = .Dark
        textView.font = UIFont.systemFontOfSize(18)
        view.addSubview(textView)
        
        toolbar = UIView(frame: CGRectMake(0, window.height - toolbarHeight, window.width, toolbarHeight))
        toolbar.backgroundColor = UIColor.whiteColor()
        view.addSubview(toolbar)
        
        let divider = UIView(frame: CGRectMake(padding, -1, toolbar.frame.width - padding * 2, 1))
        divider.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25)
        toolbar.addSubview(divider)
        
        done.frame = CGRectMake(toolbar.frame.width - 100, 0, 100, toolbarHeight)
        done.setTitle("Done", forState: .Normal)
        done.setTitleColor(UIColor.blueColor(), forState: .Normal)
        done.addTarget(self, action: "handleDoneTap", forControlEvents: .TouchUpInside)
        toolbar.addSubview(done)
    }
    
    override func viewWillAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
//    override func viewDidAppear(animated: Bool) {
//        textView.becomeFirstResponder()
//    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func handleDoneTap() {
        let newString = textView.text
        if let oldString = note.objectForKey("Text") as? String {
            if newString.isEmpty {
                delegate?.removeNote(note)
            } else if newString != oldString {
                note!.setObject(textView.text, forKey: "Text")
                delegate?.modifyNote(note!)
            }
        } else {
            if !newString.isEmpty {
                note.setObject(newString, forKey: "Text")
                delegate?.addNote(note)
            }
        }
        textView.resignFirstResponder()
        navigationController?.popToRootViewControllerAnimated(true)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
            println("textView frame before: \(textView.frame)")
            let textViewHeight = window.height - keyboardSize.height - toolbar.frame.height
            toolbar.frame.origin.y = textViewHeight
            textView.frame.size.height = textViewHeight
            println("Keyboard Size: \(keyboardSize)")
            println("textView frame after: \(textView.frame)")
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        toolbar.frame.origin.y = window.height - toolbar.frame.height
        textView.frame = window
    }
}