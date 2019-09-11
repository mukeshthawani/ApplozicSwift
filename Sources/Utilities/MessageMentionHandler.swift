//
//  MessageMentionHandler.swift
//  ApplozicSwift
//
//  Created by Mukesh on 06/09/19.
//

import Foundation

// typealias for all type related to mentions
enum MemberMention {
    enum MetadataKey {
        static let notification = "AL_NOTIFICATION"
        static let mention = "AL_MEMBER_MENTION"
    }
}

struct MessageMentionHandler {

    typealias Mention = (userId: String, range: NSRange)
    static let mentionSymbol = "@"

    let message: NSAttributedString

    private var allMentions: [Mention] = []

    private var messageRange: NSRange {
        let range = message.string.startIndex..<message.string.endIndex
        return NSRange(range, in: message.string)
    }

    init(message: NSAttributedString) {
        self.message = message
        self.allMentions = mentionsInMessage(message)
    }

    func containsAutosuggestions() -> Bool {
        return !allMentions.isEmpty
    }

    func metadataForMentions() -> [String: Any]? {
        guard !allMentions.isEmpty else { return nil }
        // all usernames for notification
        let userIds = Set(allMentions
            .map { $0.userId.dropFirst(MessageMentionHandler.mentionSymbol.count) })
        let userIdString = userIds
            .reduce("") { $0 + (!$0.isEmpty ? ",":"") + $1 }
        var metadata: [String: Any] = [MemberMention.MetadataKey.notification: userIdString]

        do {
            let data = try JSONSerialization.data(withJSONObject: userMentionsMetadata(), options: .prettyPrinted)
           metadata[MemberMention.MetadataKey.mention] = String(data: data, encoding: String.Encoding.utf8) ?? ""
        } catch {
            print("Error while serializing mention metadata: \(error)")
        }
        return metadata
    }

    func replaceMentionsWithKeys() -> NSAttributedString {
        var newMessage = message
        allMentions.enumerated().forEach { index, mention in
            let attrs = [AutoCompleteItem.attributesKey: mention.userId]
            let replacementText = NSAttributedString(string: mention.userId, attributes: attrs)

            // As the range will change after text replacement
            // so calculating again.
            let range = mentionsInMessage(newMessage)[index].range
            newMessage = newMessage.replacingCharacters(in: range, with: replacementText)
        }
        return newMessage
    }

    private func mentionsInMessage(_ attrString: NSAttributedString) -> [Mention] {
        let range = attrString.string.startIndex..<attrString.string.endIndex
        let messageRange = NSRange(range, in: attrString.string)
        var allMentions: [Mention] = []
        attrString.enumerateAttribute(AutoCompleteItem.attributesKey, in: messageRange, options: []) { (value, keyRange, _) in
            if let value = value as? String, value.starts(with: MessageMentionHandler.mentionSymbol) {
                allMentions.append((value, keyRange))
            }
        }
        return allMentions
    }

    private func userMentionsMetadata() -> [[String: Any]] {
        var mentions: [[String: Any]] = []
        let newMessage = replaceMentionsWithKeys()
        let allMentions = mentionsInMessage(newMessage)
        allMentions.forEach { mention in
            let userId = String(mention.userId.dropFirst(MessageMentionHandler.mentionSymbol.count))
            var mentionMetadata: [String: Any] = ["userId": userId]
            let indices: [Int] = [mention.range.lowerBound, mention.range.upperBound]
            mentionMetadata["indices"] = indices
            mentions.append(mentionMetadata)
        }
        return mentions
    }
}


// For processing on the received side
// TODO: change the name
struct MessageMentionParser {
    typealias Mention = (word: String, range: NSRange)

    let message: String
    let metadata: [String: Any]

    // TODO: remove both these vars
    private let attributesKey = NSAttributedString.Key.init("com.applozicswift.autocompletekey")
    private let mentionSymbol = "@"

    private var allMentions: [Mention] = []


    init(message: String, metadata: [String: Any]) {
        self.message = message
        self.metadata = metadata
        self.allMentions = mentionsInMetadata()
    }

    func containsMentions() -> Bool {
        return !allMentions.isEmpty
    }

    func mentionedUserIds() -> Set<String> {
        return Set(allMentions.map { String($0.word.dropFirst(mentionSymbol.count)) })
    }

