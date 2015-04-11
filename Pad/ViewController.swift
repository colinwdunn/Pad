//
//  ViewController.swift
//  Pad
//
//  Created by Colin Dunn on 4/10/15.
//  Copyright (c) 2015 Colin Dunn. All rights reserved.
//

import UIKit
import CloudKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NoteDelegate {
    let db = CKContainer.defaultContainer().privateCloudDatabase
    let noteViewController = NoteViewController()
    var tableView: UITableView!
    var newButton: UIButton!
    var notes = [CKRecord]()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView = UITableView(frame: CGRectZero, style: .Plain)
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: Note.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        
        newButton = UIButton()
        newButton.addTarget(self, action: "handleButtonTap", forControlEvents: .TouchUpInside)
        newButton.setTitle("New", forState: .Normal)
        newButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
        view.addSubview(newButton)
        
        loadItems()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        newButton.frame = CGRectMake(view.bounds.width - 100, 10, 100, 25)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func handleButtonTap() {
        noteViewController.textField.text = nil
        noteViewController.delegate = self
        presentViewController(noteViewController, animated: true, completion: nil)
    }
    
    //MARK: CloudKit
    func loadItems() {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: Note.recordType, predicate: predicate)
        db.performQuery(query, inZoneWithID: nil) { (results, error) -> Void in
            if error != nil {
                println(error.localizedDescription)
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.notes = results as! [CKRecord]
                self.tableView.reloadData()
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
                    self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
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
                self.tableView.reloadData()
                if let index = find(self.notes, note) {
                    let indexPath = NSIndexPath(forRow: index, inSection: 0)
                    self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                }
            })
        }
        db.addOperation(operation)
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
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
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let note = notes[indexPath.row]
        removeNote(note)
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let text = notes[indexPath.row].objectForKey("Text") as! String
        noteViewController.delegate = self
        noteViewController.note = notes[indexPath.row]
        presentViewController(noteViewController, animated: true, completion: nil)
    }
}