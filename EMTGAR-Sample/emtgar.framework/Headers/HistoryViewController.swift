//
//  HistoryViewController.swift
//  emtgar-swift
//
//  Created by Mac mini ssd500 on 29/4/20.
//  Copyright © 2020 Nadia Thailand. All rights reserved.
//

import UIKit

enum HistoryViewMode {
    case presentView
    case editView
}


class HistoryViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var editBtn: UIButton!
    @IBOutlet weak var deleteBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet weak var menuBtn: UIButton!
    @IBOutlet weak var emptyListLbl: UILabel!
    
    var historyArray:[History] = []
    var viewMode:HistoryViewMode = .presentView
    var removeHistoryArray:[History] = []
    var menuDelegate:MemuControllerDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.historyArray = CMSLoadDataFromFiles.getJsonHistory()
        self.historyArray = self.historyArray.sorted { (first, second) -> Bool in
            return first.date > second.date
        }
        if self.historyArray.count == 0 {
            self.emptyListLbl.alpha = 1.0
            self.editBtn.alpha = 0.0
        } else {
            self.emptyListLbl.alpha = 0.0
            self.editBtn.alpha = 1.0
        }
        tableView.reloadData()
    }
    
    //MARK: - IBAction
    @IBAction func ibaBackBtn(_ sender: Any) {
        menuDelegate?.back(from:"history")
    }
    
    @IBAction func eventTouchUpIndiseRemoveBtn(_ sender: Any) {
        
        if removeHistoryArray.count != 0 {
            let alert = UIAlertController(title: "本当に削除して", message: "よろしいですか？", preferredStyle: .alert)
            let okButton = UIAlertAction(title: "はい", style: .default, handler: { action in
                self.removeSelectedItems()
            })
            let cancelButton = UIAlertAction(title: "いいえ", style: .cancel, handler: { action in
                
            })
            alert.addAction(cancelButton)
            alert.addAction(okButton)
            self.present(alert, animated: true)
        } else {
            removeSelectedItems()
        }
        
    }
    
    @IBAction func ibaCancelBtn(_ sender: Any) {
        removeHistoryArray.removeAll()
        removeSelectedItems()
    }
    
    @IBAction func ibaEditBtn(_ sender: Any) {
        viewMode = .editView
        self.deleteBtn.isHidden = false
        self.cancelBtn.isHidden = false
        self.editBtn.isHidden = true
        self.tableView.reloadData()
        updateRemoveBtn()
    }
    
    func removeSelectedItems() {
        viewMode = .presentView
//        self.tableView.allowsSelection = true
        self.deleteBtn.isHidden = true
        self.cancelBtn.isHidden = true
        self.editBtn.isHidden = false
        if removeHistoryArray.count != 0 {
            historyArray = historyArray.filter{!removeHistoryArray.contains($0)}
            CMSLoadDataFromFiles.saveJsonHistory(historyArray: historyArray)
            removeHistoryArray = []
        }
        self.tableView.reloadData()
    }
    
    func updateRemoveBtn() {
        let frameworkBundle = Bundle().emtgarResourceBundle
        if removeHistoryArray.count != 0 {
            deleteBtn.isUserInteractionEnabled = true
            deleteBtn.setImage(UIImage(named: "trash", in: frameworkBundle, compatibleWith: nil), for: .normal)
        } else {
            deleteBtn.isUserInteractionEnabled = false
            deleteBtn.setImage(UIImage(named: "trash_active", in: frameworkBundle, compatibleWith: nil), for: .normal)
        }
    }
    
    func stringDate(date:Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
    
    deinit {
        print("deinit history")
    }

}


extension HistoryViewController:UITableViewDelegate,UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return historyArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryTableViewCell", for: indexPath) as! HistoryTableViewCell
        cell.delegate = self
        let history = historyArray[indexPath.row]
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let bundleRoot = paths.first
        if let  uwBundleRoot = bundleRoot {
            let filePath = URL(fileURLWithPath: uwBundleRoot).appendingPathComponent(history.pathComponent).relativePath
            if let thumbnail = UIImage(contentsOfFile: filePath) {
                cell.thumbnail.image = thumbnail
            }
        }
        cell.dateLbl.text = stringDate(date: history.date)
        cell.nameLbl.text = history.title
        cell.infoLbl.text = history.detail
        if viewMode == .editView {
            cell.selectImageView.isHidden = false
            let frameworkBundle = Bundle().emtgarResourceBundle
            cell.selectImageView.image = UIImage(named: "check", in: frameworkBundle, compatibleWith: nil)
            cell.selectedCell = false
            cell.history = history
        } else {
            cell.selectImageView.isHidden = true
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if viewMode == .editView {
            guard let cell = tableView.cellForRow(at: indexPath) as? HistoryTableViewCell else {return}
            if cell.selectedCell {
                let frameworkBundle = Bundle().emtgarResourceBundle
                cell.selectImageView.image = UIImage(named: "check", in: frameworkBundle, compatibleWith: nil)
                cell.selectedCell = false
                removeHistoryArray = removeHistoryArray.filter { (history) -> Bool in
                    return history != cell.history
                }
            }
            else {
                let frameworkBundle = Bundle().emtgarResourceBundle
                cell.selectImageView.image = UIImage(named: "check_active", in: frameworkBundle, compatibleWith: nil)
                cell.selectedCell = true
                removeHistoryArray.append(cell.history)
            }
            updateRemoveBtn()
        }
        else {
            menuDelegate?.didSelectHistory(history: historyArray[indexPath.row])
        }
    }

}

extension HistoryViewController: HistoryCellDelegate {
    func updateHistoryCellSelected(cell: HistoryTableViewCell, selected: Bool) {
        if selected {
            removeHistoryArray.append(cell.history)
        } else {
            removeHistoryArray = removeHistoryArray.filter { (history) -> Bool in
                return history != cell.history
            }
        }
        updateRemoveBtn()
    }

}
