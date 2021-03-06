//
//  ALMessageDBServiceMock.swift
//  ApplozicSwiftDemoTests
//
//  Created by Mukesh Thawani on 25/09/18.
//  Copyright © 2018 Applozic. All rights reserved.
//

import Foundation
import Applozic

class ALMessageDBServiceMock: ALMessageDBService {

    static var lastMessage: ALMessage! = MockMessage().message

    override func getMessages(_ subGroupList: NSMutableArray!) {
        delegate.getMessagesArray([ALMessageDBServiceMock.lastMessage])
    }

}

