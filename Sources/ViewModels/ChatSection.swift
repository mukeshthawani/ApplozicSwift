//
//  ChatSection.swift
//  ApplozicSwift
//
//  Created by Mukesh on 01/07/19.
//

import Foundation
import DifferenceKit
import Applozic

struct ChatInfo {
    let message: ALMessage
    let channel: ALChannel?
    let contact: ALContact?
}

struct ChatSection: Section {

    var chatInfo: ChatInfo

    var model: AnyDifferentiable {
        return AnyDifferentiable(chatInfo)
    }

    let message: ALMessage

    var viewModels = [AnyChatItem]()
    weak var controllerContext: UIViewController?

    var chatController: ALKChatCellDelegate? {
        return controllerContext as? ALKChatCellDelegate
    }

    let contact: ALContact?
    let channel: ALChannel?

    init(message: ALMessage,
         channel: ALChannel?,
         contact: ALContact?,
         controllerContext: UIViewController?) {

        self.message = message
        self.contact = contact
        self.channel = channel
        self.controllerContext = controllerContext
        self.chatInfo = ChatInfo(message: message, channel: channel, contact: contact)

        self.viewModels = makeViewModels()
    }

    private func makeViewModels() -> [AnyChatItem] {
        var items: [AnyChatItem] = []

        if let channel = channel {
            let chatItem = ALKChatViewModel(
                message: message,
                channel: channel,
                isMember: channel.isMember())
            items.append(AnyChatItem(chatItem))
        } else if let contact = contact {
            let chatItem = ALKChatViewModel(message: message, contact: contact)
            items.append(AnyChatItem(chatItem))
        } else {
            print("Not a channel or contact")
        }
        return items
    }

    func cellForRow(_ viewModel: AnyChatItem, tableView: UITableView, indexPath: IndexPath) -> ChatCell {
        guard let cell = tableView.dequeueReusableCell(
                withIdentifier: viewModel.reuseIdentifier,
                for: indexPath) as? ALKChatCell else {
                    // Pass empty cell
                    return SampleTableViewCell()
        }
        cell.viewModel = viewModel
        cell.chatCellDelegate = chatController
        return cell
    }
}

extension ALMessage: Differentiable {

    public var differenceIdentifier: String {
        return identifier
    }

    public func isContentEqual(to source: ALMessage) -> Bool {
        return self.identifier == source.identifier
            && self.name == source.name
            && self.avatarImage == source.avatarImage
            && self.avatarGroupImageUrl == source.avatarGroupImageUrl
            && self.avatar == source.avatar
    }
}

extension ALChannel {

    func isMember(_ channelService: ALChannelService = ALChannelService()) -> Bool {
        return !channelService.isChannelLeft(key)
    }

    func isContentEqual(to source: ALChannel) -> Bool {
        return self.isNotificationMuted() == source.isNotificationMuted()
            && self.unreadCount == source.unreadCount
    }
}

extension ALContact {
    func isContentEqual(to source: ALContact) -> Bool {
        return self.connected == source.connected
            && self.isNotificationMuted() == source.isNotificationMuted()
            && self.block == source.block
            && self.unreadCount == source.unreadCount
    }
}

extension ChatInfo: Differentiable {
    var differenceIdentifier: String {
        return message.identifier
    }

    func isContentEqual(to source: ChatInfo) -> Bool {
        let isMessageEqual = source.message.isContentEqual(to: source.message)
        var isChannelEqual = true
        if let channel = channel, let sourceChannel = source.channel {
            isChannelEqual = channel.isContentEqual(to: sourceChannel)
        }
        var isContactEqual = true
        if let contact = contact, let sourceContact = source.contact {
            isContactEqual = contact.isContentEqual(to: sourceContact)
        }
        return isMessageEqual && isChannelEqual && isContactEqual
    }
}
