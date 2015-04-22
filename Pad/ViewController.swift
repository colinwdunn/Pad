//
//  ViewController.swift
//  Pad
//
//  Created by Colin Dunn on 4/10/15.
//  Copyright (c) 2015 Colin Dunn. All rights reserved.
//

import UIKit
import CloudKit

class ViewController: UITableViewController, UITableViewDataSource, UITableViewDelegate, NoteDelegate, NSCoding, UITextViewDelegate {
    let db = CKContainer.defaultContainer().privateCloudDatabase
    let defaults = NSUserDefaults.standardUserDefaults()
    var allNotes: [CKRecord]!
    var visibleNotes: [CKRecord]!
    var searchResults: [CKRecord]!
    var shouldShowSearchResults = false {
        didSet {
            refreshTableView()
        }
    }
    var query = String()
    let noteViewController = NoteViewController()
    let kNotesKey = "Notes"
    var composer = Composer()
    
    struct note {
        var date: NSDate
        var text: String
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: Note.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 50
        noteViewController.delegate = self
        allNotes = unarchiveNotes()
        visibleNotes = allNotes
        composer.becomeFirstResponder()
        composer.delegate = self
        scrollToLastCell()
        loadItems()
    }
    
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
    
    func refreshTableView() {
        if shouldShowSearchResults {
            visibleNotes = searchResults
        } else {
            visibleNotes = allNotes
        }
        tableView.reloadData()
        println("search results set")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
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
    
    func handleTap() {
        let note = CKRecord(recordType: Note.recordType)
        presentNote(note)
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
    required convenience init(coder decoder: NSCoder) {
        self.init()
        println(decoder.decodeObjectForKey(kNotesKey) as! [CKRecord])
    }
    
    override func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(allNotes, forKey: kNotesKey)
    }

    //MARK: UITableViewDataSource
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visibleNotes.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
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
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView(frame: CGRectMake(0, 0, view.frame.width, tableView.rowHeight))
        footerView.backgroundColor = UIColor.whiteColor()
        
        composer.frame = CGRectMake(8, 0, view.frame.width - 8, tableView.rowHeight)
        footerView.addSubview(composer)
        return footerView
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return tableView.rowHeight
    }
    
    //MARK: UITableViewDelegate
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let note = visibleNotes[indexPath.row]
        removeNote(note)
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let note = visibleNotes[indexPath.row]
        presentNote(note)
    }
    
    //MARK: ScrollView Delegate
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        composer.resignFirstResponder()
    }
}

extension ViewController: UITextViewDelegate {
    func textViewDidBeginEditing(textView: UITextView) {
        composer.textViewDidBeginEditing(textView)
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        let currentText:NSString = textView.text
        query = currentText.stringByReplacingCharactersInRange(range, withString: text)
        
        if count(query) == 0 || query == composer.placeholderText {
            shouldShowSearchResults = false
        } else {
            shouldShowSearchResults = true
        }
        return composer.textView(textView, shouldChangeTextInRange: range, replacementText: text)
    }
    
    func textViewDidChangeSelection(textView: UITextView) {
        composer.textViewDidChangeSelection(textView)
    }
    
    func textViewDidChange(textView: UITextView) {
        searchResults = allNotes.filter({ (note: CKRecord) -> Bool in
            let query = note.objectForKey("Text") as! String
            let match = query.rangeOfString(textView.text, options: NSStringCompareOptions.CaseInsensitiveSearch)
            return match != nil
        })
    }
}