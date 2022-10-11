//
//  SmallClassRoomListController.swift
//  Scene-Examples
//
//  Created by wushengtao on 2022/10/11.
//

import Foundation
import UIKit
//import AgoraSyncManager
import Agora_Scene_Utils

@objc
class SmallClassRoomListController: BaseViewController {
    lazy var syncUtil: SceneSyncUtil = SceneSyncUtil()
    private lazy var tableView: AGETableView = {
        let view = AGETableView()
        view.rowHeight = 58
        view.delegate = self
        view.emptyTitleColor = .white
        view.addRefresh()
        view.register(LiveRoomListCell.self,
                      forCellWithReuseIdentifier: LiveRoomListCell.description())
        return view
    }()
    private lazy var createLiveButton: UIButton = {
        let button = UIButton()
        button.setBackgroundImage(UIImage(named: "create_room"), for: .normal)
        button.addTarget(self, action: #selector(onTapCreateLiveButton), for: .touchUpInside)
        return button
    }()
    private lazy var bannerView: InteractiveBlogBannerView = {
        let view = InteractiveBlogBannerView()
        view.isHidden = true
        view.onTapInteractiveBlogExitClosure = { [weak self] in
            self?.createLiveButton.isHidden = false
            view.isHidden = true
            self?.getLiveData()
        }
        view.onTapInteractiveBlogBannerViewClosure = { [weak self] channelName in
            guard let self = self else { return }
            self.createLiveButton.isHidden = false
            let roomInfo = self.dataArray.first(where: { $0.roomId == channelName })
            let params = JSONObject.toJson(roomInfo)
            self.syncUtil.joinScene(id: roomInfo?.roomId ?? "",
                               userId: roomInfo?.userId ?? "",
                               property: params,
                               success: { result in
                let channelName = result.getPropertyWith(key: "roomId", type: String.self) as? String
                let ownerId = result.getPropertyWith(key: "userId", type: String.self) as? String
                NetworkManager.shared.generateToken(channelName: channelName ?? "", uid: UserInfo.userId) {
                    let interactiveBlogVC = InteractiveBlogController(channelName: channelName ?? "", userId: ownerId ?? "", isAddUser: false)
                    self.navigationController?.pushViewController(interactiveBlogVC, animated: true)
                }
            })
        }
        interactiveBlogDownPullClosure = { [weak self] channelName, userModel, agoraKit, role in
            guard let self = self else { return }
            self.bannerView.isHidden = false
            self.createLiveButton.isHidden = true
            self.bannerView.setupParams(channelName: channelName, model: userModel, agoraKit: agoraKit, role: role)
        }
        return view
    }()
    private var dataArray = [LiveRoomInfo]()
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationTransparent(isTransparent: false)
        let appdelegate = UIApplication.shared.delegate as? AppDelegate
        appdelegate?.blockRotation = .portrait
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        getLiveData()
    }
    
    private func getLiveData() {
        guard syncUtil.inited else {
            syncUtil.initSyncManager(sceneId: "SmallClassRoomListController") { [weak self] in
                guard self?.syncUtil.inited ?? false else {
                    return
                }
                
                self?.getLiveData()
            }
            
            return
        }
            
        ToastView.showWait(text: "loading".localized, view: view)
        syncUtil.fetchAll { results in
            ToastView.hidden()
            self.tableView.endRefreshing()
            print("result == \(results.compactMap{ $0.toJson() })")
            self.dataArray = results.compactMap({ $0.toJson() }).compactMap({ JSONObject.toModel(LiveRoomInfo.self, value: $0 )})
            self.tableView.dataArray = self.dataArray
        } fail: { error in
            ToastView.hidden()
            self.tableView.endRefreshing()
            LogUtils.log(message: "get live data error == \(error.localizedDescription)", level: .info)
        }
    }
    
    private func setupUI() {
        tableView.backgroundColor = view.backgroundColor
        view.addSubview(tableView)
        view.addSubview(createLiveButton)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        createLiveButton.translatesAutoresizingMaskIntoConstraints = false
        createLiveButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -25).isActive = true
        createLiveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -35).isActive = true
        
        view.addSubview(bannerView)
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        bannerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15).isActive = true
        bannerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(Screen.safeAreaBottomHeight() + 30)).isActive = true
        bannerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15).isActive = true
    }
    
    @objc
    private func onTapCreateLiveButton() {
//        let model = dataArray.filter({ $0.userId == UserInfo.uid }).first
//        if model != nil {
//            showAlert(title: "you_have_created_the_room_will_jump_into_you".localized, message: "") {
//                let params = JSONObject.toJson(model)
//                SyncUtil.joinScene(id: model?.roomId ?? "",
//                                   userId: model?.userId ?? "",
//                                   property: params, success: { result in
//                    self.joinSceneHandler(result: result)
//                })
//            }
//            return
//        }
            let createLiveVC = SmallClassCreateController()
            createLiveVC.syncUtil = self.syncUtil
            navigationController?.pushViewController(createLiveVC, animated: true)
        
    }
    
    private func joinSceneHandler(result: IObject) {
        let channelName = result.getPropertyWith(key: "roomId", type: String.self) as? String
        let ownerId = result.getPropertyWith(key: "userId", type: String.self) as? String
        let vc = SmallClassController(channelName: channelName ?? "",
                                      userId: ownerId ?? "")
        navigationController?.pushViewController(vc, animated: true)

    }
}

extension SmallClassRoomListController: AGETableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = dataArray[indexPath.item]
        let params = JSONObject.toJson(item)
        syncUtil.joinScene(id: item.roomId, userId: item.userId, property: params, success: { result in
            let channelName = result.getPropertyWith(key: "roomId", type: String.self) as? String
            NetworkManager.shared.generateToken(channelName: channelName ?? "") {
                self.joinSceneHandler(result: result)
            }
        })
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: LiveRoomListCell.description(), for: indexPath) as! LiveRoomListCell
        
        cell.setRoomInfo(info: dataArray[indexPath.item])
        return cell
    }
    func pullToRefreshHandler() {
        getLiveData()
    }
}
