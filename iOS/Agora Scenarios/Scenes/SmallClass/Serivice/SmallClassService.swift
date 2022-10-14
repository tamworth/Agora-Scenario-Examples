//
//  SmallClassService.swift
//  Agora Scenarios
//
//  Created by wushengtao on 2022/10/13.
//

import Foundation

class SmallClassService {
    var channelName: String?
}

extension SmallClassService: SmallClassServiceDelegate {
    
    func join(roomName: String, completion:@escaping (SyncError?, SmallClassServiceJoinResponse?)->()) {
        let roomInfo = LiveRoomInfo(roomName: roomName)
        let params = JSONObject.toJson(roomInfo)
        
        SyncUtil.joinScene(id: roomInfo.roomId,
                           userId: roomInfo.userId,
                           property: params) {[weak self] result in
            LogUtils.log(message: "result == \(result.toJson() ?? "")", level: .info)
            let channelName = result.getPropertyWith(key: "roomId", type: String.self) as? String
            self?.channelName = channelName
            NetworkManager.shared.generateToken(channelName: channelName ?? "", uid: UserInfo.userId) {
                let resp = SmallClassServiceJoinResponse(channelName: channelName ?? "", userId: "\(UserInfo.userId)")
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
        
        SyncUtil.scene(id: channelName)?.unsubscribe(key: SceneType.smallClass.rawValue)
        SyncUtil.scene(id: channelName)?.collection(className: SYNC_SCENE_ROOM_USER_COLLECTION).document().unsubscribe(key: "")
        SyncUtil.leaveScene(id: channelName)
    }
    
    func removeRoom() {
        guard let channelName = self.channelName else {
            assert(false, "channelName = nil")
            return
        }
//        SyncUtil.scene(id: channelName)?.delete(success: nil, fail: nil)
        SyncUtil.scene(id: channelName)?.deleteScenes()
    }
    
    func addUser(user: AgoraUsersModel, completion: @escaping (SyncError?, AgoraUsersModel?)->()) {
        guard let channelName = self.channelName else {
            assert(false, "channelName = nil")
            return
        }
        let params = JSONObject.toJson(user)
        SyncUtil.scene(id: channelName)?.collection(className: SYNC_SCENE_ROOM_USER_COLLECTION).add(data: params, success: { object in
            let model = JSONObject.toModel(AgoraUsersModel.self, value: object.toJson())
            completion(nil, model)
        }, fail: { error in
            completion(error, nil)
        })
    }
    func removeUser(user: AgoraUsersModel, completion: @escaping (SyncError?, [AgoraUsersModel]?) -> ()) {
        guard let channelName = self.channelName else {
            assert(false, "channelName = nil")
            return
        }
        SyncUtil.scene(id: channelName)?.collection(className: SYNC_SCENE_ROOM_USER_COLLECTION)
            .document(id: user.objectId ?? "")
            .delete(success: { results in
                let datas = results.compactMap({ $0.toJson() })
                    .compactMap({ JSONObject.toModel(AgoraUsersModel.self, value: $0 )})
                    .sorted(by: { $0.timestamp < $1.timestamp })
                completion(nil, datas)
            }, fail: { error in
                completion(error, nil)
            })
    }
    
    func updateUser(user: AgoraUsersModel, completion: @escaping (SyncError?, AgoraUsersModel?)->()) {
        guard let channelName = self.channelName else {
            assert(false, "channelName = nil")
            return
        }
        SyncUtil.scene(id: channelName)?.collection(className: SYNC_SCENE_ROOM_USER_COLLECTION)
            .document(id: user.objectId ?? "")
            .update(key: "", data: JSONObject.toJson(user), success: { objects in
                guard let object = objects.first, let model = JSONObject.toModel(AgoraUsersModel.self, value: object.toJson()) else {
                    assert(false, "user == nil")
                    return
                }
                completion(nil, model)
            }, fail: { error in
                completion(error, nil)
            })
    }
    
    func getUserStatus(completion: @escaping (SyncError?, [AgoraUsersModel]?)->()) {
        guard let channelName = self.channelName else {
            assert(false, "channelName = nil")
            return
        }
        SyncUtil.scene(id: channelName)?.collection(className: SYNC_SCENE_ROOM_USER_COLLECTION).get(success: { results in
            let datas = results.compactMap({ $0.toJson() })
                .compactMap({ JSONObject.toModel(AgoraUsersModel.self, value: $0 )})
                .sorted(by: { $0.timestamp < $1.timestamp })
            completion(nil, datas)
        }, fail: { error in
            completion(error, nil)
        })
    }

    
    func subscribeRoom(subscribeClosure: @escaping (SmallClassSubscribeStatus, LiveRoomInfo?)->(),
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
            subscribeClosure(SmallClassSubscribeStatus.created, model)
        }, onUpdated: { object in
            guard let model = JSONObject.toModel(LiveRoomInfo.self, value: object.toJson()) else {
                assert(false, "LiveRoomInfo == nil")
                return
            }
            subscribeClosure(SmallClassSubscribeStatus.updated, model)
        }, onDeleted: { object in
            let model = JSONObject.toModel(LiveRoomInfo.self, value: object.toJson())
            subscribeClosure(SmallClassSubscribeStatus.deleted, model)
        }, onSubscribed: {
            onSubscribed?()
        }, fail: { error in
            fail?(error)
        })
    }
    
    func subscribeUser(subscribeClosure: @escaping (SmallClassSubscribeStatus, AgoraUsersModel?)->(),
                       onSubscribed: (()->())?,
                       fail: ((SyncError)->())?) {
        guard let channelName = self.channelName else {
            assert(false, "channelName = nil")
            return
        }
        SyncUtil.scene(id: channelName)?.subscribe(key: SYNC_SCENE_ROOM_USER_COLLECTION,
                                                   onCreated: { object in
            guard let model = JSONObject.toModel(AgoraUsersModel.self, value: object.toJson()) else {
                assert(false, "AgoraUsersModel == nil")
                return
            }
            subscribeClosure(SmallClassSubscribeStatus.created, model)
        }, onUpdated: { object in
            guard let model = JSONObject.toModel(AgoraUsersModel.self, value: object.toJson()) else {
                assert(false, "AgoraUsersModel == nil")
                return
            }
            subscribeClosure(SmallClassSubscribeStatus.updated, model)
        }, onDeleted: { object in
            let model = JSONObject.toModel(AgoraUsersModel.self, value: object.toJson())
            subscribeClosure(SmallClassSubscribeStatus.deleted, model)
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
