//
//  ConversationViewController.swift
//  
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import Applozic

public final class ALKConversationViewController: ALKBaseViewController {

    public var viewModel: ALKConversationViewModel!
    private var isFirstTime = true
    private var bottomConstraint: NSLayoutConstraint?
    private var leftMoreBarConstraint: NSLayoutConstraint?
    private var typingNoticeViewHeighConstaint: NSLayoutConstraint?
    private var isJustSent: Bool = false
    let audioPlayer = ALKAudioPlayer()

    fileprivate let moreBar: ALKMoreBar = ALKMoreBar(frame: .zero)
    fileprivate let typingNoticeView = TypingNotice()
    fileprivate var alMqttConversationService: ALMQTTConversationService!
    fileprivate let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)

    fileprivate var keyboardSize: CGRect?

    let tableView : UITableView = {
        let tv = UITableView(frame: .zero, style: .grouped)
        tv.separatorStyle   = .none
        tv.allowsSelection  = false
        tv.backgroundColor  = UIColor.white
        tv.clipsToBounds    = true
        tv.keyboardDismissMode = UIScrollViewKeyboardDismissMode.onDrag
        return tv
    }()

    fileprivate let titleButton : UIButton = {
        let titleButton = UIButton(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        titleButton.setTitleColor(UIColor.black, for: .normal)
        titleButton.titleLabel?.font  = UIFont.boldSystemFont(ofSize: 17.0)
        return titleButton
    }()

    let chatBar: ALKChatBar = ALKChatBar(frame: .zero)

    let unreadScrollButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.lightText
        let image = UIImage(named: "scrollDown", in: Bundle.applozic, compatibleWith: nil)
        button.setImage(image, for: .normal)
        button.layer.cornerRadius = 15
        return button
    }()

    required public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func addObserver() {
            NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardWillShow, object: nil, queue: nil, using: { [weak self]
            notification in
            print("keyboard will show")
            guard let weakSelf = self else {return}

            if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {

                weakSelf.keyboardSize = keyboardSize

                let tableView = weakSelf.tableView
                let isAtBotom = tableView.isAtBottom
                let isJustSent = weakSelf.isJustSent

                let view = weakSelf.view
                _ = weakSelf.navigationController


                var h = CGFloat(0)
                h = keyboardSize.height-h

                let newH = -1*h
                if weakSelf.bottomConstraint?.constant == newH {return}

                weakSelf.bottomConstraint?.constant = newH

                let duration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.05

                UIView.animate(withDuration: duration, animations: {
                    view?.layoutIfNeeded()
                }, completion: { (_) in
                    print("animated ")
                    if isAtBotom == true && isJustSent == false {
                        tableView.scrollToBottomByOfset(animated: false)
                    }
                })
            }
        })


        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardWillHide, object: nil, queue: nil, using: {[weak self]
            (notification) in

            guard let weakSelf = self else {return}
            let view = weakSelf.view

            weakSelf.bottomConstraint?.constant = 0

            let duration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.05

            UIView.animate(withDuration: duration, animations: {
                view?.layoutIfNeeded()
            }, completion: { (_) in
                guard let vm = weakSelf.viewModel else { return }
                vm.sendKeyboardDoneTyping()
            })

        })

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "newMessageNotification"), object: nil, queue: nil, using: { [weak self]
            notification in
            guard let weakSelf = self else { return }
            let msgArray = notification.object as? [ALMessage]
            print("new notification received: ", msgArray?.first?.message as Any, msgArray?.count)
            guard let list = notification.object as? [Any], !list.isEmpty, weakSelf.isViewLoaded, weakSelf.viewModel != nil else { return }
            weakSelf.viewModel.addMessagesToList(list)
//            weakSelf.handlePushNotification = false
        })

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "notificationIndividualChat"), object: nil, queue: nil, using: {[weak self]
            notification in
            print("notification individual chat received")
        })

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "report_DELIVERED"), object: nil, queue: nil, using: {[weak self]
            notification in
            guard let weakSelf = self, let key = notification.object as? String else { return }
            weakSelf.viewModel.updateDeliveryReport(messageKey: key, status: Int32(DELIVERED.rawValue))
            print("report delievered notification received")
        })

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "report_DELIVERED_READ"), object: nil, queue: nil, using: {[weak self]
            notification in
            guard let weakSelf = self, let key = notification.object as? String else { return }
            weakSelf.viewModel.updateDeliveryReport(messageKey: key, status: Int32(DELIVERED_AND_READ.rawValue))
            print("report delievered and read notification received")
        })

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "report_CONVERSATION_DELIVERED_READ"), object: nil, queue: nil, using: {[weak self]
            notification in
            guard let weakSelf = self, let key = notification.object as? String else { return }
            weakSelf.viewModel.updateStatusReportForConversation(contactId: key, status: Int32(DELIVERED_AND_READ.rawValue))
            print("report conversation delievered and read notification received")
        })

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "UPDATE_MESSAGE_SEND_STATUS"), object: nil, queue: nil, using: {[weak self]
            notification in
            print("Message sent notification received")
            guard let weakSelf = self, let message = notification.object as? ALMessage else { return }
            weakSelf.viewModel.updateSendStatus(message: message)
        })

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "USER_DETAILS_UPDATE_CALL"), object: nil, queue: nil, using: {[weak self] notification in
            NSLog("update user detail notification received")
            guard let weakSelf = self, let userId = notification.object as? String else { return }
            print("update user detail")
            ALUserService.updateUserDetail(userId, withCompletion: {
                userDetail in
                guard let detail = userDetail else { return }
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "USER_DETAIL_OTHER_VC"), object: detail)
                guard !weakSelf.viewModel.isGroup && userId == weakSelf.viewModel.contactId else { return }
                weakSelf.titleButton.setTitle(detail.getDisplayName(), for: .normal)
            })
        })

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "UPDATE_CHANNEL_NAME"), object: nil, queue: nil, using: {[weak self] notification in
            NSLog("update group name notification received")
            guard let weakSelf = self else { return }
            print("update group detail")
            guard weakSelf.viewModel.isGroup else { return }
            let alChannelService = ALChannelService()
            guard let key = weakSelf.viewModel.channelKey, let channel = alChannelService.getChannelByKey(key), let name = channel.name else { return }
            weakSelf.titleButton.setTitle(name, for: .normal)
            })
    }

    override func removeObserver() {

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "newMessageNotification"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "notificationIndividualChat"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "report_DELIVERED"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "report_DELIVERED_READ"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "report_CONVERSATION_DELIVERED_READ"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "UPDATE_MESSAGE_SEND_STATUS"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "USER_DETAILS_UPDATE_CALL"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "UPDATE_CHANNEL_NAME"), object: nil)
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
            tableView.semanticContentAttribute = UISemanticContentAttribute.forceRightToLeft
        }
        view.backgroundColor = UIColor.white
        self.edgesForExtendedLayout = []
        activityIndicator.center = CGPoint(x: view.bounds.size.width/2, y: view.bounds.size.height/2)
        activityIndicator.color = UIColor.lightGray
        tableView.addSubview(activityIndicator)
        addRefreshButton()
        if let listVC = self.navigationController?.viewControllers.first as? ALKConversationListViewController, !listVC.isViewLoaded {
            viewModel.individualLaunch = true
        } else {
            viewModel.individualLaunch = false
        }
        alMqttConversationService = ALMQTTConversationService.sharedInstance()
        if viewModel.individualLaunch {
            alMqttConversationService.mqttConversationDelegate = self
            alMqttConversationService.subscribeToConversation()
        }

        if self.viewModel.isGroupConversation() == true {
            self.setTypingNotiDisplayName(displayName: "Somebody")
        } else {
            self.setTypingNotiDisplayName(displayName: self.title ?? "")
        }

        viewModel.delegate = self
        viewModel.prepareController()
        if self.isFirstTime {
            self.setupNavigation()
        } else {
            tableView.reloadData()
        }
        subscribingChannel()
        print("id: ", viewModel.messageModels.first?.contactId as Any)
    }

    override public func viewDidAppear(_ animated: Bool) {
        NSLog("view loaded first time \(isFirstTime)")
        setupView()
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        ALUserDefaultsHandler.setDebugLogsRequire(true)
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if self.isFirstTime && tableView.isCellVisible(section: 0, row: 0) {
            self.tableView.scrollToBottomByOfset(animated: false)
            isFirstTime = false
        }
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAudioPlayer()
        chatBar.stopRecording()
        if viewModel.individualLaunch {
            if let _ = alMqttConversationService {
                alMqttConversationService.unsubscribeToConversation()
            }
        }
        unsubscribingChannel()
    }

    override func backTapped() {
        print("back tapped")
        self.viewModel.sendKeyboardDoneTyping()
        _ = navigationController?.popToRootViewController(animated: true)
    }

    func setupView() {

        unreadScrollButton.isHidden = true
        unreadScrollButton.addTarget(self, action: #selector(unreadScrollDownAction(_:)), for: .touchUpInside)

        view.addViewsForAutolayout(views: [tableView,moreBar,chatBar,typingNoticeView, unreadScrollButton])

        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: typingNoticeView.topAnchor).isActive = true

        typingNoticeViewHeighConstaint = typingNoticeView.heightAnchor.constraint(equalToConstant: 0)
        typingNoticeViewHeighConstaint?.isActive = true

        typingNoticeView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8).isActive = true
        typingNoticeView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12).isActive = true
        typingNoticeView.bottomAnchor.constraint(equalTo: chatBar.topAnchor).isActive = true

        chatBar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        chatBar.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        bottomConstraint = chatBar.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        bottomConstraint?.isActive = true

        unreadScrollButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        unreadScrollButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        unreadScrollButton.trailingAnchor.constraint(equalTo: tableView.trailingAnchor, constant: -10).isActive = true
        unreadScrollButton.bottomAnchor.constraint(equalTo: chatBar.topAnchor, constant: -10).isActive = true

        leftMoreBarConstraint = moreBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 56)
        leftMoreBarConstraint?.isActive = true
        prepareTable()
        prepareMoreBar()
        prepareChatBar()

    }

    private func setupNavigation() {

        titleButton.setTitle(self.title, for: .normal)
        titleButton.addTarget(self, action: #selector(showParticipantListChat), for: .touchUpInside)
        self.navigationItem.titleView = titleButton
    }

    private func prepareTable() {

        let gesture = UITapGestureRecognizer(target: self, action: #selector(tableTapped(gesture:)))
        gesture.numberOfTapsRequired = 1
        tableView.addGestureRecognizer(gesture)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        tableView.sectionHeaderHeight = 0.0
        tableView.sectionFooterHeight = 0.0
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: tableView.bounds.size.width, height: 0.1))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: tableView.bounds.size.width, height: 8))

        self.automaticallyAdjustsScrollViewInsets = false

        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentBehavior.never
        }
        tableView.estimatedRowHeight = 0

        tableView.register(ALKMyMessageCell.self)
        tableView.register(ALKFriendMessageCell.self)
        tableView.register(ALKMyPhotoPortalCell.self)
        tableView.register(ALKMyPhotoLandscapeCell.self)

        tableView.register(ALKFriendPhotoPortalCell.self)
        tableView.register(ALKFriendPhotoLandscapeCell.self)

        tableView.register(ALKMyVoiceCell.self)
        tableView.register(ALKFriendVoiceCell.self)
        tableView.register(ALKInformationCell.self)
        tableView.register(ALKMyLocationCell.self)
        tableView.register(ALKFriendLocationCell.self)
        tableView.register(ALKMyVideoCell.self)
        tableView.register(ALKFriendVideoCell.self)
    }


    private func prepareMoreBar() {

        moreBar.bottomAnchor.constraint(equalTo: chatBar.topAnchor).isActive = true
        moreBar.isHidden = true
        moreBar.setHandleAction { [weak self] (actionType) in
            self?.hideMoreBar()
        }
    }


    private func prepareChatBar() {
        chatBar.accessibilityIdentifier = "chatBar"
        chatBar.setComingSoonDelegate(delegate: self.view)
        chatBar.action = { [weak self] (action) in

            guard let weakSelf = self else {
                return
            }

            if case .more(_) = action {

                if weakSelf.moreBar.isHidden == true {
                    weakSelf.showMoreBar()
                } else {
                    weakSelf.hideMoreBar()
                }

                return
            }

            weakSelf.hideMoreBar()

            switch action {

            case .sendText(let button, let message):

                if message.characters.count < 1 {
                    return
                }

                button.isUserInteractionEnabled = false
                weakSelf.viewModel.sendKeyboardDoneTyping()

                weakSelf.isJustSent = true

                weakSelf.chatBar.clear()

                NSLog("Sent: ", message)

                weakSelf.viewModel.send(message: message)
                button.isUserInteractionEnabled = true
            case .chatBarTextChange(_):

                weakSelf.viewModel.sendKeyboardBeginTyping()

                UIView.animate(withDuration: 0.05, animations: { () in
                    weakSelf.view.layoutIfNeeded()
                }, completion: { [weak self] (_) in

                    guard let weakSelf = self else {
                        return
                    }

                    if weakSelf.tableView.isAtBottom == true && weakSelf.isJustSent == false {
                        weakSelf.tableView.scrollToBottomByOfset(animated: false)
                    }
                })
            case .sendPhoto(let button, let image):
                print("Image call done")
                weakSelf.isJustSent = true

                let (message, indexPath) =  weakSelf.viewModel.send(photo: image)
                guard let _ = message, let newIndexPath = indexPath else { return }
                weakSelf.tableView.beginUpdates()
                weakSelf.tableView.insertSections(IndexSet(integer: newIndexPath.section), with: .automatic)
                weakSelf.tableView.endUpdates()
                weakSelf.tableView.scrollToBottom(animated: false)

                guard let cell = weakSelf.tableView.cellForRow(at: newIndexPath) as? ALKMyPhotoPortalCell else { return }
                guard ALDataNetworkConnection.checkDataNetworkAvailable() else {
                    let notificationView = ALNotificationView()
                    notificationView.noDataConnectionNotificationView()
                    return
                }
                weakSelf.viewModel.uploadImage(view: cell, indexPath: newIndexPath)

                button.isUserInteractionEnabled = true
                button.isUserInteractionEnabled = true

            case .sendVoice(let voice):
                weakSelf.viewModel.send(voiceMessage: voice as Data)
                break;

            case .startVideoRecord():
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: {
                        granted in
                        DispatchQueue.main.async {
                            if granted {
                                let imagePicker = UIImagePickerController()
                                imagePicker.delegate = self
                                imagePicker.allowsEditing = true;
                                imagePicker.sourceType = .camera
                                imagePicker.mediaTypes = [kUTTypeMovie as String]
                                UIViewController.topViewController()?.present(imagePicker, animated: false, completion: nil)
                            } else {
                                ALUtilityClass.permissionPopUp(withMessage: "Enable Camera Permission", andViewController: self)
                            }
                        }
                    })
                } else {
                    ALUtilityClass.showAlertMessage(NSLocalizedString("CameraNotAvailableMessage", value: "Camera is not Available !!!", comment: ""), andTitle: NSLocalizedString("CameraNotAvailableTitle", value: "OOPS !!!", comment: ""))
                }
            case .showImagePicker():
                let storyboard = UIStoryboard.name(storyboard: UIStoryboard.Storyboard.picker, bundle: Bundle.applozic)
                if let vc = storyboard.instantiateViewController(withIdentifier: "CustomPickerNavigationViewController") as? ALKBaseNavigationViewController {
                    guard let firstVC = vc.viewControllers.first else {return}
                    let cameraView = firstVC as! ALKCustomPickerViewController
                    cameraView.delegate = self
                    UIViewController.topViewController()?.present(vc, animated: false, completion: nil)
                }
            case .showLocation():
                let storyboard = UIStoryboard.name(storyboard: UIStoryboard.Storyboard.MapView, bundle: Bundle.applozic)

                guard let nav = storyboard.instantiateInitialViewController() as? UINavigationController else { return }
                guard let mapViewVC = nav.viewControllers.first as? ALKMapViewController else { return }
                mapViewVC.delegate = self
                self?.present(nav, animated: true, completion: {})
            default:
                print("Not available")
            }
        }
    }

    //MARK: public Control Typing notification
    func setTypingNotiDisplayName(displayName:String)
    {
        typingNoticeView.setDisplayName(displayName: displayName)
    }

    func tableTapped(gesture: UITapGestureRecognizer) {
        hideMoreBar()
        view.endEditing(true)
    }

    private func showMoreBar() {

        self.moreBar.isHidden = false
        self.leftMoreBarConstraint?.constant = 0

        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] () in
            self?.view.layoutIfNeeded()
            }, completion: { [weak self] (finished) in

                guard let strongSelf = self else {return}

                strongSelf.view.bringSubview(toFront: strongSelf.moreBar)
                strongSelf.view.sendSubview(toBack: strongSelf.tableView)
        })

    }

    private func hideMoreBar() {

        if self.leftMoreBarConstraint?.constant == 0 {

            self.leftMoreBarConstraint?.constant = 56

            UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] () in
                self?.view.layoutIfNeeded()
                }, completion: { [weak self] (finished) in
                    self?.moreBar.isHidden = true
            })

        }

    }

    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        UIMenuController.shared.setMenuVisible(false, animated: true)
        hideMoreBar()
    }

    // Called from the parent VC
    func showTypingLabel(status: Bool, userId: String) {
        typingNoticeViewHeighConstaint?.constant = status ? 30:0
        view.layoutIfNeeded()
        if tableView.isAtBottom {
            tableView.scrollToBottomByOfset(animated: false)
        }
    }

    func sync(message: ALMessage) {
        viewModel.sync(message: message)
    }

    @objc private func showParticipantListChat() {
        if viewModel.isGroupConversation() {
            let storyboard = UIStoryboard.name(storyboard: UIStoryboard.Storyboard.createGroupChat, bundle: Bundle.applozic)
            if let vc = storyboard.instantiateViewController(withIdentifier: "ALKCreateGroupViewController") as? ALKCreateGroupViewController {

                if viewModel.groupProfileImgUrl().isEmpty {
                    vc.setCurrentGroupSelected(groupName: viewModel.groupName(),groupProfileImg:nil, groupSelected: viewModel.friends(), delegate: self)
                } else {
                    vc.setCurrentGroupSelected(groupName: viewModel.groupName(),groupProfileImg:viewModel.groupProfileImgUrl(), groupSelected: viewModel.friends(), delegate: self)
                }
                vc.addContactMode = .existingChat
                navigationController?.pushViewController(vc, animated: true)
            }
        }
    }

    func updateDeliveryReport(messageKey: String?, contactId: String?, status: Int32?) {
        guard let key = messageKey, let status = status else {
            return
        }
        viewModel.updateDeliveryReport(messageKey: key, status: status)
    }

    func updateStatusReport(contactId: String?, status: Int32?) {
        guard let id = contactId, let status = status else {
            return
        }
        viewModel.updateStatusReportForConversation(contactId: id, status: status)
    }

    private func subscribingChannel() {
        let channelService = ALChannelService()
        if viewModel.isGroup, let groupId = viewModel.channelKey, !channelService.isChannelLeft(groupId) && !ALChannelService.isChannelDeleted(groupId) {
            self.alMqttConversationService.subscribe(toChannelConversation: groupId)
        } else if !viewModel.isGroup {
            self.alMqttConversationService.subscribe(toChannelConversation: nil)
        }
        if viewModel.isGroup, ALUserDefaultsHandler.isUserLoggedInUserSubscribedMQTT(){
            self.alMqttConversationService.unSubscribe(toChannelConversation: nil)
        }

    }

    private func unsubscribingChannel() {
        self.alMqttConversationService.sendTypingStatus(ALUserDefaultsHandler.getApplicationKey(), userID: viewModel.contactId, andChannelKey: viewModel.channelKey, typing: false)
        self.alMqttConversationService.unSubscribe(toChannelConversation: viewModel.channelKey)
    }


    func unreadScrollDownAction(_ sender: UIButton) {
        tableView.scrollToBottom()
        unreadScrollButton.isHidden = true
    }
    
}

