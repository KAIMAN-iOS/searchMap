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

    var _isSelected: Bool = false  {
        didSet {
            button.isSelected = _isSelected
        }
    }
    
    private func addButton() {
        contentView.addSubview(button)
        button.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
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
        _isSelected = isSelected
    }
    
    func configure(_ option: VehicleOption, isSelected: Bool) {
        if button.superview == nil {
            addButton()
        }
        button.setTitle(option.displayText.capitalized, for: .normal)
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.textAlignment = .center
        _isSelected = isSelected
    }
    
    func configureForAllOptions(isSelected: Bool) {
        if button.superview == nil {
            addButton()
        }
        button.setTitle("all".bundleLocale().capitalized, for: .normal)
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.textAlignment = .center
        _isSelected = isSelected
    }
}
