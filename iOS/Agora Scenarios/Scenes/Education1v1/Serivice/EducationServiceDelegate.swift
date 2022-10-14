//
//  EducationServiceDelegate.swift
//  Scene-Examples
//
//  Created by wushengtao on 2022/10/12.
//

import Foundation

enum EducationSubscribeStatus {
    case created
    case deleted
    case updated
}

protocol EducationServiceDelegate {

    func join(roomName: String, completion:@escaping (SyncError?, EducationServiceJoinResponse?)->())
    func leave()
    func removeRoom()
    func subscribeRoom(subscribeClosure: @escaping (EducationSubscribeStatus, LiveRoomInfo?)->(),
                       onSubscribed: (()->())?,
                       fail: ((SyncError)->())?)
    func unsubscribe()
}


