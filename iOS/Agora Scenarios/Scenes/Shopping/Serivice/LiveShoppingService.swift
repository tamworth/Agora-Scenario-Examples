//
//  LiveShoppingService.swift
//  Agora Scenarios
//
//  Created by wushengtao on 2022/10/13.
//

import Foundation

class LiveShoppingService {
    var channelName: String?
}

extension LiveShoppingService: LiveShoppingServiceDelegate {

    func join(roomName: String, completion:@escaping (SyncError?, LiveShoppingServiceJoinResponse?)->()) {
        let roomInfo = LiveRoomInfo(roomName: roomName)
        let params = JSONObject.toJson(roomInfo)
        
        SyncUtil.joinScene(id: roomInfo.roomId,
                           userId: roomInfo.userId,
                           property: params) {[weak self] result in
            LogUtils.log(message: "result == \(result.toJson() ?? "")", level: .info)
            let channelName = result.getPropertyWith(key: "roomId", type: String.self) as? String
            self?.channelName = channelName
            NetworkManager.shared.generateToken(channelName: channelName ?? "", uid: UserInfo.userId) {
                let resp = LiveShoppingServiceJoinResponse(channelName: channelName ?? "", userId: "\(UserInfo.userId)")
                completion(nil, resp)
            }
        } fail: { error in
            completion(error, nil)
        }
    }
    
    func leave(channelName: String? = nil) {
        guard let channelName = channelName ?? self.channelName else {
            assert(false, "channelName = nil")
            return
        }
        SyncUtil.scene(id: channelName)?.unsubscribe(key: SYNC_MANAGER_GIFT_INFO)
        SyncUtil.scene(id: channelName)?.unsubscribe(key: SceneType.shopping.rawValue)
        SyncUtil.leaveScene(id: channelName)
//        SyncUtil.scene(id: channelName)?.unsubscribe(key: SYNC_MANAGER_PK_INFO)
    }
    
    func removeRoom() {
        guard let channelName = self.channelName else {
            assert(false, "channelName = nil")
            return
        }
//        SyncUtil.scene(id: channelName)?.delete(success: nil, fail: nil)
        SyncUtil.scene(id: channelName)?.deleteScenes()
    }
    
    func getPkInfo(completion: @escaping (SyncError?, PKInfoModel?)->()) {
        guard let channelName = channelName ?? self.channelName else {
            assert(false, "channelName = nil")
            return
        }
        SyncUtil.scene(id: channelName)?.get(key: SYNC_MANAGER_PK_INFO, success: { result in
            guard let pkInfoModel = JSONObject.toModel(PKInfoModel.self, value: result?.toJson()) else {
//                assert(false, "pkInfoModel = nil, add error closure!")
                return
            }
            completion(nil, pkInfoModel)
        }, fail: { error in
            completion(error, nil)
        })
    }
    
    func updatePkInfo(info: PKInfoModel, completion: @escaping (SyncError?, PKInfoModel?)->()) {
        guard let channelName = self.channelName else {
            assert(false, "channelName = nil")
            return
        }
        SyncUtil.scene(id: channelName)?.update(key: SYNC_MANAGER_PK_INFO, data: JSONObject.toJson(info), success: { object in
            guard let model = object.first, let model = JSONObject.toModel(PKInfoModel.self, value: model.toJson()) else {
                assert(false, "udpate pkinfo fail")
                return
            }
            completion(nil, model)
        }, fail: { error in
            completion(error, nil)
        })
    }
    
    func updatePkApply(invitation: PKApplyInfoModel, completion: @escaping (SyncError?, PKApplyInfoModel?)->()) {
        guard let channelName = invitation.targetRoomId else {
            assert(false, "channelName = nil")
            return
        }
        SyncUtil.scene(id: channelName)?.update(key: SceneType.shopping.rawValue, data: JSONObject.toJson(invitation), success: { object in
            guard let obj = object.first, let _ = JSONObject.toModel(PKApplyInfoModel.self, value: obj.toJson()) else {
                assert(false, "convert object to PKApplyInfoModel fail!")
                return
            }
            completion(nil, nil)
        }, fail: { error in
            completion(error, nil)
        })
    }
    
    func removePkApply(channelName: String,
                       completion: @escaping (SyncError?, PKApplyInfoModel?)->()) {
        SyncUtil.scene(id: channelName)?.collection(className: SceneType.shopping.rawValue).delete(success: { object in
            guard let obj = object.first, let model = JSONObject.toModel(PKApplyInfoModel.self, value: obj.toJson()) else {
                assert(false, "unknown obj")
                return
            }
            completion(nil, model)
        }, fail: { error in
            completion(error, nil)
        })
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
    
    func subscribePkInfo(channelName: String?,
                         subscribeClosure: @escaping (LiveShoppingSubscribeStatus, PKInfoModel?)->(),
                         onSubscribed: (()->())?,
                         fail: ((SyncError)->())?) {
        guard let channelName = channelName ?? self.channelName else {
            assert(false, "channelName = nil")
            return
        }
        SyncUtil.scene(id: channelName)?.subscribe(key: SYNC_MANAGER_PK_INFO,
                                                   onCreated: { object in
            guard let model = JSONObject.toModel(PKInfoModel.self, value: object.toJson()) else {
                assert(false, "PKInfoModel == nil")
                return
            }
            subscribeClosure(LiveShoppingSubscribeStatus.created, model)
        }, onUpdated: { object in
            guard let model = JSONObject.toModel(PKInfoModel.self, value: object.toJson()) else {
                assert(false, "PKInfoModel == nil")
                return
            }
            subscribeClosure(LiveShoppingSubscribeStatus.updated, model)
        }, onDeleted: { object in
            let model = JSONObject.toModel(PKInfoModel.self, value: object.toJson())
            subscribeClosure(LiveShoppingSubscribeStatus.deleted, model)
        }, onSubscribed: {
            onSubscribed?()
        }, fail: { error in
            fail?(error)
        })
    }
    
    func subscribeApply(channelName: String?,
                             subscribeClosure: @escaping (LiveShoppingSubscribeStatus, PKApplyInfoModel?)->(),
                             onSubscribed: (()->())?,
                             fail: ((SyncError)->())?) {
        guard let channelName = channelName ?? self.channelName else {
            assert(false, "channelName = nil")
            return
        }
        SyncUtil.scene(id: channelName)?.subscribe(key: SceneType.shopping.rawValue,
                                                   onCreated: { object in
            guard let model = JSONObject.toModel(PKApplyInfoModel.self, value: object.toJson()) else {
                assert(false, "PKApplyInfoModel == nil")
                return
            }
            subscribeClosure(LiveShoppingSubscribeStatus.created, model)
        }, onUpdated: { object in
            guard let model = JSONObject.toModel(PKApplyInfoModel.self, value: object.toJson()) else {
                assert(false, "PKApplyInfoModel == nil")
                return
            }
            subscribeClosure(LiveShoppingSubscribeStatus.updated, model)
        }, onDeleted: { object in
            let model = JSONObject.toModel(PKApplyInfoModel.self, value: object.toJson())
            subscribeClosure(LiveShoppingSubscribeStatus.deleted, model)
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
