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
    
    let done = UIButton()
    let textView = UITextView()
    var indexPath: NSIndexPath!
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
        view.backgroundColor = UIColor.whiteColor()
        
        textView.contentInset = UIEdgeInsets(top: 8, left: 16, bottom: 16, right: 8)
        textView.frame = window
        textView.keyboardAppearance = .Dark
        textView.font = UIFont.systemFontOfSize(18)
        view.addSubview(textView)
        
        done.frame = CGRectMake(view.bounds.width - 100, view.bounds.height - 40, 100, 30)
        done.setTitle("Done", forState: .Normal)
        done.setTitleColor(UIColor.blueColor(), forState: .Normal)
        done.addTarget(self, action: "handleDoneTap", forControlEvents: .TouchUpInside)
        view.addSubview(done)
    }
    
    override func viewWillAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        textView.becomeFirstResponder()
    }
    
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
                println("Save new note")
                note.setObject(newString, forKey: "Text")
                delegate?.addNote(note)
            }
        }
        textView.resignFirstResponder()
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
            println("textView frame before: \(textView.frame)")
            done.frame.origin.y = window.height - keyboardSize.height - 40
            textView.frame.size.height = window.height - keyboardSize.height
            println("Keyboard Size: \(keyboardSize)")
            println("textView frame after: \(textView.frame)")
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        done.frame.origin.y = window.height - 40
        textView.frame = window
    }
}