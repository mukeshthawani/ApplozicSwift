//
//  ALKFormPasswordItemCell.swift
//  ApplozicSwift
//
//  Created by Mukesh on 13/07/20.
//

import Foundation

class ALKFormPasswordItemCell: UITableViewCell {
    var item: FormViewModelItem? {
        didSet {
            guard let item = item as? FormViewModelPasswordItem else {
                return
            }
            nameLabel.text = item.name
            valueTextField.placeholder = item.placeholder
        }
    }

    let nameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = Font.medium(size: 15).font()
        label.textColor = .black
        label.numberOfLines = 1
        label.textAlignment = .left
        return label
    }()

    let valueTextField: UITextField = {
        let textfield = UITextField(frame: .zero)
        textfield.isSecureTextEntry = true
        return textfield
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addConstraints() {
        addViewsForAutolayout(views: [nameLabel, valueTextField])
        nameLabel.layout {
            $0.leading == leadingAnchor + 10
            $0.trailing == trailingAnchor - 30
            $0.top == topAnchor + 10
        }
        valueTextField.layout {
            $0.leading == nameLabel.leadingAnchor
            $0.trailing == nameLabel.trailingAnchor
            $0.top == nameLabel.bottomAnchor + 5
            $0.bottom <= bottomAnchor - 10
        }
    }
}