extension ALKConversationViewController: ALKConversationViewModelDelegate {

    public func loadingStarted() {
        activityIndicator.startAnimating()
    }

    public func loadingFinished(error: Error?) {
        activityIndicator.stopAnimating()
        tableView.reloadData()
        print("loading finished")
        DispatchQueue.main.async {
            if self.viewModel.isFirstTime {
                self.tableView.scrollToBottom(animated: false)
                self.viewModel.isFirstTime = false
            }
        }
        viewModel.markConversationRead()
    }

    public func messageUpdated() {
        if activityIndicator.isAnimating {
            activityIndicator.stopAnimating()
        }
        tableView.reloadData()
    }

    public func updateMessageAt(indexPath: IndexPath) {
        DispatchQueue.main.async {
            self.tableView.reloadSections(IndexSet(integer: indexPath.section), with: .none)
        }
    }

    public func newMessagesAdded() {
        tableView.reloadData()
        if tableView.isCellVisible(section: viewModel.messageModels.count-2, row: 0) {
            tableView.scrollToBottom()
        } else {
            unreadScrollButton.isHidden = false
        }
        guard self.isViewLoaded && self.view.window != nil else {
            return
        }
        viewModel.markConversationRead()
    }

    public func messageSent(at indexPath: IndexPath) {
        DispatchQueue.main.async {
            NSLog("current indexpath: %i and tableview section %i", indexPath.section, self.tableView.numberOfSections)
            guard indexPath.section >= self.tableView.numberOfSections else {
                NSLog("rejected indexpath: %i and tableview and section %i", indexPath.section, self.tableView.numberOfSections)
                return
            }
            self.tableView.beginUpdates()
            self.tableView.insertSections(IndexSet(integer: indexPath.section), with: .automatic)
            self.tableView.endUpdates()
            self.tableView.scrollToBottom(animated: false)
        }
    }

