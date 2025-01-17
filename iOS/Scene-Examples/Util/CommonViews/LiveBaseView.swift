//
//  LiveView.swift
//  Scene-Examples
//
//  Created by zhaoyongqiang on 2021/12/23.
//

import UIKit
import AgoraRtcKit
import Agora_Scene_Utils

enum RecelivedType {
    case me
    case target
}

class LiveBaseView: UIView {
    /// 点击发送消息
    var onTapSendMessageClosure: ((ChatMessageModel) -> Void)?
    /// 点击消息cell
    var onDidMessageCellClosure: ((ChatMessageModel) -> Void)?
    /// 关闭直播
    var onTapCloseLiveClosure: (() -> Void)?
    /// 点击切换摄像头
    var onTapSwitchCameraClosure: ((Bool) -> Void)?
    /// 点击暂停推理
    var onTapIsMuteCameraClosure: ((Bool) -> Void)?
    /// 麦克风是否静音
    var onTapIsMuteMicClosure: ((Bool) -> Void)?
    /// 点击PK邀请
    var onTapPKButtonClosure: (() -> Void)?
    /// 点击商品列表
    var onTapShoppingButtonClosure: (() -> Void)?
    /// 点击游戏
    var onTapGameButtonClosure: (() -> Void)?
    /// 点击退出游戏
    var onTapExitGameButtonClosure: (() -> Void)?
    /// 发送礼物
    var onSendGiftClosure: ((LiveGiftModel) -> Void)?
    /// 收到礼物
    var onReceivedGiftClosure: ((LiveGiftModel, RecelivedType) -> Void)?
    /// 设置本地视频画面
    var setupLocalVideoClosure: ((AgoraRtcVideoCanvas?) -> Void)?
    /// 设置远程直播画面
    var setupRemoteVideoClosure: ((LiveCanvasModel) -> Void)?
    
    enum LiveLayoutPostion {
        case full, center, bottom, signle, mutli
    }
    lazy var liveCanvasView: AGECollectionView = {
        let view = AGECollectionView()
        view.itemSize = CGSize(width: Screen.width, height: Screen.height)
        view.minInteritemSpacing = 0
        view.minLineSpacing = 0
        view.delegate = self
        view.scrollDirection = .vertical
        view.showsVerticalScrollIndicator = false
        view.isUserInteractionEnabled = false
        view.register(LivePlayerCell.self,
                      forCellWithReuseIdentifier: LivePlayerCell.description())
        return view
    }()
    /// 顶部头像昵称
    public lazy var avatarview = LiveAvatarView()
    /// 聊天
    public lazy var chatView = LiveChatView()
    /// 设置直播的工具弹窗
    private lazy var liveToolView = LiveToolView()
    /// 礼物
    private lazy var giftView = LiveGiftView()
    private lazy var onlineView = LiveOnlineView()
    public lazy var playGifView: GIFImageView = {
        let view = GIFImageView()
        view.isHidden = true
        return view
    }()
    /// 底部功能
    public lazy var bottomView: LiveBottomView = {
        let view = LiveBottomView(type: [.gift, .tool, .close])
        return view
    }()
    
    public var canvasDataArray = [LiveCanvasModel]()
    private var channelName: String = ""
    private var currentUserId: String = ""
    private var canvasLeadingConstraint: NSLayoutConstraint?
    private var canvasTopConstraint: NSLayoutConstraint?
    private var canvasTrailingConstraint: NSLayoutConstraint?
    private var canvasBottomConstraint: NSLayoutConstraint?
    private var chatViewTrailingConstraint: NSLayoutConstraint?
    private(set) var liveCanvasViewHeight: CGFloat = 0
    
