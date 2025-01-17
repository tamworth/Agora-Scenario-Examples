//
//  BORCreateRoomController.swift
//  BreakoutRoom
//
//  Created by zhaoyongqiang on 2021/10/29.
//

import UIKit

class BORCreateRoomController: BaseViewController {
    var syncUtil: SceneSyncUtil?
    var createRoomFinished: (() -> Void)?
    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.layer.borderColor = UIColor.systemPink.cgColor
        textField.layer.borderWidth = 1
        textField.layer.cornerRadius = 10
        textField.layer.masksToBounds = true
        textField.textColor = .black
        textField.leftView = UIView(frame: CGRect(x: 10, y: 0, width: 10, height: 0))
        textField.leftViewMode = .always
        textField.font = .systemFont(ofSize: 14)
        textField.placeholder = "Please_enter_a_room_name".localized
        return textField
    }()
    private lazy var createRoomButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "create_room"), for: .normal)
        button.addTarget(self, action: #selector(onTapCreateRoomButton(_:)), for: .touchUpInside)
        return button
    }()
    private var channelName: String?
    
    init(channelName: String? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.channelName = channelName
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "create_room".localized
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        textField.translatesAutoresizingMaskIntoConstraints = false
        createRoomButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textField)
        view.addSubview(createRoomButton)
        textField.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 80).isActive = true
        textField.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 40).isActive = true
        textField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        textField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -40).isActive = true
        
        createRoomButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        createRoomButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40).isActive = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        textField.resignFirstResponder()
    }
    
    @objc
    private func onTapCreateRoomButton(_ sender: UIButton) {
        let text = textField.text ?? ""
        guard !text.isEmpty else {
            ToastView.show(text: "Cant_be_empty".localized)
            return
        }
        guard text.count < 11 else {
            ToastView.show(text: "Over_length_limit".localized)
            return
        }
        guard !text.isChinese(str: text) else {
            ToastView.show(text: "Chinese_not_supported".localized)
            return
        }
        ToastView.showWait(text: "loading".localized, view: view)
        var itemModel = BORLiveModel()
        itemModel.id = text.trimmingCharacters(in: .whitespacesAndNewlines)
        itemModel.backgroundId = String(format: "cover/portrait%02d", Int.random(in: 1...2))
        let params = JSONObject.toJson(itemModel)
        LogUtils.log(message: "params == \(params)", level: .info)
        syncUtil?.joinScene(id: itemModel.id, userId: UserInfo.uid, property: params) { objects in
            NetworkManager.shared.generateToken(channelName: self.textField.text ?? "") {
                let roomDetailVC = BORRoomDetailController(channelName: self.textField.text ?? "",
                                                           ownerId: UserInfo.uid)
                roomDetailVC.syncUtil = self.syncUtil
                self.navigationController?.pushViewController(roomDetailVC, animated: true)
            }
            ToastView.hidden()
        } fail: { error in
            ToastView.hidden()
            LogUtils.log(message: "join scene error == \(error.localizedDescription)", level: .error)
        }

        let roomModel = BORSubRoomModel(subRoom: text)
        let roomParams = JSONObject.toJson(roomModel)
//        SyncUtil.instance.addCollection(id: itemModel.id, className: SYNC_COLLECTION_SUB_ROOM,
//                                        params: roomParams,
//                                        delegate: self)
        createRoomFinished?()
    }
}