    // One issue I can think of is that:
    // When a user sends a text which contains a substring
    // which starts with "@" and the text after that prefix
    // matches with one of the userIds that was mentioned
    // later in the text. In that case we'll replace the first
    // userId and the mentioned with their display names
    // even though, the first one was not a mention.
    //
    // One way to avoid that would be by passing the positions
    // along with the mentioned userIds in the metadata.
    // The problem with that is: it is error prone as different
    // clients might calculate that in different ways.
    // Should the positions be based on utf16 version or
    // on character based like Swift?
    //
    // We can pass the position based on visible chars.
    // Twitter's API also adds the indices(range) in the response.
    // See this: https://developer.twitter.com/en/docs/tweets/data-dictionary/overview/entities-object.html
    //
    // [Done 👆]
    //
    // TODO: take attributes for highlighting the mentions
    //
    // First add a func or var that creates
    // an attributed string which contains userId as attributes
    // in the range. Always use this for processing like in
    // MessageMetadataHandler.
    // Then start the replacement process. Check replacment
    // in handler for understanding. We can move those methods
    // to a single type instead of duplicating.
    //
    // [Done 👆]
    //
    // And when creating attributes make sure even
    // if one of the ranges doesn't point to correct word
    // (that starts with @) then fallback to manual parsing
    // based on the prefix which we've already written
    // just that in that case that bug(highligting incorrect id)
    // might show up. Or we can think of a different backup system

    func replaceUserIds(
        withDisplayNames displayNames: [String: String]
        ) -> NSAttributedString? {

        // TODO: get it from outside
        let defaultAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.font(.normal(size: 14))
        ]
        let colorAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.blue,
            .backgroundColor: UIColor.blue.withAlphaComponent(0.1)
        ]

        let attributedMessage = makeAttributedMessage(
            usingMentions: allMentions,
            andMessage: message,
            attributes: defaultAttributes)
        var newMessage = attributedMessage
        allMentions.enumerated().forEach { index, mention in
            var attrs: [NSAttributedString.Key: Any] = [attributesKey: mention.word]
            attrs.merge(defaultAttributes) { $1 }
            attrs.merge(colorAttributes) { $1 }
            let userId = String(mention.word.dropFirst(mentionSymbol.count))
            let replacementText = NSAttributedString(
                string: mentionSymbol + (displayNames[userId] ?? mention.word),
                attributes: attrs)

            // As the range will change after text replacement
            // so calculating again.
            let range = mentionsInMessage(newMessage)[index].range
            newMessage = newMessage.replacingCharacters(in: range, with: replacementText)
        }
        return newMessage
    }

    private func makeAttributedMessage(
        usingMentions mentions: [Mention],
        andMessage message: String,
        attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {

        var attributedMessage = NSAttributedString(string: message, attributes: attributes)

        // First add attributes at the range
        for mention in mentions {
            let attrs = attributes.merging([attributesKey: mention.word]) { $1 }
            let replacementText = NSAttributedString(string: mention.word, attributes: attrs)
            attributedMessage = attributedMessage.replacingCharacters(in: mention.range, with: replacementText)
        }
        return attributedMessage
    }

    private func mentionsInMetadata() -> [Mention] {
        guard let containsMentions = metadata["AL_MEMBER_MENTION"] as? String  else {
            return []
        }
        let data = containsMentions.data
        let jsonArray = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
        guard let mentionsMetadata = jsonArray as? [[String: Any]] else { return [] }

        var mentions: [Mention] = []
        for i in 0..<mentionsMetadata.count {
            guard let userId = mentionsMetadata[i]["userId"] as? String,
                let indices = mentionsMetadata[i]["indices"] as? [Int],
                indices.count == 2 else {
                    continue
            }
            let range = NSRange(
                location: indices[0],
                length: indices[1]-indices[0])
            // TODO: Verify if the prefix is present at this range or not.
            // If not then break and return empty as the indices are incorrect.
            mentions.append((mentionSymbol+userId, range))
        }
        return mentions
    }

    private func mentionsInMessage(_ attrString: NSAttributedString) -> [Mention] {
        let range = attrString.string.startIndex..<attrString.string.endIndex
        let messageRange = NSRange(range, in: attrString.string)
        var allMentions: [Mention] = []
        attrString.enumerateAttribute(attributesKey, in: messageRange, options: []) { (value, keyRange, _) in
            if let value = value as? String, value.starts(with: mentionSymbol) {
                allMentions.append((value, keyRange))
            }
        }
        return allMentions
    }
}
