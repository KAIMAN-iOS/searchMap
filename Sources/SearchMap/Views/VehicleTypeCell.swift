//
//  File.swift
//  
//
//  Created by GG on 11/02/2021.
//

import UIKit
import ATAViews
import SnapKit

class VehicleTypeCell: UICollectionViewCell {
    lazy var button: SelectableButton = SelectableButton()
    override var isSelected: Bool  {
        didSet {
            button.isSelected = isSelected
        }
    }
    
    func configure(_ vehicleType: VehicleTypeable, isSelected: Bool) {
        if button.superview == nil {
            contentView.addSubview(button)
            button.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        button.setTitle(vehicleType.displayText, for: .normal)
        button.isSelected = isSelected
    }
}
