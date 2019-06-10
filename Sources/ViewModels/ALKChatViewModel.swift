//
//  ALKChatViewModel.swift
//  ApplozicSwift
//
//  Created by Mukesh on 27/06/19.
//

import Foundation
import Applozic
import DifferenceKit

struct ALKChatViewModel: ChatItem {

    enum Action: Equatable {
        case mute
        case unmute
        case delete
        case leave
        case block
        case unblock
    }

    var reuseIdentifier: String {
        return "cell"
    }

    // Inputs
    private var message: ALMessage
    private var contact: ALContact?
    private var channel: ALChannel?
    private var isMember: Bool

    // Outputs

    var name: String {
        return message.isGroupChat ? message.groupName:message.name
    }

    var messageText: String {
        return message.theLastMessage ?? ""
    }

    var isGroup: Bool {
        return message.isGroupChat
    }

    var userAvatarURL: URL? {
        if message.avatarImage != nil {
            if let imgStr = message.avatarGroupImageUrl,
                let imgURL = URL(string: imgStr) {
                return imgURL
            }
        }else if let avatar = message.avatar {
            return avatar
        }
        return nil
    }

    var unreadCount: String {
        let unreadMsgCount = Int(message.totalNumberOfUnreadMessages)
        let numberText: String = (unreadMsgCount < 1000 ? "\(unreadMsgCount)" : "999+")
        let isHidden = unreadMsgCount < 1
        return isHidden ? "":numberText
    }

    var createdAt: String? {
        return message.createdAt
    }

    var isEmail: Bool {
        return message.messageType == .email
    }

    var isOnline: Bool {
        guard !isGroup, let contact = contact else { return false }
        return contact.connected
    }

    var hideOnlineStatus: Bool {
        guard !isGroup, let contact = contact else { return true }
        return contact.block || contact.blockBy || contact.isDeleted
    }

    var actions: [Action] {
        var actions: [Action] = []
        actions.append(isConversationMuted ? .unmute:.mute)
        if isGroup {
            actions.append(isMember ? .leave:.delete)
        } else if let contact = contact {
            actions.append(.delete)
            actions.append(contact.block ? .unblock:.block)
        }
        return actions
    }

    // Internal

    private var isConversationMuted: Bool {
        if isGroup, let channel = channel {
            return channel.isNotificationMuted()
        } else if let contact = contact {
            return contact.isNotificationMuted()
        }
        return false
    }

    private init(
        message: ALMessage,
        contact: ALContact?,
        channel: ALChannel?,
        isMember: Bool
        ) {

        self.message = message
        self.contact = contact
        self.channel = channel
        self.isMember = isMember
    }
}

extension ALKChatViewModel {
    init(message: ALMessage, contact: ALContact) {
        self.init(message: message, contact: contact, channel: nil, isMember: false)
    }

    init(message: ALMessage, channel: ALChannel, isMember: Bool) {
        self.init(message: message, contact: nil, channel: channel, isMember: isMember)
    }
}

extension ALKChatViewModel: Differentiable {

    var differenceIdentifier: String {
        return message.identifier
    }

    func isContentEqual(to source: ALKChatViewModel) -> Bool {
        return source.userAvatarURL == userAvatarURL
            && source.name == name
            && source.unreadCount == unreadCount
            && source.isConversationMuted == isConversationMuted
            && source.isOnline == isOnline
            && source.actions == actions
    }
}
