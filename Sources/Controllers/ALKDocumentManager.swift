//
//  ALKDocumentManager.swift
//  ApplozicSwift
//
//  Created by Mukesh on 06/08/20.
//

import MobileCoreServices
import UIKit

class ALKDocumentManager: NSObject {
    static let shared = ALKDocumentManager()

    func showPicker(from controller: UIViewController) {
        let types = [kUTTypePDF, kUTTypeText, kUTTypeRTF, kUTTypeSpreadsheet]
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
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}
