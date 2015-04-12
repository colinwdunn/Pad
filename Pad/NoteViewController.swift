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

class NoteViewController: UIViewController, UITextFieldDelegate {
    
    let done = UIButton()
    let textField = UITextField()
    var note: CKRecord! {
        didSet {
            if let text = note.objectForKey("Text") as? String {
                textField.text = text
            } else {
                textField.text = nil
            }
        }
    }
    var isNewNote = false
    var delegate: NoteDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.whiteColor()
        done.frame = CGRectMake(view.bounds.width - 100, view.bounds.height - 40, 100, 30)
        done.setTitle("Done", forState: .Normal)
        done.setTitleColor(UIColor.blueColor(), forState: .Normal)
        done.addTarget(self, action: "handleDoneTap", forControlEvents: .TouchUpInside)
        view.addSubview(done)
        
        textField.placeholder = "Write something…"
        textField.keyboardAppearance = .Dark
        view.addSubview(textField)
    }
    
    override func viewWillAppear(animated: Bool) {
        textField.becomeFirstResponder()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        textField.frame = CGRectMake(16, 16, view.bounds.width - 32, 32)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func handleDoneTap() {
        let newString = textField.text
        if let oldString = note.objectForKey("Text") as? String {
            if newString.isEmpty {
                delegate?.removeNote(note)
            } else if newString != oldString {
                note!.setObject(textField.text, forKey: "Text")
                delegate?.modifyNote(note!)
            }
        } else {
            if !newString.isEmpty {
                println("Save new note")
                note.setObject(newString, forKey: "Text")
                delegate?.addNote(note)
            }
        }
        textField.resignFirstResponder()
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
            done.frame.origin.y = view.bounds.height - keyboardSize.height - 40
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        done.frame.origin.y = view.bounds.height - 40
    }
}