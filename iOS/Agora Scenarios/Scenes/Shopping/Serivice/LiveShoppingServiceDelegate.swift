//
//  LiveShoppingServiceDelegate.swift
//  Scene-Examples
//
//  Created by wushengtao on 2022/10/12.
//

import Foundation

enum  LiveShoppingSubscribeStatus {
    case created
    case deleted
    case updated
}

protocol LiveShoppingServiceDelegate {

    func join(roomName: String, completion:@escaping (SyncError?, LiveShoppingServiceJoinResponse?)->())
    func leave(channelName: String?)
    func removeRoom()
    func getPkInfo(completion: @escaping (SyncError?, PKInfoModel?)->())
    func updatePkInfo(info: PKInfoModel, completion: @escaping (SyncError?, PKInfoModel?)->())
    func updatePkApply(invitation: PKApplyInfoModel,
                       completion: @escaping (SyncError?, PKApplyInfoModel?)->())
    func removePkApply(channelName: String,
                       completion: @escaping (SyncError?, PKApplyInfoModel?)->())
    func subscribeRoom(subscribeClosure: @escaping (InteractiveBlogSubscribeStatus, LiveRoomInfo?)->(),
                       onSubscribed: (()->())?,
                       fail: ((SyncError)->())?)
    func subscribePkInfo(channelName: String?,
                         subscribeClosure: @escaping (LiveShoppingSubscribeStatus, PKInfoModel?)->(),
                         onSubscribed: (()->())?,
                         fail: ((SyncError)->())?)
    func subscribeApply(channelName: String?,
                        subscribeClosure: @escaping (LiveShoppingSubscribeStatus, PKApplyInfoModel?)->(),
                        onSubscribed: (()->())?,
                        fail: ((SyncError)->())?)
    
    func unsubscribe()
}


