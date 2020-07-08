//
//  ALKFormTextItemCell.swift
//  ApplozicSwift
//
//  Created by Mukesh on 08/07/20.
//

import UIKit

class ALKFormTextItemCell: UITableViewCell {
    var item: FormViewModelItem? {
        didSet {
            guard let item = item as? FormViewModelTextItem  else {
                return
            }
            nameLabel.text = item.name
        }
    }

    let nameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = Font.normal(size: 17).font()
        label.textColor = .black
        label.numberOfLines = 1
        label.textAlignment = .center
        return label
    }()

    init() {
        super.init(style: .default, reuseIdentifier: nil)
        addConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addConstraints() {
        addViewsForAutolayout(views: [nameLabel])
        nameLabel.layout {
            $0.leading == leadingAnchor
            $0.trailing == trailingAnchor
            $0.top == topAnchor + 10
            $0.bottom <= bottomAnchor
        }
    }
}
