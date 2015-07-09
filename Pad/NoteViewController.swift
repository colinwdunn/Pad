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
    func removeNote(note: CKRecord)
}

class NoteViewController: UIViewController, UIGestureRecognizerDelegate {
    let composer = Composer()
    var panGesture: UIPanGestureRecognizer!
    var note: CKRecord! {
        didSet {
            if let text = note.objectForKey("Text") as? String {
                composer.text = text
            } else {
                composer.text = nil
            }
        }
    }
    var delegate: NoteDelegate?
    let padding:CGFloat = 16

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor() 
        
        composer.alwaysBounceVertical = true
        composer.textContainerInset = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        composer.font = atlas
        composer.keyboardDismissMode = .Interactive
        view.addSubview(composer)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
        let newString = composer.text
        if let oldString = note.objectForKey("Text") as? String {
            if newString.isEmpty {
                delegate?.removeNote(note)
                print("Remove note")
            } else if newString != oldString {
                note!.setObject(composer.text, forKey: "Text")
                delegate?.modifyNote(note!)
                print("Modify note")
            }
        }
//        else {
//            if !newString.isEmpty {
//                note.setObject(newString, forKey: "Text")
//                println("Add note")
//                //delegate?.addNote(note)
//            }
//        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        composer.frame = view.bounds
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue() {
            composer.contentInset.bottom = keyboardSize.height
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        composer.contentInset.bottom = 0
    }
}