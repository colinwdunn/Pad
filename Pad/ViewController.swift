//
//  ViewController.swift
//  Pad
//
//  Created by Colin Dunn on 4/10/15.
//  Copyright (c) 2015 Colin Dunn. All rights reserved.
//

import UIKit
import CloudKit

class ViewController: UITableViewController, UITableViewDataSource, UITableViewDelegate, NoteDelegate, NSCoding {
    let db = CKContainer.defaultContainer().privateCloudDatabase
    let defaults = NSUserDefaults.standardUserDefaults()
    var notes = [CKRecord]()
    let noteViewController = NoteViewController()
    let kNotesKey = "Notes"
    
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
        notes = unarchiveNotes()
        loadItems()
    }
    
    func unarchiveNotes() -> [CKRecord] {
        var notes = [CKRecord]()
        if let data = defaults.objectForKey(kNotesKey) as? NSData {
            notes = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! [CKRecord]
        }
        println("Restored from disk")
        return notes
    }
    
    func archiveNotes(notes: [CKRecord]) {
        let data = NSKeyedArchiver.archivedDataWithRootObject(self.notes)
        self.defaults.setObject(data, forKey: self.kNotesKey)
        println("Saved to disk")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func scrollToLastCell() {
        if notes.count > 0 {
            let lastCell = NSIndexPath(forItem: notes.count - 1, inSection: 0)
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
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        db.performQuery(query, inZoneWithID: nil) { (results, error) -> Void in
            if error != nil {
                println(error.localizedDescription)
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.notes = results as! [CKRecord]
                self.archiveNotes(self.notes)
                self.tableView.reloadData()
                self.scrollToLastCell()
            })
        }
    }
    
    func addNote(note: CKRecord) {
        db.saveRecord(note, completionHandler: { (record, error) -> Void in
            if error != nil {
                println(error.localizedDescription)
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.notes.append(record)
                let indexPath = NSIndexPath(forRow: self.notes.count - 1, inSection: 0)
                self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                self.archiveNotes(self.notes)
                self.scrollToLastCell()
            })
        })
    }
    
    func removeNote(note: CKRecord) {
        self.db.deleteRecordWithID(note.recordID) { (record, error) -> Void in
            if error != nil {
                println(error.localizedDescription)
            }
            
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                if let index = find(self.notes, note) {
                    self.notes.removeAtIndex(index)
                    let indexPath = NSIndexPath(forRow: index, inSection: 0)
                    self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .None)
                    self.archiveNotes(self.notes)
                }
            }
        }
    }
    
    func modifyNote(note: CKRecord) {
        let operation = CKModifyRecordsOperation(recordsToSave: [note], recordIDsToDelete: nil)
        operation.modifyRecordsCompletionBlock = { saved, deleted, error in
            if error != nil {
                println(error.localizedDescription)
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if let index = find(self.notes, note) {
                    let indexPath = NSIndexPath(forRow: index, inSection: 0)
                    self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
                    self.archiveNotes(self.notes)
                }
            })
        }
        db.addOperation(operation)
    }
    
    //MARK: NSCoding
    required convenience init(coder decoder: NSCoder) {
        self.init()
        println(decoder.decodeObjectForKey(kNotesKey) as! [CKRecord])
    }
    
    override func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(notes, forKey: kNotesKey)
    }

    //MARK: UITableViewDataSource
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(Note.identifier) as! UITableViewCell
        cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: Note.identifier)
        let text = notes[indexPath.row].objectForKey("Text") as! String
        let date = notes[indexPath.row].objectForKey("creationDate") as! NSDate
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d"
        cell.textLabel!.text = text
        cell.detailTextLabel!.text = dateFormatter.stringFromDate(date)
        
        return cell
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView(frame: CGRectMake(0, 0, view.frame.width, tableView.rowHeight))
        footerView.backgroundColor = UIColor.whiteColor()
        let label = UILabel(frame: CGRectMake(16, 0, view.frame.width - 16, tableView.rowHeight))
        label.text = "Write something…"
        label.userInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: "handleTap")
        label.addGestureRecognizer(tapGesture)
        footerView.addSubview(label)
        return footerView
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return tableView.rowHeight
    }
    
    //MARK: UITableViewDelegate
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let note = notes[indexPath.row]
        removeNote(note)
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let note = notes[indexPath.row]
        presentNote(note)
    }
}