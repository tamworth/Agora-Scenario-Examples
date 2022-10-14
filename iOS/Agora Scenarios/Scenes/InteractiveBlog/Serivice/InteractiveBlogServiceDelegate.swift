//
//  InteractiveBlogServiceDelegate.swift
//  Scene-Examples
//
//  Created by wushengtao on 2022/10/12.
//

import Foundation

enum InteractiveBlogSubscribeStatus {
    case created
    case deleted
    case updated
}

protocol InteractiveBlogServiceDelegate {

    func join(roomName: String, completion:@escaping (SyncError?, InteractiveBlogServiceJoinResponse?)->())
    func leave()
    func removeRoom()
    func subscribeRoom(subscribeClosure: @escaping (InteractiveBlogSubscribeStatus, LiveRoomInfo?)->(),
                       onSubscribed: (()->())?,
                       fail: ((SyncError)->())?)
    func unsubscribe()
}


