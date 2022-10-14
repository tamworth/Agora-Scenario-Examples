//
//  LiveBroadcastingService.swift
//  Agora Scenarios
//
//  Created by wushengtao on 2022/10/13.
//

import Foundation

class LiveBroadcastingService {
    var channleName: String?
}

extension LiveBroadcastingService: LiveBroadcastingServiceDelegate {
    
    func join(roomName: String, completion:@escaping (SyncError?, LiveBroadcastingServiceJoinResponse?)->()) {
        let roomInfo = LiveRoomInfo(roomName: roomName)
        let params = JSONObject.toJson(roomInfo)
        
        SyncUtil.joinScene(id: roomInfo.roomId,
                           userId: roomInfo.userId,
                           property: params) {[weak self] result in
            LogUtils.log(message: "result == \(result.toJson() ?? "")", level: .info)
            let channelName = result.getPropertyWith(key: "roomId", type: String.self) as? String
            self?.channleName = channelName
            NetworkManager.shared.generateToken(channelName: channelName ?? "") {
                let resp = LiveBroadcastingServiceJoinResponse(channelName: channelName ?? "", userId: "\(UserInfo.userId)")
                completion(nil, resp)
            }
        } fail: { error in
            completion(error, nil)
        }
    }
    
    func leave() {
        guard let channleName = self.channleName else {
            assert(false, "channelName = nil")
            return
        }
        SyncUtil.scene(id: channleName)?.unsubscribe(key: SceneType.singleLive.rawValue)
        SyncUtil.leaveScene(id: channleName)
    }
    
    func removeRoom() {
        guard let channleName = self.channleName else {
            assert(false, "channelName = nil")
            return
        }
        SyncUtil.scene(id: channleName)?.deleteScenes()
    }
    
    func subscribeRoomDidEnd(completion: @escaping (LiveRoomInfo?)->()) {
        guard let channleName = self.channleName else {
            assert(false, "channelName = nil")
            return
        }
        SyncUtil.scene(id: channleName)?.subscribe(key: "", onCreated: { object in
            
        }, onUpdated: { object in
            
        }, onDeleted: { object in
            let model = JSONObject.toModel(LiveRoomInfo.self, value: object.toJson())
            completion(model)
        }, onSubscribed: {
            
        }, fail: { error in
            
        })
    }
}
