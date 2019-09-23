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

/// AutoComplete configuration for each prefix.
public struct AutoCompleteConfiguration {

    /// If true then space will be added after the autocomplete text.
    /// Default value is true.
    public var addSpaceAfterInserting = true

    /// If true then the selected autocomplete item will be
    /// inserted with the prefix. Default value is true.
    public var insertWithPrefix = true

    /// If it is true, then the auto complete text won't be deleted in
    /// a single back tap and the autocompleted text can be edited
    /// by the user. Default value is false.
    ///
    /// NOTE: If this is true then adding text attributes
    /// like font, color etc. won't work properly as the
    /// content for this prefix will be treated as a normal text.
    public var allowEditingAutocompleteText = false

    /// Style for autocomplete text.
    public var textStyle: Style?

    public init() {}
}

/// An autocomplete manager that is used for registering prefixes,
/// finding prefixes in user text and showing autocomplete suggestions.
public class AutoCompleteManager: NSObject {
    public let autocompletionView: UITableView
    public let textView: ALKChatBarTextView
    public weak var autocompletionDelegate: AutoCompletionDelegate?
    public var items = [AutoCompleteItem]()

    // Prefix and entered word with its range in the text.
    typealias Selection = (
        prefix: String,
        range: NSRange,
        word: String
    )

    var selection: Selection? {
        didSet {
            if selection == nil {
                items = []
            }
        }
    }

    fileprivate var autoCompletionViewHeightConstraint: NSLayoutConstraint?
    private var autocompletionPrefixes: Set<String> = []
    private var prefixConfigurations: [String: AutoCompleteConfiguration] = [:]

    public init(
        textView: ALKChatBarTextView,
        tableview: UITableView
    ) {
        self.textView = textView
        autocompletionView = tableview
        super.init()

        self.textView.add(delegate: self)
        autocompletionView.dataSource = self
        autocompletionView.delegate = self
        autoCompletionViewHeightConstraint = autocompletionView.heightAnchor.constraint(equalToConstant: 0)
        autoCompletionViewHeightConstraint?.isActive = true
    }

    public func registerPrefix(
        prefix: String,
        configuration: AutoCompleteConfiguration = AutoCompleteConfiguration()
    ) {
        autocompletionPrefixes.insert(prefix)
        prefixConfigurations[prefix] = configuration
    }

    public func reloadAutoCompletionView() {
        autocompletionView.reloadData()
    }

    public func hide(_ flag: Bool) {
        if flag {
            autoCompletionViewHeightConstraint?.constant = 0
        } else {
            let contentHeight = autocompletionView.contentSize.height

            let bottomPadding: CGFloat = contentHeight > 0 ? 25 : 0
            let maxheight: CGFloat = 200
            autoCompletionViewHeightConstraint?.constant = contentHeight < maxheight ? contentHeight + bottomPadding : maxheight
        }
    }

    public func cancelAndHide() {
        selection = nil
        hide(true)
    }

    func insert(item: AutoCompleteItem, at insertionRange: NSRange, replace selection: Selection) {
        let defaultAttributes = textView.typingAttributes
        var newAttributes = defaultAttributes
        let configuration = prefixConfigurations[selection.prefix] ?? AutoCompleteConfiguration()
        if let style = configuration.textStyle {
            // pass prefix attributes for the range and override old value if present
            newAttributes.merge(style.toAttributes) { $1 }
        }
        if !configuration.allowEditingAutocompleteText {
            newAttributes[AutoCompleteItem.attributesKey] = selection.prefix + item.key
        }

        let prefix = configuration.insertWithPrefix ? selection.prefix : ""
        let insertionItemString = NSAttributedString(
            string: prefix + item.content,
            attributes: newAttributes
        )
        var insertionRange = insertionRange
        if !configuration.insertWithPrefix {
            insertionRange = NSRange(
                location: insertionRange.location - prefix.utf16.count,
                length: insertionRange.length + prefix.utf16.count
            )
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
        replacementText _: String
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
            cancelAndHide()
            return
        }

        selection = (result.prefix, result.range, String(result.word.dropFirst(result.prefix.count)))
        // Call delegate and get items
        autocompletionDelegate?.didMatch(prefix: result.prefix, message: String(result.word.dropFirst(result.prefix.count)))
    }
}

extension AutoCompleteConfiguration {
    public static var memberMention: AutoCompleteConfiguration {
        var config = AutoCompleteConfiguration()
        config.textStyle = Style(
            font: UIFont.systemFont(ofSize: 14),
            text: UIColor.blue,
            background: UIColor.blue.withAlphaComponent(0.1)
        )
        return config
    }
}

extension Style {
    var toAttributes: [NSAttributedString.Key: Any] {
        return [
            .foregroundColor: text,
            .backgroundColor: background,
            .font: font
        ]
    }
}