    init(channelName: String, currentUserId: String) {
        super.init(frame: .zero)
        self.channelName = channelName
        self.currentUserId = currentUserId
        setupUI()
        eventHandler()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        eventHandler()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 设置主播昵称
    func setAvatarName(name: String, roomId: String) {
        avatarview.setName(with: "\(roomId)")
    }
    
    /// 更新底部功能按钮
    func updateBottomButtonType(type: [LiveBottomView.LiveBottomType]) {
        bottomView.updateButtonType(type: type)
    }
    
    func setupCanvasData(data: LiveCanvasModel) {
        canvasDataArray.append(data)
        liveCanvasView.dataArray = canvasDataArray
    }
    
    func sendMessage(userName: String, message: String, messageType: ChatMessageType) {
        var model = ChatMessageModel(content: message, messageType: messageType)
        model.userName = "User-\(userName)"
        chatView.sendMessage(messageModel: model)
    }
    
    func reloadData() {
        liveCanvasView.reloadData()
    }
    
    func removeData(index: Int) {
        canvasDataArray.remove(at: index)
        liveCanvasView.dataArray = canvasDataArray
    }
    
    func leave(channelName: String) {
        onlineView.delete(channelName: channelName)
        SyncUtil.scene(id: channelName)?.unsubscribe(key: SYNC_MANAGER_GIFT_INFO)
        SyncUtil.scene(id: channelName)?.unsubscribe(key: SYNC_SCENE_ROOM_MESSAGE_INFO)
        SyncUtil.scene(id: channelName)?.unsubscribe(key: SYNC_SCENE_ROOM_USER_COLLECTION)
    }
    
    /// 监听礼物
    func subscribeGift(channelName: String, type: RecelivedType) {
        SyncUtil.scene(id: channelName)?.subscribe(key: SYNC_MANAGER_GIFT_INFO, onCreated: { object in

        }, onUpdated: { object in
            LogUtils.log(message: "onUpdated gift == \(String(describing: object.toJson()))", level: .info)
            guard let userModel = JSONObject.toModel(LiveGiftModel.self, value: object.toJson()) else { return }
            if type == .me {
                self.playGifView.isHidden = false
                self.playGifView.loadGIFName(gifName: userModel.gifName)
                var model = ChatMessageModel(content: "i_gave_one_away".localized + userModel.title, messageType: .message)
                model.userName = "User-\(userModel.userId)"
                self.chatView.sendMessage(messageModel: model)
            }
            self.onReceivedGiftClosure?(userModel, type)
        }, onDeleted: { object in

        }, onSubscribed: {
            LogUtils.log(message: "subscribe gift type == \(type)", level: .info)
        }, fail: { error in
            ToastView.show(text: error.message)
        })
    }
    
    /// 更新直播布局
    func updateLiveLayout(postion: LiveLayoutPostion) {
        var leading: CGFloat = 0
        var top: CGFloat = -Screen.statusHeight()
        var bottom: CGFloat = 0
        var trailing: CGFloat = 0
        var itemWidth: CGFloat = Screen.width
        var itemHeight: CGFloat = Screen.height
        switch postion {
        case .bottom:
            let viewW = Screen.width
            itemWidth = ((viewW * 0.5) - 15) * 0.5
            itemHeight = viewW / 2 * 0.7
            let topMargin = frame.height - itemHeight - 78
            leading = viewW * 0.5
            top = topMargin
            bottom = -70
            trailing = -15
            chatViewTrailingConstraint?.constant = -(leading - 10)
            
        case .center:
            let viewW = Screen.width
            itemWidth = viewW / 2
            itemHeight = viewW / 2 * 1.2
            top = Screen.kNavHeight + 40
            guard let cons = chatViewTrailingConstraint else { return }
            chatView.removeConstraint(cons)
            
        case .signle:
            let viewW = Screen.width
            itemWidth = 90
            itemHeight = viewW / 2 * 0.7
            let topMargin = frame.height - itemHeight - 78
            leading = viewW - (itemWidth + 15)
            top = topMargin
            bottom = -70
            trailing = -15
            chatViewTrailingConstraint?.constant = -(itemWidth + 10)
            
        case .mutli:
            let viewW = Screen.width * 0.7
            itemWidth = viewW
            leading = viewW - (itemWidth + 15)
            top = Screen.kNavHeight + 40
            trailing = -(Screen.width - viewW)
            let chatViewW = Screen.width / 2 * 0.9
            bottom = -(70 + chatViewW)
            itemHeight = Screen.height - top + bottom
            chatViewTrailingConstraint?.constant = -15
            
        default:
            let chatViewW = Screen.width / 2 * 0.9
            chatViewTrailingConstraint?.constant = -chatViewW
        }
        liveCanvasViewHeight = top + itemHeight
        canvasLeadingConstraint?.constant = leading
        canvasTopConstraint?.constant = top
        canvasBottomConstraint?.constant = bottom
        canvasTrailingConstraint?.constant = trailing
        UIView.animate(withDuration: 0.5) {
            self.canvasTopConstraint?.isActive = true
            self.canvasBottomConstraint?.isActive = true
            self.canvasTrailingConstraint?.isActive = true
            self.canvasLeadingConstraint?.isActive = true
            self.liveCanvasView.itemSize = CGSize(width: itemWidth,
                                                  height: itemHeight)
            self.chatViewTrailingConstraint?.isActive = true
        }
    }
    
    private func eventHandler() {
        // gif播放完成回调
        playGifView.gifAnimationFinishedClosure = { [weak self] in
            guard let self = self else { return }
            self.playGifView.isHidden = true
        }
        // 聊天发送
        bottomView.onTapChatButtonClosure = { [weak self] message in
            guard let self = self else { return }
            var model = ChatMessageModel(content: message, messageType: .message)
            model.userName = "User-\(UserInfo.uid)"
            self.onTapSendMessageClosure?(model)
            SyncUtil.scene(id: self.channelName)?
                .collection(className: SYNC_SCENE_ROOM_MESSAGE_INFO)
                .add(data: JSONObject.toJson(model), success: nil, fail: nil)
        }
        // 点击聊天消息
        chatView.didSelectRowAt = { [weak self] messageModel in
            self?.onDidMessageCellClosure?(messageModel)
        }
        // 底部功能回调
        bottomView.onTapBottomButtonTypeClosure = { [weak self] type in
            guard let self = self else { return }
            switch type {
            case .close:
                self.onTapCloseLiveClosure?()
                
            case .tool:
                self.liveToolView.onTapItemClosure = { itemType, isSelected in
                    switch itemType {
                    case .switch_camera:
                        self.onTapSwitchCameraClosure?(isSelected)
                        
                    case .camera:
                        self.onTapIsMuteCameraClosure?(isSelected)
                        self.liveCanvasView.isHidden = isSelected
                    
                    case .mic:
                        self.onTapIsMuteMicClosure?(isSelected)
                    
                    default: break
                    }
                }
                AlertManager.show(view: self.liveToolView, alertPostion: .bottom)
            
            case .gift:
                self.giftView.onTapGiftItemClosure = { giftModel in
                    LogUtils.log(message: "gif == \(giftModel.gifName)", level: .info)
                    self.onSendGiftClosure?(giftModel)
                    let params = JSONObject.toJson(giftModel)
                    /// 发送礼物
                    SyncUtil.scene(id: self.channelName)?.update(key: SYNC_MANAGER_GIFT_INFO, data: params, success: { _ in
                        
                    }, fail: { error in
                        ToastView.show(text: error.message)
                    })
                }
                AlertManager.show(view: self.giftView, alertPostion: .bottom)
            case .pk:
                self.onTapPKButtonClosure?()
                
            case .game:
                self.onTapGameButtonClosure?()
                
            case .exitgame:
                self.onTapExitGameButtonClosure?()
                
            case .shopping:
                self.onTapShoppingButtonClosure?()
                
            default: break
            }
        }
        subscribeGift(channelName: channelName, type: .me)
        
        chatView.subscribeMessage(channelName: channelName)
        
        onlineView.getUserInfo(channelName: channelName)
    }
    
    private func setupUI() {
        liveCanvasView.translatesAutoresizingMaskIntoConstraints = false
        avatarview.translatesAutoresizingMaskIntoConstraints = false
        chatView.translatesAutoresizingMaskIntoConstraints = false
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        playGifView.translatesAutoresizingMaskIntoConstraints = false
        onlineView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(liveCanvasView)
        addSubview(avatarview)
        addSubview(chatView)
        addSubview(bottomView)
        addSubview(onlineView)
        
        canvasLeadingConstraint = liveCanvasView.leadingAnchor.constraint(equalTo: leadingAnchor)
        canvasTopConstraint = liveCanvasView.topAnchor.constraint(equalTo: topAnchor, constant: 0)
        canvasBottomConstraint = liveCanvasView.bottomAnchor.constraint(equalTo: bottomAnchor)
        canvasTrailingConstraint = liveCanvasView.trailingAnchor.constraint(equalTo: trailingAnchor)
        canvasTopConstraint?.isActive = true
        canvasBottomConstraint?.isActive = true
        canvasLeadingConstraint?.isActive = true
        canvasTrailingConstraint?.isActive = true
        
        avatarview.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15).isActive = true
        avatarview.topAnchor.constraint(equalTo: topAnchor, constant: Screen.statusHeight() + 15).isActive = true
        
        chatView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        chatView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -60).isActive = true
        let chatViewW = Screen.width / 2 * 0.9
        chatViewTrailingConstraint = chatView.trailingAnchor.constraint(equalTo: liveCanvasView.trailingAnchor, constant: -chatViewW)
        chatViewTrailingConstraint?.isActive = true
        chatView.heightAnchor.constraint(equalToConstant: chatViewW).isActive = true
        
