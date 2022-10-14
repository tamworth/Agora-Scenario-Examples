//
//  SmallClassServiceDelegate.swift
//  Scene-Examples
//
//  Created by wushengtao on 2022/10/12.
//

import Foundation

enum SmallClassSubscribeStatus {
    case created
    case deleted
    case updated
}

protocol SmallClassServiceDelegate {

    func join(roomName: String, completion:@escaping (SyncError?, SmallClassServiceJoinResponse?)->())
    func leave()
    func removeRoom()
    func addUser(user: AgoraUsersModel, completion: @escaping (SyncError?, AgoraUsersModel?)->())
    func removeUser(user: AgoraUsersModel, completion: @escaping (SyncError?, [AgoraUsersModel]?)->())
    func updateUser(user: AgoraUsersModel, completion: @escaping (SyncError?, AgoraUsersModel?)->())
    func getUserStatus(completion: @escaping (SyncError?, [AgoraUsersModel]?)->())
    func subscribeRoom(subscribeClosure: @escaping (SmallClassSubscribeStatus, LiveRoomInfo?)->(),
                       onSubscribed: (()->())?,
                       fail: ((SyncError)->())?)
    func subscribeUser(subscribeClosure: @escaping (SmallClassSubscribeStatus, AgoraUsersModel?)->(),
                       onSubscribed: (()->())?,
                       fail: ((SyncError)->())?)
    func unsubscribe()
}


