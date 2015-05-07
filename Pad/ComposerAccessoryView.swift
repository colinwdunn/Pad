//
//  ComposerAccessoryView.swift
//  Pad
//
//  Created by Colin Dunn on 5/5/15.
//  Copyright (c) 2015 Colin Dunn. All rights reserved.
//

import UIKit

protocol ComposerAccessoryViewDelegate {
    func composerTextDidChange(text: String)
    func openNote()
    func addNote(text: String)
    var searchResultsCount: Int! { get }
}

class ComposerAccessoryView: UIView, ComposerDelegate {
    
    let composer = Composer()
    private let composerAddButton = UIButton()
    var delegate: ComposerAccessoryViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.whiteColor()
        
        composer.composerDelegate = self
        addSubview(composer)
        
        composerAddButton.setTitle("Open", forState: .Normal)
        composerAddButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
        composerAddButton.addTarget(self, action: "handleAddButtonTap:", forControlEvents: .TouchUpInside)
        composerAddButton.titleLabel?.font = atlas
        addSubview(composerAddButton)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        composer.frame = bounds
        composerAddButton.frame = CGRectMake(bounds.width - 80, composer.frame.height - 30, 80, 20)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func composerTextDidChange(text: String) {
        delegate?.composerTextDidChange(text)
        
        if count(text) > 0 {
            if delegate?.searchResultsCount > 0 {
                composerAddButton.setTitle("Open", forState: .Normal)
            } else {
                composerAddButton.setTitle("Add", forState: .Normal)
            }
        } else {
            composerAddButton.setTitle("Open", forState: .Normal)
        }
    }
    
    func handleAddButtonTap(button: UIButton) {
        if button.currentTitle == "Add" {
            let text = composer.text
            composer.clearInput()
            delegate?.addNote(text)
        } else {
            delegate?.openNote()
        }
//        if button.currentTitle == "Add" {
//            let note = CKRecord(recordType: Note.recordType)
//            note.setObject(composerInput.text, forKey: "Text")
//            composerInput.clearInput()
//            addNote(note)
//        } else {
//            if searchResults != nil {
//                let note = searchResults[searchResults.count - 1]
//                presentNote(note)
//            } else {
//                let note = allNotes[allNotes.count - 1]
//                presentNote(note)
//            }
//        }
    }

}
