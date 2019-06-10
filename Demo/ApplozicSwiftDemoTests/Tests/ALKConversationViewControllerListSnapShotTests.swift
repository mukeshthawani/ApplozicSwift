//
//  ALKConversationViewControllerUITests.swift
//  ApplozicSwiftDemoTests
//
//  Created by Mukesh Thawani on 17/06/18.
//  Copyright © 2018 Applozic. All rights reserved.
//

import Quick
import Nimble
import Nimble_Snapshots
import Applozic
@testable import ApplozicSwift

class ALKConversationViewControllerListSnapShotTests: QuickSpec {

    override func spec() {

        describe("Conversation list") {

            var conversationVC: ALKConversationListViewController!
            var navigationController: UINavigationController!

            beforeEach {

                conversationVC = ALKConversationListViewController(configuration: ALKConfiguration())
                ALMessageDBServiceMock.lastMessage.createdAtTime = NSNumber(value: Date().timeIntervalSince1970 * 1000)
                conversationVC.dbService = ALMessageDBServiceMock()
                conversationVC.userService = ALUserServiceMock()

                let firstMessage = MockMessage().message
                firstMessage.message = "first message"
                let secondmessage = MockMessage().message
                secondmessage.message = "second message"
                ALKConversationViewModelMock.testMessages = [firstMessage.messageModel, secondmessage.messageModel]
                conversationVC.conversationViewModelType = ALKConversationViewModelMock.self
                navigationController = ALKBaseNavigationViewController(rootViewController: conversationVC)
                conversationVC.beginAppearanceTransition(true, animated: false)
                conversationVC.endAppearanceTransition()
            }

            it("Show list") {
                XCTAssertNotNil(navigationController.view)
                XCTAssertNotNil(conversationVC.view)
                expect(navigationController)
                    .toEventually(
                        haveValidSnapshot(),
                        timeout: 3.0,
                        pollInterval: 0.5,
                        description: nil)
            }

            it("Open chat thread") {
                XCTAssertNotNil(conversationVC.tableView)
                let tableView = conversationVC.tableView 
                tableView.delegate?.tableView?(tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
                XCTAssertNotNil(conversationVC.navigationController?.view)
                expect(conversationVC.navigationController)
                    .toEventually(
                        haveValidSnapshot(),
                        timeout: 2.0,
                        pollInterval: 0.5,
                        description: nil)
            }
        }

        context("Conversation list screen") {
            var conversationVC: ALKConversationListViewController!
            var navigationController: UINavigationController!

            beforeEach {
                conversationVC = ALKConversationListViewController(configuration: ALKConfiguration())
                let mockMessage = ALMessageDBServiceMock.lastMessage!
                mockMessage.message = "Re: Subject"
                mockMessage.contentType = Int16(ALMESSAGE_CONTENT_TEXT_HTML)
                mockMessage.source = 7
                mockMessage.createdAtTime = NSNumber(value: Date().timeIntervalSince1970 * 1000)
                conversationVC.dbService = ALMessageDBServiceMock()
                navigationController = ALKBaseNavigationViewController(rootViewController: conversationVC)
            }

            it("show email thread") {
                expect(navigationController)
                    .toEventually(
                        haveValidSnapshot(),
                        timeout: 2.0,
                        pollInterval: 0.5,
                        description: nil)
            }
        }

        describe("configure right nav bar icon") {

            var configuration: ALKConfiguration!
            var conversationVC: ALKConversationListViewController!
            var navigationController: UINavigationController!

            beforeEach {
                configuration = ALKConfiguration()
                configuration.rightNavBarImageForConversationListView = UIImage(named: "close", in: Bundle.applozic, compatibleWith: nil)
                conversationVC = ALKConversationListViewController(configuration: configuration)
                conversationVC.dbService = ALMessageDBServiceMock()
                conversationVC.conversationViewModelType = ALKConversationViewModelMock.self
                conversationVC.beginAppearanceTransition(true, animated: false)
                conversationVC.endAppearanceTransition()
                navigationController = ALKBaseNavigationViewController(rootViewController: conversationVC)
            }

            it("change icon image") {
                navigationController.navigationBar.snapshotView(afterScreenUpdates: true)
                expect(navigationController.navigationBar).to(haveValidSnapshot())
            }
        }

    }

    func getApplicationKey() -> NSString {

        let appKey = ALUserDefaultsHandler.getApplicationKey() as NSString?
        let applicationKey = appKey
        return applicationKey!
    }
}
