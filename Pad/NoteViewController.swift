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

class NoteViewController: UIViewController, UIGestureRecognizerDelegate {
    var toolbar = UIView()
    var divider = UIView()
    var done = UIButton()
    let composer = Composer()
    var edgeSwipe: UIScreenEdgePanGestureRecognizer!
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
    let toolbarHeight:CGFloat = 50
    let padding:CGFloat = 16

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
        
        edgeSwipe = UIScreenEdgePanGestureRecognizer(target: self, action: "handleEdgeSwipe")
        edgeSwipe.edges = UIRectEdge.Left
        edgeSwipe.delegate = self
        view.addGestureRecognizer(edgeSwipe)
        
        composer.alwaysBounceVertical = true
        composer.textContainerInset = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        composer.font = national
        view.addSubview(composer)
        
        toolbar.frame = CGRectMake(0, UIScreen.mainScreen().bounds.height, UIScreen.mainScreen().bounds.width, toolbarHeight)
        toolbar.backgroundColor = UIColor.whiteColor()
        view.addSubview(toolbar)
        
        divider.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25)
        toolbar.addSubview(divider)
        
        done.setTitle("Done", forState: .Normal)
        done.setTitleColor(UIColor.blueColor(), forState: .Normal)
        done.addTarget(self, action: "handleDoneTap", forControlEvents: .TouchUpInside)
        done.titleLabel?.font = national
        toolbar.addSubview(done)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        composer.frame = view.bounds
        toolbar.frame = CGRectMake(0, view.bounds.height + 1, view.bounds.width, toolbarHeight)
        done.frame = CGRectMake(toolbar.frame.width - 100, 0, 100, toolbarHeight)
        divider.frame = CGRectMake(padding, -1, toolbar.frame.width - padding * 2, 1)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func handleDoneTap() {
        composer.resignFirstResponder()
    }
    
    func handleEdgeSwipe() {
        let newString = composer.text
        if let oldString = note.objectForKey("Text") as? String {
            if newString.isEmpty {
                delegate?.removeNote(note)
            } else if newString != oldString {
                note!.setObject(composer.text, forKey: "Text")
                delegate?.modifyNote(note!)
            }
        } else {
            if !newString.isEmpty {
                note.setObject(newString, forKey: "Text")
                delegate?.addNote(note)
            }
        }
        composer.resignFirstResponder()
        navigationController?.popToRootViewControllerAnimated(true)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        println("Keyboard will show")
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue() {
            toolbar.frame.origin.y = view.frame.height - keyboardSize.height - toolbarHeight
            composer.contentInset.bottom = keyboardSize.height + toolbarHeight
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        println("Keyboard will hide")
        toolbar.frame.origin.y = view.frame.height + 1
        composer.contentInset.bottom = 0
    }
}