//
//  ChatCell.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//


import Foundation
import UIKit
import Kingfisher
import MGSwipeTableCell
import Applozic

public protocol ALKChatViewModelProtocol {
    var avatar: URL? { get }
    var avatarImage: UIImage? { get }
    var avatarGroupImageUrl: String? { get }
    var name: String { get }
    var groupName: String { get }
    var theLastMessage: String? { get }
    var hasUnreadMessages: Bool { get }
    var totalNumberOfUnreadMessages: UInt { get }
    var isGroupChat: Bool { get }
    var contactId: String? { get }
    var channelKey: NSNumber? { get }
    var conversationId: NSNumber! {get set}
    var createdAt: String? { get }
    var messageType: ALKMessageType { get }
}

public enum ALKChatCellAction {
    case delete
    case favorite
    case store
    case call
    case mute
    case unmute
    case block
    case unblock
}

public protocol ALKChatCellDelegate: class {
    func chatCell(cell: ALKChatCell, action: ALKChatCellAction)
}

public final class ALKChatCell: MGSwipeTableCell, Localizable, ChatCell {
    var viewModel: AnyChatItem? {
        didSet {
            configure(viewModel: viewModel)
        }
    }

    enum ConstraintIdentifier: String {
        case iconWidthIdentifier = "iconViewWidth"
    }

    struct Padding {
        struct Email {
            static let top: CGFloat = 4
            static let left: CGFloat = 12
            static let height: CGFloat = 15
            static let width: CGFloat = 24
        }
    }

    public var localizationFileName: String = "Localizable"

    private var avatarImageView: UIImageView = {
        let imv = UIImageView()
        imv.contentMode = .scaleAspectFill
        imv.clipsToBounds = true
        let layer = imv.layer
        layer.cornerRadius = 22.5
        layer.backgroundColor = UIColor.clear.cgColor
        layer.masksToBounds = true
        return imv
    }()

    private var nameLabel: UILabel = {
        let label = UILabel()
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        label.font = Font.bold(size: 14.0).font()
        label.textColor = .text(.black00)
        return label
    }()

    private var locationLabel: UILabel = {
        let label = UILabel()
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        label.font = Font.normal(size: 14.0).font()
        label.textColor = UIColor(netHex: 0x9B9B9B)
        return label
    }()

    private var lineView: UIView = {
        let view = UIView()
        let layer = view.layer
        view.backgroundColor = UIColor.init(red: 200.0/255.0, green: 199.0/255.0, blue: 204.0/255.0, alpha: 0.33)
        return view
    }()

    private var emailIcon: UIImageView = {
        let imv = UIImageView()
        imv.contentMode = .scaleAspectFill
        imv.clipsToBounds = true
        imv.isHidden = true
        imv.image = UIImage(named: "alk_email_icon", in: Bundle.applozic, compatibleWith: nil)
        return imv
    }()

    // MARK: BadgeNumber
    private lazy var badgeNumberView: UIView = {
        let view = UIView(frame: .zero)
        view.setBackgroundColor(.background(.main))
        return view
    }()

    private lazy var badgeNumberLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "0"
        label.textAlignment = .center
        label.setTextColor(.white)
        label.setFont(UIFont.font(.normal(size: 9.0)))