    public func updateDisplay(name: String) {
        self.title = name
        titleButton.setTitle(name, for: .normal)
    }

    func addRefreshButton() {
        let refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(ALKConversationViewController.refreshButtonAction(_:)))
        self.navigationItem.rightBarButtonItem = refreshButton
    }

    func refreshButtonAction(_ selector: UIBarButtonItem) {
        viewModel.refresh()
    }

}

extension ALKConversationViewController: ALKCreateGroupChatAddFriendProtocol {

    func createGroupGetFriendInGroupList(friendsSelected: [ALKFriendViewModel], groupName: String, groupImgUrl: String, friendsAdded: [ALKFriendViewModel]) {
        if viewModel.isGroupConversation() {
            if !groupName.isEmpty {
                self.title = groupName
                titleButton.setTitle(self.title, for: .normal)
            }
            
            viewModel.updateGroup(groupName: groupName, groupImage: groupImgUrl, friendsAdded: friendsAdded)

            if let titleButton = navigationItem.titleView as? UIButton {
                titleButton.setTitle(title, for: .normal)
            }

            let _ = navigationController?.popToViewController(self, animated: true)
        }
    }
}

extension ALKConversationViewController: ALKShareLocationViewControllerDelegate {
    func locationDidSelected(geocode: Geocode, image: UIImage) {
        let (message, indexPath) = viewModel.add(geocode: geocode)
        guard let newMessage = message, let newIndexPath = indexPath else {
            return
        }
        self.tableView.beginUpdates()
        self.tableView.insertSections(IndexSet(integer: (newIndexPath.section)), with: .automatic)
        self.tableView.endUpdates()
        
        // Not scrolling down without the delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.tableView.scrollToBottom(animated: false)
        }
        viewModel.sendGeocode(message: newMessage, indexPath: newIndexPath)
    }
}


