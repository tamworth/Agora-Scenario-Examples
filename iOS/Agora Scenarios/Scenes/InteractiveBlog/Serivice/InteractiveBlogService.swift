//
//  InteractiveBlogService.swift
//  Agora Scenarios
//
//  Created by wushengtao on 2022/10/13.
//

import Foundation

class InteractiveBlogService {
    var channelName: String?
}

extension InteractiveBlogService: InteractiveBlogServiceDelegate {
    
    func join(roomName: String, completion:@escaping (SyncError?, InteractiveBlogServiceJoinResponse?)->()) {
        let roomInfo = LiveRoomInfo(roomName: roomName)
        let params = JSONObject.toJson(roomInfo)
        
        SyncUtil.joinScene(id: roomInfo.roomId,
                           userId: roomInfo.userId,
                           property: params) {[weak self] result in
            LogUtils.log(message: "result == \(result.toJson() ?? "")", level: .info)
            let channelName = result.getPropertyWith(key: "roomId", type: String.self) as? String
            self?.channelName = channelName
            NetworkManager.shared.generateToken(channelName: channelName ?? "", uid: UserInfo.userId) {
                let resp = InteractiveBlogServiceJoinResponse(channelName: channelName ?? "", userId: "\(UserInfo.userId)")
                completion(nil, resp)
            }
        } fail: { error in
            completion(error, nil)
        }
    }
    
    func leave() {
        guard let channelName = self.channelName else {
            assert(false, "channelName = nil")
            return
        }
        
//        SyncUtil.scene(id: channelName)?.unsubscribe(key: SceneType.singleLive.rawValue)
        SyncUtil.leaveScene(id: channelName)
    }
    
    func removeRoom() {
        guard let channelName = self.channelName else {
            assert(false, "channelName = nil")
            return
        }
        SyncUtil.scene(id: channelName)?.delete(success: nil, fail: nil)
//        SyncUtil.scene(id: channelName)?.deleteScenes()
    }
    
    
    func subscribeRoom(subscribeClosure: @escaping (InteractiveBlogSubscribeStatus, LiveRoomInfo?)->(),
                       onSubscribed: (()->())?,
                       fail: ((SyncError)->())?) {
        guard let channelName = self.channelName else {
            assert(false, "channelName = nil")
            return
        }
        SyncUtil.scene(id: channelName)?.subscribe(key: "",
                                                   onCreated: { object in
            guard let model = JSONObject.toModel(LiveRoomInfo.self, value: object.toJson()) else {
                assert(false, "LiveRoomInfo == nil")
                return
            }
            subscribeClosure(InteractiveBlogSubscribeStatus.created, model)
        }, onUpdated: { object in
            guard let model = JSONObject.toModel(LiveRoomInfo.self, value: object.toJson()) else {
                assert(false, "LiveRoomInfo == nil")
                return
            }
            subscribeClosure(InteractiveBlogSubscribeStatus.updated, model)
        }, onDeleted: { object in
            let model = JSONObject.toModel(LiveRoomInfo.self, value: object.toJson())
            subscribeClosure(InteractiveBlogSubscribeStatus.deleted, model)
        }, onSubscribed: {
            onSubscribed?()
        }, fail: { error in
            fail?(error)
        })
    }
    
    
    func unsubscribe() {
        guard let channelName = self.channelName else {
            assert(false, "channelName = nil")
            return
        }
        SyncUtil.scene(id: channelName)?.unsubscribe(key: SceneType.interactiveBlog.rawValue)
        SyncUtil.scene(id: channelName)?.unsubscribe(key: SYNC_MANAGER_AGORA_VOICE_USERS)
    }
}
