//
//  File.swift
//  
//
//  Created by GG on 11/02/2021.
//

import UIKit
import ATAViews
import SnapKit
import ATACommonObjects

class VehicleTypeCell: UICollectionViewCell {
    lazy var button: SelectableButton = SelectableButton()

    override var isSelected: Bool  {
        didSet {
            button.isSelected = isSelected
        }
    }
    
    private func addButton() {
        contentView.addSubview(button)
        button.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        button.selectedColor = SearchMapController.configuration.palette.secondary
        button.unselectedColor = SearchMapController.configuration.palette.background
        button.isUserInteractionEnabled = false
        button.titleLabel?.font = .applicationFont(forTextStyle: .caption1)
        button.titleLabel?.minimumScaleFactor = 0.5
        button.titleLabel?.adjustsFontSizeToFitWidth = true
    }
    
    func configure(_ vehicleType: VehicleType, isSelected: Bool) {
        if button.superview == nil {
            addButton()
        }
        button.setTitle(vehicleType.displayText.capitalized, for: .normal)
        button.isSelected = isSelected
    }
    
    func configure(_ option: VehicleOption, isSelected: Bool) {
        if button.superview == nil {
            addButton()
        }
        button.setTitle(option.displayText.capitalized, for: .normal)
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.textAlignment = .center
        button.isSelected = isSelected
    }
}
