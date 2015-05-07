//
//  ViewController.swift
//  Pad
//
//  Created by Colin Dunn on 4/10/15.
//  Copyright (c) 2015 Colin Dunn. All rights reserved.
//

import UIKit
import CloudKit

class ViewController: UIViewController, NSCoding, NoteDelegate, TableViewDelegate, ComposerAccessoryViewDelegate {
    let db = CKContainer.defaultContainer().privateCloudDatabase
    let defaults = NSUserDefaults.standardUserDefaults()

    var allNotes: [CKRecord]! {
        didSet {
            if oldValue != nil {
                if oldValue != allNotes {
                    archiveNotes(allNotes)
                }
            }
        }
    }
    var searchResults: [CKRecord]!
    var searchResultsCount: Int!
    
    let noteViewController = NoteViewController()
    let kNotesKey = "Notes"
    
    let tableViewController = TableViewController()
    
    private let accessoryView = ComposerAccessoryView(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, 200))
    
    override var inputAccessoryView: ComposerAccessoryView {
        return accessoryView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        tableViewController.delegate = self
        view.addSubview(tableViewController.view)
        
        noteViewController.delegate = self
        
        allNotes = unarchiveNotes()
        tableViewController.notes = allNotes
        loadItems()
        
        scrollToLastCell(false)
        
        accessoryView.delegate = self
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
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        accessoryView.frame = CGRectMake(0, 0, view.bounds.width, 200)
        tableViewController.view.frame = view.bounds
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    //MARK: Composer Delegate
    func composerTextDidChange(text: String) {
        searchResults = allNotes.filter({ (note: CKRecord) -> Bool in
            let query = note.objectForKey("Text") as! String
            let match = query.rangeOfString(text, options: .CaseInsensitiveSearch)
            return match != nil
        })
        
        if count(text) > 0 {
            tableViewController.notes = searchResults
        } else {
            tableViewController.notes = allNotes
            searchResults = nil
        }
        
        tableViewController.tableView.reloadData()
        scrollToLastCell(false)
        
        if searchResults != nil {
            searchResultsCount = searchResults!.count
        } else {
            searchResultsCount = 0
        }
    }
    
    func openNote() {
        let note = tableViewController.notes.last as CKRecord!
        presentNote(note)
    }
    
    //MARK: Functions
    func scrollToLastCell(animated: Bool) {
        if tableViewController.notes.count > 0 {
            let lastCell = NSIndexPath(forItem: tableViewController.notes.count - 1, inSection: 0)
            tableViewController.tableView.scrollToRowAtIndexPath(lastCell, atScrollPosition: .Bottom, animated: animated)
       }
    }
    
    func presentNote(note: CKRecord) {
        noteViewController.note = note
        navigationController?.pushViewController(noteViewController, animated: true)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue() {
            tableViewController.tableView.contentInset.bottom = keyboardSize.height
        }
        scrollToLastCell(true)
    }
    
    func keyboardWillHide(notification: NSNotification) {
        tableViewController.tableView.contentInset.bottom = 0
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
                self.scrollToLastCell(true)
            })
        }
    }
    
    func addNote(text: String) {
        let note = CKRecord(recordType: Note.recordType)
        note.setObject(text, forKey: "Text")
    
        tableViewController.notes.append(note)
        allNotes.append(note)
        
        let indexPath = NSIndexPath(forRow: allNotes.count - 1, inSection: 0)
        tableViewController.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        scrollToLastCell(true)
        
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
                scrollToLastCell(false)
            }
            
            //Refresh cell
            tableViewController.notes = allNotes
            tableViewController.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
            tableViewController.tableView.reloadRowsAtIndexPaths([lastPosition], withRowAnimation: .None)
            tableViewController.tableView.cellForRowAtIndexPath(lastPosition)?.detailTextLabel?.text = "Just now"
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
        println("Saved notes to disk")
    }
    
    override func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(allNotes, forKey: kNotesKey)
    }
}

class Extensions: NSObject {}

extension CKRecord: Equatable {}
public func ==( lhs: CKRecord, rhs: CKRecord ) -> Bool {
    return lhs.recordID == rhs.recordID
}

extension NSDate {
    func yearsFrom(date:NSDate) -> Int { return NSCalendar.currentCalendar().components(NSCalendarUnit.CalendarUnitYear, fromDate: date, toDate: self, options: nil).year }
    func monthsFrom(date:NSDate) -> Int { return NSCalendar.currentCalendar().components(NSCalendarUnit.CalendarUnitMonth, fromDate: date, toDate: self, options: nil).month }
    func weeksFrom(date:NSDate) -> Int { return NSCalendar.currentCalendar().components(NSCalendarUnit.CalendarUnitWeekOfYear, fromDate: date, toDate: self, options: nil).weekOfYear }
    func daysFrom(date:NSDate) -> Int { return NSCalendar.currentCalendar().components(NSCalendarUnit.CalendarUnitDay, fromDate: date, toDate: self, options: nil).day }
    func hoursFrom(date:NSDate) -> Int { return NSCalendar.currentCalendar().components(NSCalendarUnit.CalendarUnitHour, fromDate: date, toDate: self, options: nil).hour }
    func minutesFrom(date:NSDate) -> Int { return NSCalendar.currentCalendar().components(NSCalendarUnit.CalendarUnitMinute, fromDate: date, toDate: self, options: nil).minute }
    func secondsFrom(date:NSDate) -> Int { return NSCalendar.currentCalendar().components(NSCalendarUnit.CalendarUnitSecond, fromDate: date, toDate: self, options: nil).second }
    var relativeTime: String {
        if NSDate().yearsFrom(self)  > 0 {
            return NSDate().yearsFrom(self).description  + "y"
        }
        if NSDate().monthsFrom(self) > 0 {
            return NSDate().monthsFrom(self).description + "m"
        }
        if NSDate().weeksFrom(self) > 0 { return NSDate().weeksFrom(self).description  + "w"
        }
        if NSDate().daysFrom(self) > 0 {
            if NSDate().daysFrom(self) == 1 { return "Yesterday" }
            return NSDate().daysFrom(self).description + "d"
        }
        if NSDate().hoursFrom(self)   > 0 {
            return "\(NSDate().hoursFrom(self))h"
        }
        if NSDate().minutesFrom(self) > 0 {
            return "\(NSDate().minutesFrom(self))m"
        }
        if NSDate().secondsFrom(self) > 0 {
            if NSDate().secondsFrom(self) < 60 { return "Just now" }
            return "\(NSDate().secondsFrom(self))s"
        }
        return ""
    }
}