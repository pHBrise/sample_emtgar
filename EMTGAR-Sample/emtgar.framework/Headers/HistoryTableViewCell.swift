//
//  HistoryTableViewCell.swift
//  emtgar-swift
//
//  Created by Mac mini ssd500 on 29/4/20.
//  Copyright © 2020 Nadia Thailand. All rights reserved.
//

import UIKit

protocol HistoryCellDelegate {
    func updateHistoryCellSelected(cell: HistoryTableViewCell,selected : Bool)
}

class HistoryTableViewCell: UITableViewCell {
    
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var dateLbl: UILabel!
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var infoLbl: UILabel!
    @IBOutlet weak var selectImageView: UIImageView!
    var selectedCell:Bool = false
    var history:History!
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    var delegate : HistoryCellDelegate?

    @IBAction func ibaSelectBtn(_ sender: Any) {
        // updateSelectCell()
    }
    
//    func updateSelectCell() {
//        let frameworkBundle = Bundle(identifier: "com.classkobukuro")
//        if (!selectedCell) {
//            selectedCell = true
//            selectBtn.setImage(UIImage(named: "check_active", in: frameworkBundle, compatibleWith: nil), for: .normal)
//        } else {
//            selectedCell = false
//            selectBtn.setImage(UIImage(named: "check", in: frameworkBundle, compatibleWith: nil), for: .normal)
//        }
//        delegate?.updateHistoryCellSelected(cell: self, selected: selectedCell)
//    }
}
