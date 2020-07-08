//
//  ALKFormCell.swift
//  ApplozicSwift
//
//  Created by Mukesh on 08/07/20.
//

import UIKit

class ALKFormCell: UITableViewCell {
    typealias Section = [UITableViewCell]

    var template: FormTemplate? {
        didSet {
            buildSections()
            tableView.reloadData()
        }
    }
    private var sections: [Section] = []

    private let tableView = NestedCellTableView()

    // TODO: Add message view and handle auto height
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpTableView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpTableView() {
        tableView.backgroundColor = .white
        tableView.estimatedRowHeight = 50
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ALKFormTextItemCell.self)

        addViewsForAutolayout(views: [tableView])
        tableView.layout {
            $0.top == topAnchor
            $0.bottom == bottomAnchor
            $0.leading == leadingAnchor + 20
            $0.trailing == trailingAnchor - 20
        }
    }

    private func buildSections() {
        guard let template = template else { return }
        sections = []
        for item in template.viewModeItems {
            switch item.type {
            case .text:
                let formViewCell = ALKFormTextItemCell()
                formViewCell.item = item
                sections.append([formViewCell])
            default:
                // TODO: temp
                print("Not supported")
            }
        }
    }

    private func cell(for indexPath: IndexPath) -> UITableViewCell {
        return sections[indexPath.section][indexPath.row]
    }
}

extension ALKFormCell: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cell(for: indexPath)
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let lineView = UIView(frame: CGRect(x: 0, y:0, width: tableView.frame.width, height: 0.5))
        lineView.backgroundColor = .lightGray
        return lineView
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.5
    }
}

class NestedCellTableView: UITableView {
    override var intrinsicContentSize: CGSize {
        self.layoutIfNeeded()
        return self.contentSize
    }

    override var contentSize: CGSize {
        didSet{
            self.invalidateIntrinsicContentSize()
        }
    }
}

