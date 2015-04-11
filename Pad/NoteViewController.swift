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
}

class NoteViewController: UIViewController, UITextFieldDelegate {
    
    let done = UIButton()
    let textField = UITextField()
    var note: CKRecord? {
        didSet {
            textField.text = note!.objectForKey("Text") as! String
        }
    }
    var delegate: NoteDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.whiteColor()
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
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        done.frame = CGRectMake(view.bounds.width - 100, 10, 100, 25)
        textField.frame = CGRectMake(20, 40, view.bounds.width - 40, 25)
    }
    
    func handleDoneTap() {
        if note != nil {
            note!.setObject(textField.text, forKey: "Text")
            delegate?.modifyNote(note!)
        } else {
            let note = CKRecord(recordType: Note.recordType)
            note!.setObject(textField.text, forKey: "Text")
            delegate?.addNote(note)
        }
        textField.resignFirstResponder()
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}