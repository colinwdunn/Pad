//
//  ViewController.swift
//  Pad
//
//  Created by Colin Dunn on 4/10/15.
//  Copyright (c) 2015 Colin Dunn. All rights reserved.
//

import UIKit
import CloudKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    let note = NoteViewController()
    
    var tableView: UITableView!
    var newButton: UIButton!
    var notes = ["First note", "Second note", "Third note"]
    let kCellIdentifier = "Cell"

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView = UITableView(frame: CGRectZero, style: .Plain)
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: kCellIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        
        newButton = UIButton()
        newButton.addTarget(self, action: "handleButtonTap", forControlEvents: .TouchUpInside)
        newButton.setTitle("New", forState: .Normal)
        newButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
        view.addSubview(newButton)
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
        note.textField.text = nil
        presentViewController(note, animated: true, completion: nil)
    }

}

extension ViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(kCellIdentifier) as! UITableViewCell
        cell.textLabel!.text = notes[indexPath.row]
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        note.textField.text = notes[indexPath.row]
        presentViewController(note, animated: true, completion: nil)
    }
}