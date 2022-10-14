//
//  VoiceChatRoomServiceDelegate.swift
//  Scene-Examples
//
//  Created by wushengtao on 2022/10/12.
//

import Foundation

enum VoiceChatRoomSubscribeStatus {
    case created
    case deleted
    case updated
}

protocol VoiceChatRoomServiceDelegate {

    func join(roomName: String, completion:@escaping (SyncError?, LiveRoomInfo?)->())
    func leave()
    func removeRoom()
    func updateRoom(room: LiveRoomInfo, completion: @escaping (SyncError?, LiveRoomInfo?)->())
    func getRoom(completion: @escaping (SyncError?, LiveRoomInfo?)->())
    func addUser(userInfo: AgoraUsersModel, completion: @escaping (SyncError?, AgoraUsersModel?)->())
    func removeUser(userId: String,
                    completion: @escaping (SyncError?)->())
    func sendMessage(messageInfo: ChatMessageModel,
                     completion: @escaping (SyncError?, ChatMessageModel?)->())
    func subscribeRoom(subscribeClosure: @escaping (VoiceChatRoomSubscribeStatus, LiveRoomInfo?)->(),
                       onSubscribed: (()->())?,
                       fail: ((SyncError)->())?)
}


