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

public struct AutoCompleteConfiguration {
    public var addSpaceAfterInserting = true
    public var insertWithPrefix = true

    /// If it is true, then the auto complete text won't be deleted in
    /// a single back tap and the autocompleted text can be edited
    /// by the user. Default value is false.
    ///
    /// NOTE: If this is true then adding text attributes
    /// like font, color etc. won't work properly as the
    /// content for this prefix will be treated as a normal text.
    public var allowEditingAutocompleteText = false
}

public class AutoCompleteManager: NSObject {
    public let autocompletionView: UITableView
    public let textView: ALKChatBarTextView
    public weak var autocompletionDelegate: AutoCompletionDelegate?

    public var autoCompletionItems = [AutoCompleteItem]()
    var filteredAutocompletionItems = [AutoCompleteItem]()

    fileprivate var autoCompletionViewHeightConstraint: NSLayoutConstraint?
    private var autocompletionPrefixes: Set<String> = []
    private var autocompletionPrefixAttributes: [String: [NSAttributedString.Key: Any]] = [:]
    private var prefixConfigurations: [String: AutoCompleteConfiguration] = [:]

    // Prefix and selected item pair
    typealias Selection = (
        prefix: String,
        range: NSRange,
        word: String
    )
    var selection: Selection?

    init(
        textView: ALKChatBarTextView,
        tableview: UITableView
        ) {
        self.textView = textView
        self.autocompletionView = tableview
        super.init()

        self.textView.add(delegate: self)
        autocompletionView.dataSource = self
        autocompletionView.delegate = self
        autoCompletionViewHeightConstraint = autocompletionView.heightAnchor.constraint(equalToConstant: 0)
        autoCompletionViewHeightConstraint?.isActive = true
    }

    func registerPrefix(
        prefix: String,
        attributes: [NSAttributedString.Key: Any],
        configuration: AutoCompleteConfiguration = AutoCompleteConfiguration()
        ) {
        autocompletionPrefixes.insert(prefix)
        autocompletionPrefixAttributes[prefix] = attributes
        prefixConfigurations[prefix] = configuration
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
        let configuration = prefixConfigurations[selection.prefix] ?? AutoCompleteConfiguration()
        if !configuration.allowEditingAutocompleteText {
            newAttributes[AutoCompleteItem.attributesKey] = selection.prefix + item.key
        }

        let prefix = configuration.insertWithPrefix ? selection.prefix:""
        let insertionItemString = NSAttributedString(
            string: prefix + item.content,
            attributes: newAttributes
        )
        var insertionRange = insertionRange
        if !configuration.insertWithPrefix {
            insertionRange = NSRange(
                location: insertionRange.location-prefix.utf16.count,
                length: insertionRange.length+prefix.utf16.count)
        }
        let newAttributedText = textView.attributedText.replacingCharacters(
            in: insertionRange,
            with: insertionItemString
        )
        if configuration.addSpaceAfterInserting {
            newAttributedText.append(NSAttributedString(string: " ", attributes: defaultAttributes))
        }
        textView.attributedText = newAttributedText
    }
}

extension AutoCompleteManager: UITextViewDelegate {

    public func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText string: String
        ) -> Bool {
        guard var text = textView.text as NSString? else {
            return true
        }

        // Check if deleting an autocomplete item, if yes then
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
