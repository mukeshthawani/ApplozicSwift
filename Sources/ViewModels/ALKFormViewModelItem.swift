//
//  ALKFormViewModelItem.swift
//  ApplozicSwift
//
//  Created by Mukesh on 08/07/20.
//

import Foundation

enum FormViewModelItemType {
    case text
    case checkbox
}

protocol FormViewModelItem {
    var type: FormViewModelItemType { get }
    var rowCount: Int { get }
}

extension FormViewModelItem {
    var rowCount: Int {
        return 1
    }
}

class FormViewModelCheckboxItem: FormViewModelItem {
    var type: FormViewModelItemType {
        return .checkbox
    }
    var title: String
    var options: [String]

    var rowCount: Int {
        return options.count
    }
    init(title: String, options: [String]) {
        self.title = title
        self.options = options
    }
}

class FormViewModelTextItem: FormViewModelItem {
    var type: FormViewModelItemType {
        return .text
    }
    let name: String
    let placeholder: String?

    init(name: String, placeholder: String?) {
        self.name = name
        self.placeholder = placeholder
    }
}

extension FormTemplate {
    var viewModeItems: [FormViewModelItem] {
        var items: [FormViewModelItem] = []
        elements.forEach { element in
            switch element.contentType {
            case .text:
                guard let name = element.label else { return }
                items.append(FormViewModelTextItem(
                    name: name,
                    placeholder: element.placeholder)
                )
            case .unknown:
                print("Form template: unknown type")
            default:
                // TODO: Temp, remove this
                items.append(FormViewModelTextItem(name: "Temp cell", placeholder: nil))
            }
        }
        return items
    }
}
