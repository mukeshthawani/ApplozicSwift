//
//  Data+Extension.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/09/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation

extension Data {
    var attributedString: NSAttributedString? {
        do {
            return try NSAttributedString(
                data: self,
                options: [
                    NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html,
                    NSAttributedString.DocumentReadingOptionKey.characterEncoding: String.Encoding.utf8.rawValue,
                ],
                documentAttributes: nil
            )
        } catch {
            print(error)
        }
        return nil
    }

    func saveToDisk(fileExtension: String) -> Result<URL, Error> {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = String(format: "/%f.%@", Date().timeIntervalSince1970 * 1000, fileExtension)
        let fullPath = documentsURL.appendingPathComponent(filePath)
        do {
            try write(to: fullPath, options: .atomic)
            return .success(fullPath)
        } catch let error {
            return .failure(error)
        }
    }
}
