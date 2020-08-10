//
//  ALKDocumentManager.swift
//  ApplozicSwift
//
//  Created by Mukesh on 06/08/20.
//

import MobileCoreServices
import UIKit

protocol ALKDocumentManagerDelegate: AnyObject {
    func documentSelected(at urls: [URL])
}

class ALKDocumentManager: NSObject {
    weak var delegate: ALKDocumentManagerDelegate?

    func showPicker(from controller: UIViewController) {
        let types = [kUTTypeCompositeContent, kUTTypeContent, kUTTypePresentation, kUTTypeSpreadsheet]
        let importMenu = UIDocumentPickerViewController(documentTypes: types as [String], in: .import)
        if #available(iOS 11.0, *) {
            importMenu.allowsMultipleSelection = true
        }
        importMenu.delegate = self
        importMenu.modalPresentationStyle = .formSheet
        controller.present(importMenu, animated: true)
    }
}

extension ALKDocumentManager: UIDocumentPickerDelegate, UINavigationControllerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        print("Documents selected: \(urls.description)")
        delegate?.documentSelected(at: urls)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}
