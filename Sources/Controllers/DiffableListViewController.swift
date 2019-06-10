//
//  DiffableListViewController.swift
//  ApplozicSwift
//
//  Created by Mukesh on 08/06/19.
//

import UIKit
import DifferenceKit

protocol MessageThreadUpdate {
    func update(data: [String])
}

open class DiffableListViewController: UITableViewController {

    var sections: [ArraySection<AnySection, AnyChatItem>] = []

    func update(sections: [ArraySection<AnySection, AnyChatItem>]) {
        // First find out the diff then store
        let changeSet = StagedChangeset(source: self.sections, target: sections)
        
        tableView.reload(
            using: changeSet,
            with: UITableView.RowAnimation.none,
            interrupt: { $0.changeCount > 100 },
            setData: { data in
                self.sections = data
        })
    }

    // MARK: - Table view data source

    override open func numberOfSections(in tableView: UITableView) -> Int {

        return sections.count
    }

    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard sections.count > section else { return 0 }
        return sections[section].elements.count
    }


    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // TODO: Create an extension on ArraySections to access elements safely
        guard indexPath.section < sections.count else { return UITableViewCell() }
        let section = sections[indexPath.section]

        guard indexPath.row < section.model.viewModels.count else { return UITableViewCell() }
        let chatItem = section.model.viewModels[indexPath.row]

        let cell = section.model.cellForRow(chatItem, tableView: tableView, indexPath: indexPath)
        cell.backgroundColor = UIColor.green
        return cell
    }
}