extension ALKConversationViewController: ALKLocationCellDelegate {
    func displayLocation(location: ALKLocationPreviewViewModel) {
        let latLonString = String(format: "%f,%f", location.coordinate.latitude, location.coordinate.longitude)
        let locationString = String(format: "https://maps.google.com/maps?q=loc:%@", latLonString)
        guard let locationUrl = URL(string: locationString) else { return }
        UIApplication.shared.openURL(locationUrl)

    }
}

extension ALKConversationViewController: ALKAudioPlayerProtocol, ALKVoiceCellProtocol {

    func reloadVoiceCell() {
        for cell in tableView.visibleCells {
            guard let indexPath = tableView.indexPath(for: cell) else {return}
            if let message = viewModel.messageForRow(indexPath: indexPath) {
                if message.messageType == .voice && message.identifier == audioPlayer.getCurrentAudioTrack(){
                    print("voice cell reloaded with row: ", indexPath.row, indexPath.section)
                    tableView.reloadSections([indexPath.section], with: .none)
                    break
                }
            }
        }
    }

    //MAKR: Voice and Audio Delegate
    func playAudioPress(identifier: String) {
        DispatchQueue.main.async { [weak self] in
            NSLog("play audio pressed")
            guard let weakSelf = self else { return }

            //if we have previously play audio, stop it first
            if !weakSelf.audioPlayer.getCurrentAudioTrack().isEmpty && weakSelf.audioPlayer.getCurrentAudioTrack() != identifier {
                //pause
                NSLog("already playing, change it to pause")
                guard var lastMessage =  weakSelf.viewModel.messageForRow(identifier: weakSelf.audioPlayer.getCurrentAudioTrack()) else {return}

                if Int(lastMessage.voiceCurrentDuration) > 0 {
                    lastMessage.voiceCurrentState = .pause
                    lastMessage.voiceCurrentDuration = weakSelf.audioPlayer.secLeft
                } else {
                    lastMessage.voiceCurrentDuration = lastMessage.voiceTotalDuration
                    lastMessage.voiceCurrentState = .stop
                }
                weakSelf.audioPlayer.pauseAudio()
            }
            NSLog("now it will be played")
            //now play
            guard var currentVoice =  weakSelf.viewModel.messageForRow(identifier: identifier) else {return}
            if currentVoice.voiceCurrentState == .playing {
                currentVoice.voiceCurrentState = .pause
                currentVoice.voiceCurrentDuration = weakSelf.audioPlayer.secLeft
                weakSelf.audioPlayer.pauseAudio()
                weakSelf.tableView.reloadData()
            }
            else {
                NSLog("reset time to total duration")
                //reset time to total duration
                if currentVoice.voiceCurrentState  == .stop || currentVoice.voiceCurrentDuration < 1 {
                    currentVoice.voiceCurrentDuration = currentVoice.voiceTotalDuration
                }

                if let data = currentVoice.voiceData {
                    let voice = data as NSData
                    //start playing
                    NSLog("Start playing")
                    weakSelf.audioPlayer.setAudioFile(data: voice, delegate: weakSelf, playFrom: currentVoice.voiceCurrentDuration,lastPlayTrack:currentVoice.identifier)
                    currentVoice.voiceCurrentState = .playing
                    weakSelf.tableView.reloadData()
                }
            }
        }

    }

