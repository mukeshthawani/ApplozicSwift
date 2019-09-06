//
//  MessageMentionHandler.swift
//  ApplozicSwift
//
//  Created by Mukesh on 06/09/19.
//

import Foundation

struct MessageMentionHandler {

    enum MetadataKey {
        static let notification = "AL_NOTIFICATION"
        static let mention = "AL_MEMBER_MENTION"
    }

    typealias Mention = (word: String, range: NSRange)
    static let mentionSymbol = "@"

    let message: NSAttributedString

    private var allMentions: [Mention] = []

    private var messageRange: NSRange {
        let range = message.string.startIndex..<message.string.endIndex
        return NSRange(range, in: message.string)
    }

    init(message: NSAttributedString) {
        self.message = message
        self.allMentions = mentionsInMessage()
    }

    func containsAutosuggestions() -> Bool {
        return !allMentions.isEmpty
    }

    func metadataForMentions() -> [String: Any]? {
        guard !allMentions.isEmpty else { return nil }
        // all usernames for notification
        let userIdString = allMentions
            .reduce("") { $0 + (!$0.isEmpty ? ",":"") + $1.word.dropFirst(MessageMentionHandler.mentionSymbol.count) }
        var metadata: [String: Any] = [MetadataKey.notification: userIdString]

        // key-value for mentions
        metadata[MetadataKey.mention] = true
        return metadata
    }

    func replaceMentionsWithKeys() -> String {
        var newMessage = message
        allMentions.forEach { mention in
            let replacementText = NSAttributedString(string: mention.word)
            newMessage = newMessage.replacingCharacters(in: mention.range, with: replacementText)
        }
        return newMessage.string
    }

    private func mentionsInMessage() -> [Mention] {
        var allMentions: [Mention] = []
        message.enumerateAttribute(AutoCompleteItem.attributesKey, in: messageRange, options: []) { (value, keyRange, _) in
            if let value = value as? String, value.starts(with: MessageMentionHandler.mentionSymbol) {
                allMentions.append((value, keyRange))
            }
        }
        return allMentions
    }
}
