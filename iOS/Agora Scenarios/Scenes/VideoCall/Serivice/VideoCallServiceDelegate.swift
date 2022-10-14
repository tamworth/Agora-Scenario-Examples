//
//  VideoCallServiceDelegate.swift
//  Scene-Examples
//
//  Created by wushengtao on 2022/10/12.
//

import Foundation


protocol VideoCallServiceDelegate {

    func join(roomName: String, completion:@escaping (SyncError?, VideoCallServiceJoinResponse?)->())
    func leave()
    func removeRoom()
    func removeUser(userId: String)
    func removeAllUsers()
    func subscribeRoomDidEnd(completion: @escaping (IObject)->())
    func getAllUserList(completion: @escaping (SyncError?, [IObject]?) -> ())
    func add(user: AgoraUsersModel, completion: @escaping (SyncError?, AgoraUsersModel?) -> ())
}