    func audioPlaying(maxDuratation: CGFloat, atSec: CGFloat,lastPlayTrack:String) {

        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else { return }
            guard var currentVoice =  weakSelf.viewModel.messageForRow(identifier: lastPlayTrack) else {return}
            if currentVoice.messageType == .voice {

                if currentVoice.identifier == lastPlayTrack {
                    if atSec <= 0 {
                        currentVoice.voiceCurrentState = .stop
                        currentVoice.voiceCurrentDuration = 0
                    } else {
                        currentVoice.voiceCurrentState = .playing
                        currentVoice.voiceCurrentDuration = atSec
                    }
                }
                print("audio playing id: ", currentVoice.identifier)
                weakSelf.reloadVoiceCell()
            }
        }
    }

    func audioStop(maxDuratation: CGFloat,lastPlayTrack:String) {

        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else { return }

            guard var currentVoice =  weakSelf.viewModel.messageForRow(identifier: lastPlayTrack) else {return}
            if currentVoice.messageType == .voice {
                if currentVoice.identifier == lastPlayTrack {
                    currentVoice.voiceCurrentState = .stop
                    currentVoice.voiceCurrentDuration = 0.0
                }
            }
            weakSelf.reloadVoiceCell()
        }
    }

    func stopAudioPlayer(){
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else { return }
            if var lastMessage = weakSelf.viewModel.messageForRow(identifier: weakSelf.audioPlayer.getCurrentAudioTrack()) {
                
                if lastMessage.voiceCurrentState == .playing {
                    weakSelf.audioPlayer.pauseAudio()
                    lastMessage.voiceCurrentState = .pause
                    weakSelf.reloadVoiceCell()
                }
            }
        }
    }
}

