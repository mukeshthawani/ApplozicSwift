//
//  ALKChatBar+AutoSuggestion.swift
//  ApplozicSwift
//
//  Created by Mukesh on 29/05/19.
//

import Foundation

extension ALKChatBar: UITableViewDataSource, UITableViewDelegate {
    public func numberOfSections(in _: UITableView) -> Int {
        return 1
    }

    public func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return filteredAutocompletionItems.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! =
            tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: UITableViewCell.reuseIdentifier)
        }

        guard indexPath.row < filteredAutocompletionItems.count,
            let selection = selection else {
                return cell
        }
        let item = filteredAutocompletionItems[indexPath.row]

        let prefix = selection.prefix
        if prefix == "@" {
            let cell: MentionAutoSuggestionCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
            cell.updateView(item: item)
            return cell
        } else if prefix == "/" {
            cell.detailTextLabel?.setTextColor(.gray)
            cell.textLabel?.text = "/\(item.key)"
            cell.detailTextLabel?.text = "\(item.content)"
        } else {
            cell.textLabel?.text = "\(item.content)"
        }
        return cell
    }

    public func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < filteredAutocompletionItems.count else {
            return
        }
        let item = filteredAutocompletionItems[indexPath.row]

        // If we replace the text here then it resizes the textview incorrectly.
        // That's why first resetting the text and then inserting the item content.
//        textView.text = ""
//        textView.insertText(text)
        guard let selection = selection else { return }
        // TODO: handle the case when prefix should be removed. In that case
        // we don't have to add anything extra in the location but length will
        // increase
        // TODO: use this
//        let insertionRange = NSRange(location: selection.range.location, length: selection.word.utf16.count)
        insert(item: item, at: selection.range, replace: selection)
        updateTextViewHeight(textView: textView, text: textView.text + item.content)
        hideAutoCompletionView()
    }
}
