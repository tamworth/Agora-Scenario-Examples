//
//  MainModel.swift
//  Scene-Examples
//
//  Created by zhaoyongqiang on 2021/11/10.
//

import UIKit

enum SceneType: String {
    /// 单直播
    case singleLive = "SignleLive"
    /// 超级小班课
    case breakoutRoom = "BreakOutRoom"
    /// 游戏
    case game = "interactiveGame"
    /// PKApply
    case pkApply = "PKApplyInfo"
    /// PKInfo
    case pkInfo = "PKInfo"
}

struct MainModel {
    var title: String = ""
    var desc: String = ""
    var imageNmae: String = ""
    var sceneType: SceneType = .singleLive
    
    static func mainDatas() -> [MainModel] {
        var dataArray = [MainModel]()
        var model = MainModel()
        model.title = "单主播直播"
        model.desc = "单主播直播"
        model.imageNmae = "pic-single"
        model.sceneType = .singleLive
        dataArray.append(model)
        
        model = MainModel()
        model.title = "PK直播"
        model.desc = "两个不同直播间的主播跨频道连麦PK, 引爆直播间"
        model.imageNmae = "pic-PK"
        model.sceneType = .pkApply
        dataArray.append(model)
        
        model = MainModel()
        model.title = "超级小班课"
        model.desc = "多人会议, 可建立小会议室讨论"
        model.imageNmae = "pic-virtual"
        model.sceneType = .breakoutRoom
        dataArray.append(model)
        
        return dataArray
    }
    
    static func sceneId(type: SceneType) -> String {
        type.rawValue
    }
}