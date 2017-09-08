//
//  CustomLabelViewCell.swift
//  Ziro
//
//  Created by Eric on 8/6/17.
//  Copyright © 2017 Zixia. All rights reserved.
//

import Foundation
import UIKit

class CustomTableViewCell: UITableViewCell {
	@IBOutlet weak var cellName: UILabel!
	@IBOutlet weak var startTime: UILabel!
	
	@IBOutlet weak var endTime: UILabel!
	
	@IBOutlet weak var cellImage: UIImageView!
	override func awakeFromNib() {
		super.awakeFromNib()
		// Initialization code
		
	}
}
