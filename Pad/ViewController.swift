//
//  ViewController.swift
//  Pad
//
//  Created by Colin Dunn on 4/10/15.
//  Copyright (c) 2015 Colin Dunn. All rights reserved.
//

import UIKit
import CloudKit

class ViewController: UIViewController, NSCoding, NoteDelegate, ComposerDelegate, TableViewDelegate {
    let db = CKContainer.defaultContainer().privateCloudDatabase
    let defaults = NSUserDefaults.standardUserDefaults()

    var allNotes: [CKRecord]! {
        didSet {
            if oldValue != nil {
                if oldValue != allNotes {
                    println("Saved notes to disk")
                    archiveNotes(allNotes)
                }
            }
        }
    }
    var searchResults: [CKRecord]!
    
    let noteViewController = NoteViewController()
    let kNotesKey = "Notes"
    
    let composer = UIView()
    let composerInput = Composer()
    let composerAddButton = UIButton()
    
    let tableViewController = TableViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        tableViewController.delegate = self
        view.addSubview(tableViewController.tableView)
        
        composerInput.composerDelegate = self
        composer.addSubview(composerInput)
        composerAddButton.setTitle("Add", forState: .Normal)
        composerAddButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
        composerAddButton.addTarget(self, action: "handleAddButtonTap", forControlEvents: .TouchUpInside)
        composerAddButton.alpha = 0
        composer.addSubview(composerAddButton)
        view.addSubview(composer)
        
        noteViewController.delegate = self
        
        allNotes = unarchiveNotes()
        tableViewController.notes = allNotes
        loadItems()
        
        scrollToLastCell()
        
//        line = UIView(frame: CGRectMake(0, view.bounds.height - tableViewController.tableView.rowHeight, self.view.bounds.width, tableViewController.tableView.rowHeight))
//        line.backgroundColor = UIColor.redColor()
//        view.addSubview(line)
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
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        composerInput.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableViewController.tableView.frame = CGRectMake(0, 0, view.bounds.width, view.bounds.height - tableViewController.tableView.rowHeight)
        composer.frame = CGRectMake(0, view.bounds.height - tableViewController.tableView.rowHeight, view.frame.width, tableViewController.tableView.rowHeight)
        composerInput.frame = CGRectMake(8, 0, composer.frame.width - 8, composer.frame.height)
        composerAddButton.frame = CGRectMake(view.frame.width - 80, 10, 80, 20)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func composerTextDidChange(text: String) {
        searchResults = allNotes.filter({ (note: CKRecord) -> Bool in
            let query = note.objectForKey("Text") as! String
            let match = query.rangeOfString(text, options: NSStringCompareOptions.CaseInsensitiveSearch)
            return match != nil
        })
        
        if count(text) > 0 {
            println("Showing search results")
            tableViewController.notes = searchResults
            composerAddButton.alpha = 1
        } else {
            println("Showing all notes")
            tableViewController.notes = allNotes
            composerAddButton.alpha = 0
        }
        
        tableViewController.tableView.reloadData()
    }
    
    func handleAddButtonTap() {
        let note = CKRecord(recordType: Note.recordType)
        note.setObject(composerInput.text, forKey: "Text")
        composerInput.clearInput()
        addNote(note)
    }
    
    func scrollToLastCell() {
        if tableViewController.notes.count > 0 {
            let lastCell = NSIndexPath(forItem: tableViewController.notes.count - 1, inSection: 0)
            tableViewController.tableView.scrollToRowAtIndexPath(lastCell, atScrollPosition: UITableViewScrollPosition.Bottom, animated: false)
       }
    }
    
    func presentNote(note: CKRecord) {
        noteViewController.note = note
        navigationController?.pushViewController(noteViewController, animated: true)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue() {
            println("Keyboard will show")
            println(keyboardSize)
            
            composer.frame.origin.y = view.frame.height - keyboardSize.height - tableViewController.tableView.rowHeight
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        println("Keyboard will hide")
        
        composer.frame.origin.y = view.frame.height - tableViewController.tableView.rowHeight
    }
    
    //MARK: CloudKit
    func loadItems() {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: Note.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: true)]
        db.performQuery(query, inZoneWithID: nil) { (results, error) -> Void in
            if error != nil {
                println(error.localizedDescription)
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                //TODO: If local notes are more recent save local copy to iCloud
                //If no internet connection don't replace local copy
                self.allNotes = results as! [CKRecord]
                self.tableViewController.tableView.reloadData()
            })
        }
    }
    
    func addNote(note: CKRecord) {
        allNotes.append(note)
        tableViewController.notes = allNotes
        let indexPath = NSIndexPath(forRow: allNotes.count - 1, inSection: 0)
        tableViewController.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        
        db.saveRecord(note, completionHandler: { (record, error) -> Void in
            if error != nil {
                println(error.localizedDescription)
                //TODO: Show add error in UI
            }
        })
    }
    
    func removeNote(note: CKRecord) {
        if let index = find(allNotes, note) {
            allNotes.removeAtIndex(index)
        }
        
        if let index = find(tableViewController.notes, note) {
            tableViewController.notes.removeAtIndex(index)
            let indexPath = NSIndexPath(forItem: index, inSection: 0)
            tableViewController.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
 
        db.deleteRecordWithID(note.recordID) { (record, error) -> Void in
            if error != nil {
                println(error.localizedDescription)
                //TODO: Show delete error in UI
            }
        }
    }
    
    func modifyNote(note: CKRecord) {
        if let index = find(allNotes, note) {
            allNotes.removeAtIndex(index)
            allNotes.append(note)
        }
        
        if let index = find(tableViewController.notes, note) {
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            let lastPosition = NSIndexPath(forRow: tableViewController.notes.count - 1, inSection: 0)
            
            //Check if note is already at the bottom
            if indexPath != lastPosition {
                //Move cell to bottom
                UIView.setAnimationsEnabled(false)
                tableViewController.tableView.moveRowAtIndexPath(indexPath, toIndexPath: lastPosition)
                UIView.setAnimationsEnabled(true)
                scrollToLastCell()
            }
            
            //Refresh cell
            tableViewController.notes = allNotes
            tableViewController.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
            tableViewController.tableView.reloadRowsAtIndexPaths([lastPosition], withRowAnimation: .None)
        }
        
        let operation = CKModifyRecordsOperation(recordsToSave: [note], recordIDsToDelete: nil)
        operation.modifyRecordsCompletionBlock = { saved, deleted, error in
            if error != nil {
                println(error.localizedDescription)
                //TODO: Show modify error in UI
            }
        }
        db.addOperation(operation)
    }
    
    //MARK: NSCoding
    func unarchiveNotes() -> [CKRecord] {
        var notes = [CKRecord]()
        if let data = defaults.objectForKey(kNotesKey) as? NSData {
            notes = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! [CKRecord]
        }
        return notes
    }
    
    func archiveNotes(notes: [CKRecord]) {
        let data = NSKeyedArchiver.archivedDataWithRootObject(allNotes)
        self.defaults.setObject(data, forKey: kNotesKey)
    }
    
    override func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(allNotes, forKey: kNotesKey)
    }
}

extension CKRecord: Equatable {}
public func ==( lhs: CKRecord, rhs: CKRecord ) -> Bool {
    return lhs.recordID == rhs.recordID
}