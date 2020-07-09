//
//  ALKFormCell.swift
//  ApplozicSwift
//
//  Created by Mukesh on 08/07/20.
//

import UIKit

class ALKFormCell: ALKChatBaseCell<ALKMessageViewModel> {
    typealias Section = [UITableViewCell]

    private var template: FormTemplate? {
        didSet {
            buildSections()
            itemListView.reloadData()
        }
    }
    let itemListView = NestedCellTableView()
    private var sections: [Section] = []

    override func setupViews() {
        super.setupViews()
        setUpTableView()
    }

    override func update(viewModel: ALKMessageViewModel) {
        super.update(viewModel: viewModel)
        template = viewModel.formTemplate()
    }

    private func setUpTableView() {
        itemListView.backgroundColor = .white
        itemListView.estimatedRowHeight = 50
        itemListView.rowHeight = UITableView.automaticDimension
        itemListView.separatorStyle = .none
        itemListView.allowsSelection = false
        itemListView.delegate = self
        itemListView.dataSource = self
        itemListView.register(ALKFormTextItemCell.self)
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

