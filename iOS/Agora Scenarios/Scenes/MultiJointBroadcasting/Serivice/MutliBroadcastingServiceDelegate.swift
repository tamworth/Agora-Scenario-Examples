//
//  MutliBroadcastingServiceDelegate.swift
//  Scene-Examples
//
//  Created by wushengtao on 2022/10/12.
//

import Foundation

enum MutliBroadcastingSubscribeStatus {
    case created
    case deleted
    case updated
}

protocol MutliBroadcastingServiceDelegate {

    func join(roomName: String, completion:@escaping (SyncError?, MutliBroadcastingServiceJoinResponse?)->())
    func leave()
    func removeRoom()
    func subscribeRoom(subscribeClosure: @escaping (MutliBroadcastingSubscribeStatus, LiveRoomInfo?)->(),
                       onSubscribed: (()->())?,
                       fail: ((SyncError)->())?)
}


