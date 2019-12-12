//
//  PrintLabelCell.swift
//  ZebraLabelPrinterSwift
//
//  Created by Sachin Pampannavar on 11/5/19.
//  Copyright © 2019 Goalsr. All rights reserved.
//

import UIKit

class PrintLabelCell: UITableViewCell {

    //MARK: IBOutlet
    @IBOutlet weak var barCodeImageView: UIImageView!
    @IBOutlet weak var skuUPCLable: UILabel!
    @IBOutlet weak var productName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
