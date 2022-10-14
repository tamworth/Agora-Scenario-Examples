//
//  LiveBroadcastingServiceDelegate.swift
//  Scene-Examples
//
//  Created by wushengtao on 2022/10/12.
//

import Foundation


protocol LiveBroadcastingServiceDelegate {

    func join(roomName: String, completion:@escaping (SyncError?, LiveBroadcastingServiceJoinResponse?)->())
    func leave()
    func removeRoom()
    func subscribeRoomDidEnd(completion: @escaping (LiveRoomInfo?)->())
}


