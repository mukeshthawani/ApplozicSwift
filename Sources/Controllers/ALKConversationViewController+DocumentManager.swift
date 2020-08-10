//
//  ALKConversationViewController+DocumentManager.swift
//  ApplozicSwift
//
//  Created by Mukesh on 07/08/20.
//

import UIKit
import Applozic

extension ALKConversationViewController: ALKDocumentManagerDelegate {
    func documentSelected(at urls: [URL]) {
        for index in 0 ..< urls.count {
            let filePath = urls[index]
            let (message, indexPath) = viewModel.sendFile(
                at: filePath,
                metadata: configuration.messageMetadata
            )
            guard message != nil, let newIndexPath = indexPath else { return }
            self.tableView.beginUpdates()
            self.tableView.insertSections(IndexSet(integer: newIndexPath.section), with: .automatic)
            self.tableView.endUpdates()
            self.tableView.scrollToBottom(animated: false)
            guard let cell = tableView.cellForRow(at: newIndexPath) as? ALKMyDocumentCell else { return }
            guard ALDataNetworkConnection.checkDataNetworkAvailable() else {
                let notificationView = ALNotificationView()
                notificationView.noDataConnectionNotificationView()
                return
            }
            viewModel.uploadImage(view: cell, indexPath: newIndexPath)
        }
    }
}