extension ALKConversationViewController: ALMQTTConversationDelegate {

    public func mqttDidConnected() {
        print("MQTT did connected")
    }


    public func syncCall(_ alMessage: ALMessage!, andMessageList messageArray: NSMutableArray!) {
        print("sync call1 ", messageArray)
        guard let message = alMessage else { return }
        sync(message: message)
    }

    public func delivered(_ messageKey: String!, contactId: String!, withStatus status: Int32) {
        updateDeliveryReport(messageKey: messageKey, contactId: contactId, status: status)
    }

    public func updateStatus(forContact contactId: String!, withStatus status: Int32) {
        updateStatusReport(contactId: contactId, status: status)
    }

    public func updateTypingStatus(_ applicationKey: String!, userId: String!, status: Bool) {
        print("Typing status is", status)
        guard viewModel.contactId == userId || viewModel.channelKey != nil else {
            return
        }
        print("Contact id matched")
        showTypingLabel(status: status, userId: userId)

    }

    public func updateLastSeen(atStatus alUserDetail: ALUserDetail!) {
        print("Last seen updated")
    }

    public func mqttConnectionClosed() {
        NSLog("MQTT connection closed")
    }

    public func reloadData(forUserBlockNotification userId: String!, andBlockFlag flag: Bool) {
        print("reload data")
    }

