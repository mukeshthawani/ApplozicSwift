//
//  AutoCompleteManager.swift
//  ApplozicSwift
//
//  Created by Mukesh on 16/09/19.
//

import UIKit

public protocol AutoCompletionDelegate: AnyObject {
    func didMatch(prefix: String, message: String)
}

public class AutoCompleteManager: NSObject {
    public var autocompletionView: UITableView!
    public var textView: UITextView!
    public weak var autocompletionDelegate: AutoCompletionDelegate?

    public var autoCompletionItems = [AutoCompleteItem]()
    var filteredAutocompletionItems = [AutoCompleteItem]()

    fileprivate var autoCompletionViewHeightConstraint: NSLayoutConstraint?
    private var autocompletionPrefixes: Set<String> = []
    private var autocompletionPrefixAttributes: [String: [NSAttributedString.Key: Any]] = [:]

    // Prefix and selected item pair
    typealias Selection = (
        prefix: String,
        range: NSRange,
        word: String
    )
    var selection: Selection?

    func setupAutoCompletion(_ tableview: UITableView) {
        autocompletionView = tableview
        autocompletionView.dataSource = self
        autocompletionView.delegate = self
        autoCompletionViewHeightConstraint = autocompletionView.heightAnchor.constraint(equalToConstant: 0)
        autoCompletionViewHeightConstraint?.isActive = true
    }

    func registerPrefix(prefix: String, attributes: [NSAttributedString.Key: Any]) {
        autocompletionPrefixes.insert(prefix)
        autocompletionPrefixAttributes[prefix] = attributes
    }

    func reloadAutoCompletionView() {
        autocompletionView.reloadData()
    }

    func showAutoCompletionView() {
        let contentHeight = autocompletionView.contentSize.height

        let bottomPadding: CGFloat = contentHeight > 0 ? 25 : 0
        let maxheight: CGFloat = 200
        autoCompletionViewHeightConstraint?.constant = contentHeight < maxheight ? contentHeight + bottomPadding : maxheight
    }

    func hideAutoCompletionView() {
        autoCompletionViewHeightConstraint?.constant = 0
    }

    func textStartsWithPrefix(_ text: String, prefix: String) -> Bool {
        guard !prefix.isEmpty, text.starts(with: prefix) else { return false }
        if text.count > 1, text[1] == " " { return false }
        return true
    }


    func insert(item: AutoCompleteItem, at insertionRange: NSRange, replace selection: Selection) {
        let defaultAttributes = textView.typingAttributes
        var newAttributes = defaultAttributes
        if let prefixAttributes = autocompletionPrefixAttributes[selection.prefix] {
            // pass prefix attributes for the range and override old value if present
            newAttributes.merge(prefixAttributes) { $1 }
        }
        // prefix to identify which autocomplete is present
        newAttributes[AutoCompleteItem.attributesKey] = selection.prefix + item.key

        let insertionItemString = NSAttributedString(
            string: selection.prefix + item.content,
            attributes: newAttributes
        )

        let newAttributedText = textView.attributedText.replacingCharacters(
            in: insertionRange,
            with: insertionItemString
        )
        newAttributedText.append(NSAttributedString(string: " ", attributes: defaultAttributes))

        // If we replace the text here then it resizes the textview incorrectly.
        // That's why first resetting the text and then inserting the item content.
        // Also, to prevent keyboard autocorrect from cloberring the insert.
        textView.attributedText = NSAttributedString()
        textView.attributedText = newAttributedText
    }
}

extension AutoCompleteManager {
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText string: String) -> Bool {
            guard var text = textView.text as NSString? else {
                return true
            }

            // check if deleting an autocomplete item, if yes then
            // remove full item in one go and clear the attributes
            //
            // range.length == 1: Remove single character
            // range.lowerBound < textView.selectedRange.lowerBound: Ignore trying to delete
            //      the substring if the user is already doing so
            if range.length == 1, range.lowerBound < textView.selectedRange.lowerBound {
                // Backspace/removing text
                let attribute = textView.attributedText
                    .attributes(at: range.lowerBound, longestEffectiveRange: nil, in: range)
                    .filter { $0.key == AutoCompleteItem.attributesKey }

                if let isAutocomplete = attribute[AutoCompleteItem.attributesKey] as? String, !isAutocomplete.isEmpty {
                    // Remove the autocompleted substring
                    let lowerRange = NSRange(location: 0, length: range.location + 1)
                    textView.attributedText.enumerateAttribute(AutoCompleteItem.attributesKey, in: lowerRange, options: .reverse, using: { _, range, stop in

                        // Only delete the first found range
                        defer { stop.pointee = true }

                        let emptyString = NSAttributedString(string: "", attributes: textView.typingAttributes)
                        textView.attributedText = textView.attributedText.replacingCharacters(in: range, with: emptyString)
                        textView.selectedRange = NSRange(location: range.location, length: 0)
                    })
                }
            }

            text = text.replacingCharacters(in: range, with: string) as NSString
//            updateTextViewHeight(textView: textView, text: text as String)
            return true
        }

        public func textViewDidChangeSelection(_ textView: UITextView) {
            guard let result = textView.find(prefixes: autocompletionPrefixes) else {
                hideAutoCompletionView()
                return
            }

            selection = (result.prefix, result.range, String(result.word.dropFirst(result.prefix.count)))
            // Call delegate and get items
            autocompletionDelegate?.didMatch(prefix: result.prefix, message: String(result.word.dropFirst(result.prefix.count)))
        }
}
