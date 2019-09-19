//
//  ALChatBarTextView.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import UIKit

open class ALKChatBarTextView: UITextView {
    weak var overrideNextResponder: UIResponder?

    open override var next: UIResponder? {
        if let overrideNextResponder = self.overrideNextResponder {
            return overrideNextResponder
        }

        return super.next
    }

    open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if overrideNextResponder != nil {
            return false
        }

        return super.canPerformAction(action, withSender: sender)
    }

    open override var text: String! {
        get { return super.text }
        set {
            let didChange = super.text != newValue
            super.text = newValue
            if didChange {
                delegate?.textViewDidChange?(self)
            }
        }
    }

    open override var attributedText: NSAttributedString! {
        get { return super.attributedText }
        set {
            let didChange = super.attributedText != newValue
            super.attributedText = newValue
            if didChange {
                delegate?.textViewDidChange?(self)
            }
        }
    }

    open override var delegate: UITextViewDelegate? {
        get { return self }
        set {}
    }

    private let delegates: NSHashTable<UITextViewDelegate> = NSHashTable.weakObjects()

    func add(delegate: UITextViewDelegate) {
        delegates.add(delegate)
    }

    func remove(delegate: UITextViewDelegate) {
        for oneDelegate in delegates.allObjects.reversed() {
            if oneDelegate === delegate {
                delegates.remove(oneDelegate)
            }
        }
    }

    fileprivate func invoke(invocation: (UITextViewDelegate) -> Void) {
        for delegate in delegates.allObjects.reversed() {
            invocation(delegate)
        }
    }
}

extension ALKChatBarTextView: UITextViewDelegate {
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        invoke { _ = $0.textView?(textView, shouldChangeTextIn: range, replacementText: text) }
        return true
    }

    public func textViewDidChangeSelection(_ textView: UITextView) {
        invoke { $0.textViewDidChangeSelection?(textView) }
    }

    public func textViewDidBeginEditing(_ textView: UITextView) {
        invoke { $0.textViewDidBeginEditing?(textView) }
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        invoke { $0.textViewDidEndEditing?(textView) }
    }

    public func textViewDidChange(_ textView: UITextView) {
        invoke { $0.textViewDidChange?(textView) }
    }
}
