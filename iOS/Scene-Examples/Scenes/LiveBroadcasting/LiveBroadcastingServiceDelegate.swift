//
//  LiveBroadcastingServiceDelegate.swift
//  Scene-Examples
//
//  Created by wushengtao on 2022/10/12.
//

import Foundation

protocol LiveBroadcastingServiceDelegate {
    func join(roomName: String, completion:@escaping (SyncError?, String?, String?)->())
    func leave()
    func removeRoom()
    func subscribeRoomDidEnd(completion: @escaping ()->())
}


class LiveBroadcastingService {
    var channleName: String?
}

extension LiveBroadcastingService: LiveBroadcastingServiceDelegate {
    
    func join(roomName: String, completion:@escaping (SyncError?, String?, String?)->()) {
        let roomInfo = LiveRoomInfo(roomName: roomName)
        let params = JSONObject.toJson(roomInfo)
        
        SyncUtil.joinScene(id: roomInfo.roomId,
                           userId: roomInfo.userId,
                           property: params) {[weak self] result in
            LogUtils.log(message: "result == \(result.toJson() ?? "")", level: .info)
            let channelName = result.getPropertyWith(key: "roomId", type: String.self) as? String
            self?.channleName = channelName
            NetworkManager.shared.generateToken(channelName: channelName ?? "") {
                completion(nil, channelName ?? "", "\(UserInfo.userId)")
            }
        } fail: { error in
            completion(error, nil, nil)
        }
    }
    
    func leave() {
        guard let channleName = self.channleName else {
            return
        }
        SyncUtil.scene(id: channleName)?.unsubscribe(key: SceneType.singleLive.rawValue)
        SyncUtil.leaveScene(id: channleName)
    }
    
    func removeRoom() {
        guard let channleName = self.channleName else {
            return
        }
        SyncUtil.scene(id: channleName)?.deleteScenes()
    }
    
    func subscribeRoomDidEnd(completion: @escaping ()->()) {
        guard let channleName = self.channleName else {
            return
        }
        SyncUtil.scene(id: channleName)?.subscribe(key: "", onCreated: { object in
            
        }, onUpdated: { object in
            
        }, onDeleted: { object in
            completion()
        }, onSubscribed: {
            
        }, fail: { error in
            
        })
    }
}
