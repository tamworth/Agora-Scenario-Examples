//
//  VideoCallService.swift
//  Agora Scenarios
//
//  Created by wushengtao on 2022/10/13.
//

import Foundation

class VideoCallService {
    var channleName: String?
}

extension VideoCallService: VideoCallServiceDelegate {
    
    func join(roomName: String, completion:@escaping (SyncError?, VideoCallServiceJoinResponse?)->()) {
        let roomInfo = LiveRoomInfo(roomName: roomName)
        let params = JSONObject.toJson(roomInfo)
        
        SyncUtil.joinScene(id: roomInfo.roomId,
                           userId: roomInfo.userId,
                           property: params) {[weak self] result in
            LogUtils.log(message: "result == \(result.toJson() ?? "")", level: .info)
            let channelName = result.getPropertyWith(key: "roomId", type: String.self) as? String
            self?.channleName = channelName
            NetworkManager.shared.generateToken(channelName: channelName ?? "", uid: UserInfo.userId) {
                let resp = VideoCallServiceJoinResponse(channelName: channelName ?? "", userId: "\(UserInfo.userId)")
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
        SyncUtil.scene(id:channleName)?.deleteScenes()
    }
    
    func removeUser(userId: String) {
        guard let channleName = self.channleName else {
            assert(false, "channelName = nil")
            return
        }
        SyncUtil.scene(id: channleName)?.collection(className: SYNC_SCENE_ROOM_USER_COLLECTION).delete(id: userId, success: nil, fail: nil)
    }
    
    func removeAllUsers() {
        guard let channleName = self.channleName else {
            assert(false, "channelName = nil")
            return
        }
        SyncUtil.scene(id: channleName)?.collection(className: SYNC_SCENE_ROOM_USER_COLLECTION).delete(success: nil, fail: nil)
    }
    
    func subscribeRoomDidEnd(completion: @escaping (IObject)->()) {
        guard let channleName = self.channleName else {
            assert(false, "channelName = nil")
            return
        }
        SyncUtil.scene(id: channleName)?.subscribe(key: "", onCreated: { object in
            
        }, onUpdated: { object in
            
        }, onDeleted: { object in
            completion(object)
        }, onSubscribed: {
            
        }, fail: { error in
            
        })
    }
    
    func getAllUserList(completion: @escaping (SyncError?, [IObject]?) -> ()) {
        guard let channleName = self.channleName else {
            assert(false, "channelName = nil")
            return
        }
        SyncUtil.scene(id: channleName)?.collection(className: SYNC_SCENE_ROOM_USER_COLLECTION).get(success: { list in
            completion(nil, list)
        }, fail: { error in
            Log.error(error: error.message, tag: "")
            completion(error, nil)
        })
    }
    
    func add(user: AgoraUsersModel, completion: @escaping (SyncError?, AgoraUsersModel?) -> ()) {
        guard let channleName = self.channleName else {
            assert(false, "channelName = nil")
            return
        }
        SyncUtil.scene(id: channleName)?.collection(className: SYNC_SCENE_ROOM_USER_COLLECTION).add(data: JSONObject.toJson(user), success: { object in
            //TODO:
            var model = user
            model.userId = object.getId()
            completion(nil, model)
        }, fail: { error in
            completion(error, nil)
        })
    }
}
