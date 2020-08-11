//
//  SettingViewController.swift
//  emtgar-swift
//
//  Created by Mac mini ssd500 on 20/5/20.
//  Copyright © 2020 Nadia Thailand. All rights reserved.
//

import UIKit
import AVFoundation
import Photos


enum SettingList: String, CaseIterable {
    case camera = "カメラの許可"
    //case notification = "プッシュ通知の許可"
    case cellular = "3G/4Gモバイルデータ通信時、\nメディアをダウンロードする際に\n確認メッセージを表示"
    case photo = "フォトライブラリーの許可"
    //case location = "位置情報の許可"
}


class SettingViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    var settingTitle:[String] = []
    var itemDict:[[String:Any]] = []
    var menuDelegate:MemuControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupData()
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc func setupData() {
        tableView.delegate = self
        tableView.dataSource = self
        itemDict.removeAll()
        for item in SettingList.allCases {
            settingCurrentPermission(item: item)
        }
        tableView.reloadData()
    }
    
    @IBAction func ibaBackBtn(_ sender: Any) {
        menuDelegate?.back(from:"setting")
    }

    func settingCurrentPermission(item:SettingList) {
        switch item {
        case .camera:
            self.addToSettingDic(item: item, allowed: askUserForCameraPermission())
        case .cellular:
            self.addToSettingDic(item: item, allowed: askUserForCellularPermission())
        case .photo:
            self.addToSettingDic(item: item, allowed: askUserForPhotoLibraryPermission())
        }
    }
    
    func askUserForCameraPermission() -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        if status == .authorized {
            return true
        } else {
            return false
        }
    }
    
    func askUserForPhotoLibraryPermission() -> Bool {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .authorized {
            return true
        } else {
            return false
        }
    }
    
    func askUserForCellularPermission() -> Bool {
        return ValidateCellular.allowed
    }
    
    func addToSettingDic(item:SettingList, allowed:Bool) {
        let item = ["item":item,"allowed":allowed] as [String : Any]
        itemDict.append(item)
    }
    
    func updateSelectedCell(item:SettingList) {
        switch item {
        case .camera:
            openSettingPermission()
        case .cellular:
            ValidateCellular.allowed = !ValidateCellular.allowed
        case .photo:
            openSettingPermission()
        }
    }
    
    func openSettingPermission() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsUrl) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    // Finished opening URL
                })
            } else {
                // Fallback on earlier versions
                UIApplication.shared.openURL(settingsUrl)
            }
        }
    }
}

extension SettingViewController:UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        itemDict.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath) as! SettingCell
        cell.delegate = self
        let item = itemDict[indexPath.row]
        cell.item = item["item"] as? SettingList
        cell.title.text = (item["item"] as? SettingList).map { $0.rawValue }
        cell.switchBtn.setOn(item["allowed"] as! Bool, animated: false)
        return cell
    }
    
}

extension SettingViewController:SettingCellDelegate {
    func updateSettingCellSelected(cell: SettingCell) {
        updateSelectedCell(item: cell.item)
    }

}