        bottomView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        bottomView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        bottomView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        if let vcView = UIViewController.keyWindow{
            vcView.addSubview(playGifView)
            playGifView.leadingAnchor.constraint(equalTo: vcView.leadingAnchor).isActive = true
            playGifView.topAnchor.constraint(equalTo: vcView.topAnchor).isActive = true
            playGifView.trailingAnchor.constraint(equalTo: vcView.trailingAnchor).isActive = true
            playGifView.bottomAnchor.constraint(equalTo: vcView.bottomAnchor).isActive = true
        }
       
        onlineView.topAnchor.constraint(equalTo: avatarview.topAnchor).isActive = true
        onlineView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15).isActive = true
        onlineView.leadingAnchor.constraint(equalTo: avatarview.trailingAnchor, constant: 15).isActive = true
        
        setAvatarName(name: currentUserId, roomId: channelName)
        
        let bottomType: [LiveBottomView.LiveBottomType] = currentUserId == UserInfo.uid ? [.tool, .close] : [.gift, .close]
        bottomView.updateButtonType(type: bottomType)
    }
}

extension LiveBaseView: AGECollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LivePlayerCell.description(),
                                                      for: indexPath) as! LivePlayerCell
        if indexPath.item >= canvasDataArray.count {
            return cell
        }
        let model = canvasDataArray[indexPath.item]
        cell.setupPlayerCanvas(with: model)
        
        if indexPath.item == 0 && currentUserId == UserInfo.uid {// 本房间主播
            setupLocalVideoClosure?(model.canvas)
            
        } else { // 观众
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.setupRemoteVideoClosure?(model)
            }
        }
        return cell
    }
}
