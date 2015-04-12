//
//  ViewController.swift
//  Pad
//
//  Created by Colin Dunn on 4/10/15.
//  Copyright (c) 2015 Colin Dunn. All rights reserved.
//

import UIKit
import CloudKit

class ViewController: UITableViewController, UITableViewDataSource, UITableViewDelegate, NoteDelegate {
    let db = CKContainer.defaultContainer().privateCloudDatabase
    var notes = [CKRecord]()
    let transitionManager = TransitionManger()
    let noteViewController = NoteViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: Note.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 50
        noteViewController.delegate = self
        loadItems()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func scrollToLastCell() {
        let lastCell = NSIndexPath(forItem: notes.count - 1, inSection: 0)
        tableView.scrollToRowAtIndexPath(lastCell, atScrollPosition: UITableViewScrollPosition.Bottom, animated: false)
    }
    
    func presentNote(note: CKRecord, indexPath: NSIndexPath) {
        noteViewController.note = note
        noteViewController.indexPath = indexPath
        noteViewController.modalPresentationStyle = .Custom
        noteViewController.transitioningDelegate = transitionManager
        transitionManager.presentingController = noteViewController
        presentViewController(noteViewController, animated: true, completion: nil)
    }
    
    func handleTap() {
        println("Did tap label")
        let note = CKRecord(recordType: Note.recordType)
        let indexPath = NSIndexPath(forItem: 0, inSection: 0)
        presentNote(note, indexPath: indexPath)
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
                let lastCell = NSIndexPath(forItem: self.notes.count - 1, inSection: 0)
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
                    self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                }
            }
        }
    }
    
    func modifyNote(note: CKRecord) {
        //TODO: remove note if string is empty
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
        presentNote(note, indexPath: indexPath)
    }
}