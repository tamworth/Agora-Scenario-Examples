//
//  SceneSyncUtil.swift
//  Scene-Examples
//
//  Created by wushengtao on 2022/10/11.
//

import Foundation
public class SceneSyncUtil: NSObject {
    private var manager: AgoraSyncManager?
    private var sceneRefs: [String: SceneReference] = [String: SceneReference]()
    private(set) var inited: Bool = false
    
    func initSyncManager(sceneId: String, complete: @escaping SuccessBlockVoid) {
//        let config = AgoraSyncManager.RtmConfig(appId: KeyCenter.AppId,
//                                                channelName: sceneId)
//        manager = AgoraSyncManager(config: config, complete: { code in
//            if code == 0 {
//                print("SyncManager init success")
//            } else {
//                print("SyncManager init error")
//            }
//        })
        let config = AgoraSyncManager.RethinkConfig(appId: KeyCenter.AppId,
                                                    channelName: sceneId)
        ToastView.showWait(text: "join Scene...", view: nil)
        manager = AgoraSyncManager(config: config, complete: {[weak self] code in
            self?.inited = true
            ToastView.hidden()
            if code == 0 {
                print("SyncManager init success")
                complete()
            } else {
                print("SyncManager init error")
                ToastView.show(text: "SyncManager 连接失败")
            }
        })
    }
    
    func joinScene(id: String,
                         userId: String,
                         property: [String: Any]?,
                         success: SuccessBlockObj? = nil,
                         fail: FailBlock? = nil) {
        guard let manager = manager else { return }
        let jsonString = JSONObject.toJsonString(dict: property) ?? ""
        let params = JSONObject.toDictionary(jsonStr: jsonString)
        let scene = Scene(id: id, userId: userId, property: params)
        manager.createScene(scene: scene, success: { [weak self] in
            manager.joinScene(sceneId: id) {[weak self] sceneRef in
                self?.sceneRefs[id] = sceneRef
                let attr = Attribute(key: id, value: jsonString)
                success?(attr)
            } fail: { error in
                fail?(error)
            }
        }) { error in
            fail?(error)
        }
    }
    
    func scene(id: String) -> SceneReference? {
        sceneRefs[id]
    }
    
    func fetchAll(success: SuccessBlock? = nil, fail: FailBlock? = nil) {
        manager?.getScenes(success: success, fail: fail)
    }
    
    func leaveScene(id: String) {
        sceneRefs.removeValue(forKey: id)
    }
}
