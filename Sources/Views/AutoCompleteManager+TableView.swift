//
//  AutoCompleteManager+TableView.swift
//  ApplozicSwift
//
//  Created by Mukesh on 29/05/19.
//

import Foundation

extension AutoCompleteManager: UITableViewDataSource, UITableViewDelegate {
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
            let cell: MentionAutoCompleteCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
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

        guard let selection = selection else { return }

        insert(item: item, at: selection.range, replace: selection)
        cancelAndHide()
    }
}
