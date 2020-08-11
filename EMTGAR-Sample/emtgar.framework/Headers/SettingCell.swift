//
//  SettingCell.swift
//  emtgar-swift
//
//  Created by Mac mini ssd500 on 20/5/20.
//  Copyright © 2020 Nadia Thailand. All rights reserved.
//

import UIKit
protocol SettingCellDelegate {
    func updateSettingCellSelected(cell: SettingCell)
}

class SettingCell: UITableViewCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var switchBtn: UISwitch!
    var item:SettingList!
    
    var delegate : SettingCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func tapSwitchBtn(_ sender: Any) {
        delegate?.updateSettingCellSelected(cell: self)
    }
    
}
