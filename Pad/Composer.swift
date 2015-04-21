//
//  Composer.swift
//  Pad
//
//  Created by Colin Dunn on 4/18/15.
//  Copyright (c) 2015 Colin Dunn. All rights reserved.
//

import UIKit

class Composer: UITextView, UITextViewDelegate {
    var placeholderText = "Write something…"
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
        font = UIFont.systemFontOfSize(18)
        keyboardAppearance = .Dark
        text = placeholderText
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        let updatedText = currentText.stringByReplacingCharactersInRange(range, withString: text)
        
        if count(updatedText) == 0 {
            self.text = placeholderText
            self.textColor = placeholderTextColor
            selectedTextRange = textRangeFromPosition(beginningOfDocument, toPosition: beginningOfDocument)
            return false
        } else if textView.textColor == placeholderTextColor && count(text) > 0 {
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
