//
//  File.swift
//  
//
//  Created by GG on 28/10/2020.
//

import UIKit
import LabelExtension
import FontExtension

protocol FavouriteTypeViewDelegate: class {
    func didSelect(_: FavouriteTypeView)
}

class FavouriteTypeView: UIView {
    var favouriteType: FavouriteType?
    var enabled: Bool = true
    weak var delegate: FavouriteTypeViewDelegate?
    var isSelected: Bool = false  {
        didSet {
            card.layer.borderColor = cardBorderColor.cgColor
            card.backgroundColor = cardBackgroundColor
            title.set(text: title.text, for: .footnote, textColor: textColor)
            icon.tintColor = textColor
        }
    }
    var textColor: UIColor {
        isSelected ? SearchMapController.configuration.palette.textOnPrimary : SearchMapController.configuration.palette.inactive
    }
    var cardBackgroundColor: UIColor {
        isSelected ? SearchMapController.configuration.palette.secondary : SearchMapController.configuration.palette.background
    }
    var cardBorderColor: UIColor {
        isSelected ? SearchMapController.configuration.palette.secondary : SearchMapController.configuration.palette.inactive
    }
    
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var card: UIView!  {
        didSet {
            card.addCardBorder(with: SearchMapController.configuration.palette.inactive)
            card.cornerRadius = 5.0
        }
    }
    
    func configure(_ favouriteType: FavouriteType?) {
        if let type = favouriteType {
            title.set(text: type.name.capitalized, for: .footnote, textColor: textColor)
            icon.image = type.icon?.withRenderingMode(.alwaysTemplate)
        } else {
            title.set(text: "other".bundleLocale().capitalized, for: .footnote, textColor: textColor)
            icon.image = UIImage(named: "historyItem", in: .module, with: nil)?.withRenderingMode(.alwaysTemplate)
        }
    }
    
    @IBAction func select() {
        delegate?.didSelect(self)
        isSelected.toggle()
    }
}
