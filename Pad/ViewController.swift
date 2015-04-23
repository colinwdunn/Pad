//
//  ViewController.swift
//  Pad
//
//  Created by Colin Dunn on 4/10/15.
//  Copyright (c) 2015 Colin Dunn. All rights reserved.
//

import UIKit
import CloudKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NoteDelegate, NSCoding, ComposerDelegate {
    let db = CKContainer.defaultContainer().privateCloudDatabase
    let defaults = NSUserDefaults.standardUserDefaults()
    var tableView: UITableView!
    var allNotes: [CKRecord]!
    var visibleNotes: [CKRecord]!
    var searchResults: [CKRecord]!
    var query = String()
    let noteViewController = NoteViewController()
    let kNotesKey = "Notes"
    
    let composer = UIView()
    var composerInput = Composer()
    
    struct note {
        var date: NSDate
        var text: String
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        tableView = UITableView(frame: CGRectZero, style: .Plain)
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: Note.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 50
        view.addSubview(tableView)
        
        composerInput.composerDelegate = self
        composer.addSubview(composerInput)
        view.addSubview(composer)
        
        noteViewController.delegate = self
        
        allNotes = unarchiveNotes()
        visibleNotes = allNotes
        loadItems()
        
        scrollToLastCell()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        composer.frame = CGRectMake(0, 0, view.frame.width, tableView.rowHeight)
        composerInput.frame = CGRectMake(8, 0, composer.frame.width - 8, composer.frame.height)
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
            visibleNotes = searchResults
        } else {
            visibleNotes = allNotes
        }
        
        tableView.reloadData()
    }
    
    func scrollToLastCell() {
        if visibleNotes.count > 0 {
            let lastCell = NSIndexPath(forItem: visibleNotes.count - 1, inSection: 0)
            tableView.scrollToRowAtIndexPath(lastCell, atScrollPosition: UITableViewScrollPosition.Bottom, animated: false)
        }
    }
    
    func presentNote(note: CKRecord) {
        noteViewController.note = note
        navigationController?.pushViewController(noteViewController, animated: true)
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
                self.archiveNotes(self.allNotes)
                self.tableView.reloadData()
            })
        }
    }
    
    func addNote(note: CKRecord) {
        self.allNotes.append(note)
        let indexPath = NSIndexPath(forRow: self.allNotes.count - 1, inSection: 0)
        self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .None)
        self.archiveNotes(self.allNotes)
        self.scrollToLastCell()
        
        db.saveRecord(note, completionHandler: { (record, error) -> Void in
            if error != nil {
                println(error.localizedDescription)
                //TODO: Show add error in UI
            }
        })
    }
    
    func removeNote(note: CKRecord) {
        if let index = find(self.allNotes, note) {
            self.allNotes.removeAtIndex(index)
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .None)
            self.archiveNotes(self.allNotes)
        }
        
        self.db.deleteRecordWithID(note.recordID) { (record, error) -> Void in
            if error != nil {
                println(error.localizedDescription)
                //TODO: Show delete error in UI
            }
        }
    }
    
    func modifyNote(note: CKRecord) {
        if let index = find(self.allNotes, note) {
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            let lastPosition = NSIndexPath(forRow: allNotes.count - 1, inSection: 0)
            
            //Check if note is already at the bottom
            if indexPath != lastPosition {
                //Move cell to bottom
                UIView.setAnimationsEnabled(false)
                tableView.moveRowAtIndexPath(indexPath, toIndexPath: lastPosition)
                UIView.setAnimationsEnabled(true)
                
                //Move note in data source and save to disk
                allNotes.removeAtIndex(index)
                allNotes.append(note)
                self.archiveNotes(self.allNotes)
                
                scrollToLastCell()
            }
            
            //Refresh bottom cell
            tableView.reloadRowsAtIndexPaths([lastPosition], withRowAnimation: .None)
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
    
    required convenience init(coder decoder: NSCoder) {
        self.init()
        println(decoder.decodeObjectForKey(kNotesKey) as! [CKRecord])
    }
    
    override func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(allNotes, forKey: kNotesKey)
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visibleNotes.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(Note.identifier) as! UITableViewCell
        cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: Note.identifier)
        
        let text = visibleNotes[indexPath.row].objectForKey("Text") as! String
        cell.textLabel!.text = text
        
        let date = visibleNotes[indexPath.row].objectForKey("modificationDate") as? NSDate
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d"
        
        if date != nil {
            cell.detailTextLabel!.text = dateFormatter.stringFromDate(date!)
        } else {
            cell.detailTextLabel!.text = dateFormatter.stringFromDate(NSDate())
        }
        
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let note = visibleNotes[indexPath.row]
        removeNote(note)
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let note = visibleNotes[indexPath.row]
        presentNote(note)
    }
    
    //MARK: ScrollView Delegate
    func scrollViewDidScroll(scrollView: UIScrollView) {
        composerInput.resignFirstResponder()
    }
}