        return label
    }()

    private var timeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.numberOfLines = 1
        label.font = Font.normal(size: 14.0).font()
        label.textColor = UIColor(netHex: 0x9B9B9B)
        label.textAlignment = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft ? .left : .right
        return label
    }()

    private var onlineStatusView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor.onlineGreen()
        return view
    }()

    public weak var chatCellDelegate: ALKChatCellDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupConstraints()
    }

    override public func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)

        guard let _ = viewModel else {
            return
        }

        lineView.backgroundColor = UIColor(netHex: 0xF1F1F1)

        backgroundColor = highlighted ? UIColor.init(netHex: 0xECECEC) : UIColor.white
        contentView.backgroundColor = backgroundColor

        // set backgroundColor of badgeNumber
        badgeNumberView.setBackgroundColor(.background(.main))
    }

    override public func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        guard let _ = viewModel else {
            return
        }

        lineView.backgroundColor = UIColor(netHex: 0xF1F1F1)

        backgroundColor = selected ? UIColor.init(netHex: 0xECECEC) : UIColor.white
        contentView.backgroundColor = backgroundColor

        // set backgroundColor of badgeNumber
        badgeNumberView.setBackgroundColor(.background(.main))
    }

    func configure(viewModel: AnyChatItem?) {
        guard let chatViewModel = viewModel?.base as? ALKChatViewModel else { return }
        nameLabel.text = chatViewModel.name
        locationLabel.text = chatViewModel.messageText
        let placeHolder = placeholderImage(isGroup: chatViewModel.isGroup)
        if let avatarImageURL = chatViewModel.userAvatarURL {
            let resource = ImageResource(downloadURL: avatarImageURL, cacheKey: "\(avatarImageURL)")
            //TODO: Add placeholder(avatarImage property)
            avatarImageView.kf.setImage(with: resource)
        } else {
            avatarImageView.image = placeHolder
        }
        badgeNumberView.isHidden = chatViewModel.unreadCount.isEmpty
        badgeNumberLabel.text = chatViewModel.unreadCount
        timeLabel.text = chatViewModel.createdAt
        onlineStatusView.isHidden = chatViewModel.hideOnlineStatus
        onlineStatusView.isHidden = !chatViewModel.isOnline
        setupLeftSwippableButtons(chatViewModel)
        setupRightSwippableButtons(chatViewModel)

        if chatViewModel.isEmail {
            emailIcon.isHidden = false
            emailIcon.constraint(withIdentifier: ConstraintIdentifier.iconWidthIdentifier.rawValue)?.constant = Padding.Email.width
        } else {
            emailIcon.isHidden = true
            emailIcon.constraint(withIdentifier: ConstraintIdentifier.iconWidthIdentifier.rawValue)?.constant = 0
        }
    }

    private func setupLeftSwippableButtons(_ viewModel: ALKChatViewModel) {
        leftSwipeSettings.transition = .static

        let deleteButton = MGSwipeButton.init(type: .system)
        deleteButton.backgroundColor = UIColor.mainRed()
        deleteButton.setImage(UIImage(named: "icon_delete_white", in: Bundle.applozic, compatibleWith: nil), for: .normal)
        deleteButton.tintColor = .white
        deleteButton.accessibilityIdentifier = "SwippableDeleteIcon"
        deleteButton.frame = CGRect.init(x: 0, y: 0, width: 69, height: 69)
        if viewModel.actions.contains(.delete) {
            let leaveTitle = localizedString(forKey: "DeleteButtonName", withDefaultValue: SystemMessage.ButtonName.Delete, fileName: localizationFileName)
            deleteButton.setTitle(leaveTitle, for: .normal)
        } else if viewModel.actions.contains(.leave) {
            let leaveTitle = localizedString(forKey: "LeaveButtonName", withDefaultValue: SystemMessage.ButtonName.Leave, fileName: localizationFileName)
            deleteButton.setTitle(leaveTitle, for: .normal)
        }
        deleteButton.alignVertically()
        deleteButton.callback = { [weak self] (button) in
            guard let strongSelf = self else {return true}
            strongSelf.chatCellDelegate?.chatCell(cell: strongSelf, action: .delete)
            return true
        }

        let blockButton = MGSwipeButton.init(type: .system)
        blockButton.setImage(UIImage(named: "icon_block", in: Bundle.applozic, compatibleWith: nil), for: .normal)
        blockButton.tintColor = .white
        blockButton.frame = CGRect.init(x: 70, y: 0, width: 69, height: 69)

        var blockAction: ALKChatCellAction = .block
        if viewModel.actions.contains(.block) {
            blockButton.backgroundColor = UIColor(red: 248, green: 139, blue: 139)
            let block = self.localizedString(forKey: "BlockTitle", withDefaultValue: SystemMessage.Block.BlockTitle, fileName: self.localizationFileName)
            blockButton.setTitle(block, for: .normal)
        } else if viewModel.actions.contains(.unblock) {
            blockButton.backgroundColor = UIColor(red: 111, green: 115, blue: 247)
            let unblock = self.localizedString(forKey: "UnblockTitle", withDefaultValue: SystemMessage.Block.UnblockTitle, fileName: self.localizationFileName)
            blockButton.setTitle(unblock, for: .normal)
            blockAction = .unblock
        }
        blockButton.alignVertically()
        blockButton.callback = { [weak self] (button) in
            guard
                let strongSelf = self
                else { return true }
            strongSelf.chatCellDelegate?.chatCell(cell: strongSelf, action: blockAction)
            return true
        }
        self.leftButtons = [deleteButton, blockButton]
    }

    private func setupRightSwippableButtons(_ viewModel: ALKChatViewModel) {
        let muteButton: MGSwipeButton = MGSwipeButton.init(type: .custom)
        muteButton.backgroundColor = UIColor.init(netHex: 0x999999)
        if viewModel.actions.contains(.unmute) {
            muteButton.setImage(UIImage(named: "icon_mute_inactive", in: Bundle.applozic, compatibleWith: nil), for: .normal)
            let unmute = self.localizedString(forKey: "UnmuteButton", withDefaultValue: SystemMessage.Mute.UnmuteButton, fileName: self.localizationFileName)
            muteButton.setTitle(unmute, for: .normal)
        }else if viewModel.actions.contains(.mute) {
            muteButton.setImage(UIImage(named: "icon_mute_active", in: Bundle.applozic, compatibleWith: nil), for: .normal)
            let mute = self.localizedString(forKey: "MuteButton", withDefaultValue: SystemMessage.Mute.MuteButton, fileName: self.localizationFileName)
            muteButton.setTitle(mute, for: .normal)
        }
        muteButton.frame = CGRect.init(x: 0, y: 0, width: 69, height: 69)
        muteButton.alignVertically()
        muteButton.callback = { [weak self] (buttnon) in
            guard let strongSelf = self else {return true}
            if viewModel.actions.contains(.unmute) {
                strongSelf.chatCellDelegate?.chatCell(cell: strongSelf, action: .unmute)
            }else {
                strongSelf.chatCellDelegate?.chatCell(cell: strongSelf, action: .mute)
            }
            return true
        }
        self.rightButtons = [muteButton]
        self.rightSwipeSettings.transition = .static
    }

    //TODO: Handle placeholders passed from outside
    private func placeholderImage(isGroup: Bool) -> UIImage? {
        let placeholder = isGroup ? "groupPlaceholder" : "contactPlaceholder"
        return UIImage(named: placeholder, in: Bundle.applozic, compatibleWith: nil)
    }

    private func setupConstraints() {

        contentView.addViewsForAutolayout(views: [avatarImageView, nameLabel, locationLabel,lineView,badgeNumberView, timeLabel, onlineStatusView,emailIcon])

        // setup constraint of imageProfile
        avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 17.0).isActive = true
        avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15.0).isActive = true
        avatarImageView.heightAnchor.constraint(equalToConstant: 45.0).isActive = true
        avatarImageView.widthAnchor.constraint(equalToConstant: 45.0).isActive = true

        // setup constraint of name
        nameLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor, constant: 2).isActive = true
        nameLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12).isActive = true
        nameLabel.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -5).isActive = true

        emailIcon.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: Padding.Email.top).isActive = true
        emailIcon.heightAnchor.constraint(equalToConstant: Padding.Email.height).isActive = true
        emailIcon.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: Padding.Email.left).isActive = true
        emailIcon.widthAnchor.constraintEqualToAnchor(constant: 0,identifier: ConstraintIdentifier.iconWidthIdentifier.rawValue).isActive = true

        // setup constraint of mood
        locationLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2).isActive = true
        locationLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        locationLabel.leadingAnchor.constraint(equalTo: emailIcon.trailingAnchor, constant: 0).isActive = true
        locationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -68).isActive = true

        // setup constraint of line
        lineView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        lineView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        lineView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        lineView.heightAnchor.constraint(equalToConstant: 1).isActive = true

        // setup constraint of badgeNumber
        badgeNumberView.addViewsForAutolayout(views: [badgeNumberLabel])

        badgeNumberView.trailingAnchor.constraint(lessThanOrEqualTo: nameLabel.leadingAnchor, constant: -5)
        badgeNumberView.topAnchor.constraint(equalTo: avatarImageView.topAnchor, constant: 0).isActive = true
        badgeNumberView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: -12).isActive = true

        badgeNumberLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        badgeNumberLabel.topAnchor.constraint(equalTo: badgeNumberView.topAnchor, constant: 2.0).isActive = true
        badgeNumberLabel.bottomAnchor.constraint(equalTo: badgeNumberView.bottomAnchor, constant: -2.0).isActive = true
        badgeNumberLabel.leadingAnchor.constraint(equalTo: badgeNumberView.leadingAnchor, constant: 2.0).isActive = true
        badgeNumberLabel.trailingAnchor.constraint(equalTo: badgeNumberView.trailingAnchor, constant: -2.0).isActive = true
        badgeNumberLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 11.0).isActive = true
        badgeNumberLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 11.0).isActive = true

        timeLabel.heightAnchor.constraint(equalToConstant: 15).isActive = true
        timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -19).isActive = true
        timeLabel.widthAnchor.constraint(equalToConstant: 70).isActive = true
        timeLabel.topAnchor.constraint(equalTo: nameLabel.topAnchor, constant: 0).isActive  = true

        onlineStatusView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0).isActive = true
        onlineStatusView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        onlineStatusView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0).isActive = true
        onlineStatusView.widthAnchor.constraint(equalToConstant: 6).isActive = true

        // update frame
        contentView.layoutIfNeeded()

        badgeNumberView.layer.cornerRadius = badgeNumberView.frame.size.height / 2.0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private weak var comingSoonDelegate: UIView?

    func setComingSoonDelegate(delegate: UIView) {
        comingSoonDelegate = delegate
    }

    override public func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
    }

    private func getRandomColor() -> UIColor {
        let colors = [0x19A5E4, 0x0EB04B, 0xF3B618, 0xE4E9EC]
        let randomNum = randomInt(min: 0, max: 3)
        return UIColor.init(netHex: colors[randomNum])
    }

    func randomInt(min: Int, max:Int) -> Int {
        return min + Int(arc4random_uniform(UInt32(max - min + 1)))
    }

}
