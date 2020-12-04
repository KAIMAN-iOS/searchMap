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
            title.set(text: type.name.capitalized, for: .footnote, textColor: FavouriteListViewController.configuration.palette.inactive)
            icon.image = type.icon
        } else {
            title.set(text: "other".bundleLocale().capitalized, for: .footnote, textColor: FavouriteListViewController.configuration.palette.inactive)
            icon.image = UIImage(named: "historyItem", in: .module, with: nil)?.withRenderingMode(.alwaysTemplate)
        }
    }
    
    @IBAction func select() {
        delegate?.didSelect(self)
    }
}
