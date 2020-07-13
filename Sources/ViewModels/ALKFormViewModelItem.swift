//
//  ALKFormViewModelItem.swift
//  ApplozicSwift
//
//  Created by Mukesh on 08/07/20.
//

import Foundation

enum FormViewModelItemType {
    case text
    case password
    case singleselect
    case multiselect
}

protocol FormViewModelItem {
    var type: FormViewModelItemType { get }
    var sectionTitle: String { get }
    var rowCount: Int { get }
}

extension FormViewModelItem {
    var rowCount: Int {
        return 1
    }
    var sectionTitle: String {
        return ""
    }
}

class FormViewModelSingleselectItem: FormViewModelItem {
    typealias Option = FormTemplate.Element.Option
    var type: FormViewModelItemType {
        return .singleselect
    }
    var title: String
    var options: [Option]
    var sectionTitle: String {
        return title
    }
    var rowCount: Int {
        return options.count
    }
    init(title: String, options: [Option]) {
        self.title = title
        self.options = options
    }
}

class FormViewModelMultiselectItem: FormViewModelItem {
    typealias Option = FormTemplate.Element.Option
    var type: FormViewModelItemType {
        return .multiselect
    }
    var title: String
    var options: [Option]
    var sectionTitle: String {
        return title
    }
    var rowCount: Int {
        return options.count
    }
    init(title: String, options: [Option]) {
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

class FormViewModelPasswordItem: FormViewModelItem {
    var type: FormViewModelItemType {
        return .password
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
                    placeholder: element.placeholder
                ))
            case .password:
                guard let name = element.label else { return }
                items.append(FormViewModelPasswordItem(
                    name: name,
                    placeholder: element.placeholder
                ))
            case .singleSelect:
                guard let title = element.title, let options = element.options else { return }
                items.append(FormViewModelSingleselectItem(
                    title: title,
                    options: options
                ))
            case .multiselect:
                guard let title = element.title, let options = element.options else { return }
                items.append(FormViewModelMultiselectItem(
                    title: title,
                    options: options
                ))
            default:
                print("\(element.contentType) form template type is not part of the form list view")
            }
        }
        return items
    }

    var submitButtonTitle: String? {
        guard let submitButton = elements.filter({ $0.contentType == .submit }).first else { return nil }
        return submitButton.label
    }
}
