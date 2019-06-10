//
//  Section.swift
//  ApplozicSwift
//
//  Created by Mukesh on 08/06/19.
//

import Foundation
import DifferenceKit

protocol ChatItem {
    var reuseIdentifier: String { get }
}

protocol ChatCell: UITableViewCell {
    var viewModel: AnyChatItem? { get set }
}

protocol Section {

    var model: AnyDifferentiable { get }

    var viewModels: Array<AnyChatItem> { get }

    var controllerContext: UIViewController? { get set }

    func cellForRow(
        _ viewModel: AnyChatItem,
        tableView: UITableView,
        indexPath: IndexPath) -> ChatCell
}

struct AnySection: Section, Differentiable {

    var base: Section

    var model: AnyDifferentiable {
        return base.model
    }

    var viewModels: Array<AnyChatItem> {
        return base.viewModels
    }

    var controllerContext: UIViewController? {
        get {
            return base.controllerContext
        } set {
            base.controllerContext = newValue
        }
    }

    var differenceIdentifier: AnyHashable {
        return AnyHashable(model.differenceIdentifier)
    }

    init<S: Section>(_ base: S) {
        self.base = base
    }

    func cellForRow(_ viewModel: AnyChatItem, tableView: UITableView, indexPath: IndexPath) -> ChatCell {
        return base.cellForRow(viewModel, tableView: tableView, indexPath: indexPath)
    }


    func isContentEqual(to source: AnySection) -> Bool {
        return model.isContentEqual(to: source.model)
    }
}

struct AnyChatItem: ChatItem, Differentiable {
    var base: ChatItem

    var reuseIdentifier: String {
        return base.reuseIdentifier
    }
    var differenceIdentifier: AnyHashable

    var isEqual: (AnyChatItem) -> Bool

    init<C: ChatItem & Differentiable>(_ base: C) {
        self.base = base
        self.differenceIdentifier = base.differenceIdentifier

        self.isEqual = { source in
            return (source.base as? C)?.differenceIdentifier == base.differenceIdentifier
        }
    }

    func isContentEqual(to source: AnyChatItem) -> Bool {
        return isEqual(source)
    }
}
