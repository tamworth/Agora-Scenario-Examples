//
//  VoiceChatRoomService.swift
//  Agora Scenarios
//
//  Created by wushengtao on 2022/10/13.
//

import Foundation

class VoiceChatRoomService {
    var channelName: String?
}

extension VoiceChatRoomService: VoiceChatRoomServiceDelegate {
    
    func join(roomName: String, completion:@escaping (SyncError?, LiveRoomInfo?)->()) {
        let roomInfo = LiveRoomInfo(roomName: roomName)
        let params = JSONObject.toJson(roomInfo)
        
        SyncUtil.joinScene(id: roomInfo.roomId,
                           userId: roomInfo.userId,
                           property: params) {[weak self] result in
            LogUtils.log(message: "result == \(result.toJson() ?? "")", level: .info)
            let channelName = result.getPropertyWith(key: "roomId", type: String.self) as? String
            self?.channelName = channelName
            NetworkManager.shared.generateToken(channelName: channelName ?? "", uid: UserInfo.userId) {
                let resp = JSONObject.toModel(LiveRoomInfo.self, value: result.toJson())
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
        SyncUtil.leaveScene(id: channelName)
    }
    
    func removeRoom() {
        guard let channelName = self.channelName else {
            assert(false, "channelName = nil")
            return
        }
        SyncUtil.scene(id: channelName)?.deleteScenes()
    }
    
    
    func updateRoom(room: LiveRoomInfo, completion: @escaping (SyncError?, LiveRoomInfo?)->()) {
        guard let channelName = self.channelName else {
            assert(false, "channelName = nil")
            return
        }
        let params = JSONObject.toJson(room)
        SyncUtil.scene(id: channelName)?.update(key: "", data: params, success: { objects in
            let model = JSONObject.toModel(LiveRoomInfo.self, value: objects.first?.toJson())
            completion(nil, model)
        }, fail: { error in
            completion(error, nil)
        })
    }
    
    func getRoom(completion: @escaping (SyncError?, LiveRoomInfo?)->()) {
        guard let channelName = self.channelName else {
            assert(false, "channelName = nil")
            return
        }
        SyncUtil.scene(id: channelName)?.get(key: "", success: { object in
            guard let object = object else {
                assert(false, "object = nil, add error message(completion(error, nil))")
                return
            }
            let model = JSONObject.toModel(LiveRoomInfo.self, value: object.toJson())
            completion(nil, model)
        }, fail: { error in
            completion(error, nil)
        })
    }

    
    func addUser(userInfo: AgoraUsersModel, completion: @escaping (SyncError?, AgoraUsersModel?)->()) {
        guard let channelName = self.channelName else {
            assert(false, "channelName = nil")
            return
        }
        let params = JSONObject.toJson(userInfo)
        SyncUtil.scene(id: channelName)?.collection(className: SYNC_MANAGER_AGORA_VOICE_USERS).add(data: params, success: { object in
            let model = JSONObject.toModel(AgoraUsersModel.self, value: object.toJson())
            completion(nil, model)
        }, fail: { error in
            completion(error, nil)
        })
    }
    
    func removeUser(userId: String, completion: @escaping (SyncError?)->()) {
        guard let channelName = self.channelName else {
            assert(false, "channelName = nil")
            return
        }
        SyncUtil.scene(id: channelName)?.collection(className: SYNC_MANAGER_AGORA_VOICE_USERS).delete(id: userId, success: {
            completion(nil)
        }, fail: { error in
            completion(error)
        })
    }
    
    func sendMessage(messageInfo: ChatMessageModel, completion: @escaping (SyncError?, ChatMessageModel?)->()) {
        guard let channelName = self.channelName else {
            assert(false, "channelName = nil")
            return
        }
        SyncUtil.scene(id: channelName)?
            .collection(className: SYNC_SCENE_ROOM_MESSAGE_INFO)
            .add(data: JSONObject.toJson(messageInfo), success: { object in
                let model = JSONObject.toModel(ChatMessageModel.self, value: object.toJson())
                completion(nil, model)
            }, fail: { error in
                completion(error, nil)
            })
    }
    
    func subscribeRoom(subscribeClosure: @escaping (VoiceChatRoomSubscribeStatus, LiveRoomInfo?)->(),
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
            subscribeClosure(VoiceChatRoomSubscribeStatus.created, model)
        }, onUpdated: { object in
            guard let model = JSONObject.toModel(LiveRoomInfo.self, value: object.toJson()) else {
                assert(false, "LiveRoomInfo == nil")
                return
            }
            subscribeClosure(VoiceChatRoomSubscribeStatus.updated, model)
        }, onDeleted: { object in
            let model = JSONObject.toModel(LiveRoomInfo.self, value: object.toJson())
            subscribeClosure(VoiceChatRoomSubscribeStatus.deleted, model)
        }, onSubscribed: {
            onSubscribed?()
        }, fail: { error in
            fail?(error)
        })
    }
}