    public func updateUserDetail(_ userId: String!) {
        guard let userId = userId else { return }
        print("update user detail")

        ALUserService.updateUserDetail(userId, withCompletion: {
            userDetail in
            guard let detail = userDetail else { return }
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "USER_DETAIL_OTHER_VC"), object: detail)
            guard !self.viewModel.isGroup && userId == self.viewModel.contactId else { return }
            self.titleButton.setTitle(detail.getDisplayName(), for: .normal)
        })
    }
}

extension ALKConversationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {

        // Video attachment
        if let mediaType = info[UIImagePickerControllerMediaType] as? String, mediaType == "public.movie" {
            guard let url = info[UIImagePickerControllerMediaURL] as? URL else { return }
            print("video path is: ", url.path)
            viewModel.encodeVideo(videoURL: url, completion: {
                path in
                guard let newPath = path else { return }
                var indexPath: IndexPath? = nil
                DispatchQueue.main.async {
                    (_, indexPath) = self.viewModel.sendVideo(atPath: newPath, sourceType: picker.sourceType)
                    self.tableView.beginUpdates()
                    self.tableView.insertSections(IndexSet(integer: (indexPath?.section)!), with: .automatic)
                    self.tableView.endUpdates()
                    self.tableView.scrollToBottom(animated: false)
                    guard let newIndexPath = indexPath, let cell = self.tableView.cellForRow(at: newIndexPath) as? ALKMyVideoCell else { return }
                    guard ALDataNetworkConnection.checkDataNetworkAvailable() else {
                        let notificationView = ALNotificationView()
                        notificationView.noDataConnectionNotificationView()
                        return
                    }
                    self.viewModel.uploadVideo(view: cell, indexPath: newIndexPath)
                }
            })
        }

