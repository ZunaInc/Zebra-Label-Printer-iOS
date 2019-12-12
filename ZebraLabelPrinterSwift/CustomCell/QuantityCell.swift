//
//  QuantityCell.swift
//  ZebraLabelPrinterSwift
//
//  Created by Vijay A on 03/01/19.
//  Copyright © 2019 Goalsr. All rights reserved.
//

import UIKit

class QuantityCell: UITableViewCell {

    @IBOutlet weak var _quantityLabel: UILabel!
    @IBOutlet weak var _addBtn    : UIButton!
    @IBOutlet weak var _removeBtn : UIButton!


    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        _quantityLabel.textColor = UIColor.black
        _quantityLabel.layer.cornerRadius = 7
        _quantityLabel.layer.borderWidth = 0.5
        _quantityLabel.layer.borderColor = UIColor.gray.cgColor

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
}

