//
//  TableViewController.swift
//  Pad
//
//  Created by Colin Dunn on 4/25/15.
//  Copyright (c) 2015 Colin Dunn. All rights reserved.
//

import UIKit
import CloudKit

protocol TableViewDelegate {
    func presentNote(note: CKRecord)
    func removeNote(note: CKRecord)
}

class TableViewController: UITableViewController {
    
    var notes: [CKRecord]!
    var delegate: TableViewDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: Note.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 50
        tableView.separatorStyle = .None
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        println("View will appear")
    }
    
    //MARK: TableView Data Source
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(Note.identifier) as! UITableViewCell
        cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: Note.identifier)
        cell.backgroundColor = UIColor.clearColor()
        
        let text = notes[indexPath.row].objectForKey("Text") as! String
        cell.textLabel!.text = text
        
        let date = notes[indexPath.row].objectForKey("modificationDate") as? NSDate
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d"
        
        if date != nil {
            cell.detailTextLabel!.text = dateFormatter.stringFromDate(date!)
        } else {
            cell.detailTextLabel!.text = dateFormatter.stringFromDate(NSDate())
        }
        
        return cell
    }

    //MARK: TableView Delegate
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let note = notes[indexPath.row]
        delegate?.removeNote(note)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let note = notes[indexPath.row]
        delegate?.presentNote(note)
    }
}