        picker.dismiss(animated: true, completion: nil)
    }
}

extension ALKConversationViewController: ALKCustomPickerDelegate {
    func filesSelected(images: [UIImage], videos: [String]) {
        let count = images.count + videos.count
        for i in 0..<count {
            if i < images.count {
                let image = images[i]
                let (message, indexPath) =  self.viewModel.send(photo: image)
                guard let _ = message, let newIndexPath = indexPath else { return }
                //            DispatchQueue.main.async {
                self.tableView.beginUpdates()
                self.tableView.insertSections(IndexSet(integer: newIndexPath.section), with: .automatic)
                self.tableView.endUpdates()
                self.tableView.scrollToBottom(animated: false)
                //            }
                guard let cell = tableView.cellForRow(at: newIndexPath) as? ALKMyPhotoPortalCell else { return }
                guard ALDataNetworkConnection.checkDataNetworkAvailable() else {
                    let notificationView = ALNotificationView()
                    notificationView.noDataConnectionNotificationView()
                    return
                }
                viewModel.uploadImage(view: cell, indexPath: newIndexPath)
            } else {
                let path = videos[i - images.count]
                let (_, indexPath) = viewModel.sendVideo(atPath: path, sourceType: .photoLibrary)
                self.tableView.beginUpdates()
                self.tableView.insertSections(IndexSet(integer: (indexPath?.section)!), with: .automatic)
                self.tableView.endUpdates()
                self.tableView.scrollToBottom(animated: false)
                guard let newIndexPath = indexPath, let cell = tableView.cellForRow(at: newIndexPath) as? ALKMyVideoCell else { return }
                guard ALDataNetworkConnection.checkDataNetworkAvailable() else {
                    let notificationView = ALNotificationView()
                    notificationView.noDataConnectionNotificationView()
                    return
                }
                self.viewModel.uploadVideo(view: cell, indexPath: newIndexPath)
            }

        }
    }
}
