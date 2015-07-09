//
//  Composer.swift
//  Pad
//
//  Created by Colin Dunn on 4/18/15.
//  Copyright (c) 2015 Colin Dunn. All rights reserved.
//

import UIKit

protocol ComposerDelegate {
    func composerTextDidChange(text: String)
}

class Composer: UITextView {
    var composerDelegate: ComposerDelegate?
    var placeholderText = "Open or add a note…"
    let placeholderTextColor = UIColor.lightGrayColor()
    override var text: String! {
        didSet {
            if text == placeholderText {
                textColor = placeholderTextColor
            } else {
                textColor = UIColor.blackColor()
            }
        }
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        font = atlasGroteskOfSize(20)
        delegate = self
        keyboardAppearance = .Dark
        text = placeholderText
        backgroundColor = UIColor.clearColor()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func clearInput() {
        text = ""
        composerDelegate?.composerTextDidChange(text)
        text = placeholderText
        selectedTextRange = textRangeFromPosition(beginningOfDocument, toPosition: beginningOfDocument)
    }
    
    func textDidChange(text: String) {
//        let characterCount = text.characters.count
//        println(characterCount)
        
//        if characterCount < 20 {
//            font = atlasGroteskOfSize(20)
//        } else if characterCount > 20 {
//            font = atlasGroteskOfSize(18)
//        } else if characterCount > 40 {
//            font = atlasGroteskOfSize(16)
//        }
    }
}

extension Composer: UITextViewDelegate {
    func textViewDidBeginEditing(textView: UITextView) {
        if textView.text == placeholderText {
            selectedTextRange = textRangeFromPosition(beginningOfDocument, toPosition: beginningOfDocument)
        }
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {        
        let currentText:NSString = textView.text
        let updatedText = (currentText == placeholderText) ? text : currentText.stringByReplacingCharactersInRange(range, withString: text)
        composerDelegate?.composerTextDidChange(updatedText)
        textDidChange(updatedText)
        
        if updatedText.characters.count == 0 {
            self.text = placeholderText
            self.textColor = placeholderTextColor
            selectedTextRange = textRangeFromPosition(beginningOfDocument, toPosition: beginningOfDocument)
            return false
        } else if textView.textColor == placeholderTextColor && text.characters.count > 0 {
            self.text = nil
            self.textColor = UIColor.blackColor()
        }
        
        return true
    }
    
    func textViewDidChangeSelection(textView: UITextView) {
        if window != nil {
            if textView.textColor == placeholderTextColor {
                textView.selectedTextRange = textView.textRangeFromPosition(textView.beginningOfDocument, toPosition: textView.beginningOfDocument)
            }
        }
    }
}
