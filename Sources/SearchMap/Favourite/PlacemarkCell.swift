//
//  File.swift
//  
//
//  Created by GG on 26/10/2020.
//

import UIKit
import TableViewExtension
import MapKit
import LabelExtension
import FontExtension

class PlacemarkCell: UITableViewCell {
    override func awakeFromNib() {
        super.awakeFromNib()
        addDefaultSelectedBackground(FavouriteListViewController.configuration.palette.primary.withAlphaComponent(0.5))
        contentView.backgroundColor = SearchMapController.configuration.palette.background
    }
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var favButton: FavoriteButton!
    
    func configure(_ model: PlacemarkCellType) {
        switch model {
        case .specificFavourite(let type, let place): configure(type, place: place)
        case .favourite(let place): configure(place)
        case .history(let place): configure(place, iconTintColor: FavouriteListViewController.configuration.palette.inactive)
        case .search(let place): configure(place)
        }
    }
    
    
    func configure(_ favType: FavouriteType, place placemark: Placemark?) {
        icon.backgroundColor = #colorLiteral(red: 0.889537096, green: 0.9146017432, blue: 0.9526402354, alpha: 1)
        address.isHidden = true
        name.set(text: placemark?.name ?? favType.name, for: .body, textColor: placemark == nil ? FavouriteListViewController.configuration.palette.inactive : FavouriteListViewController.configuration.palette.mainTexts)
        icon.image = favType.icon
    }
    
    func configure(_ placemark: Placemark, iconTintColor: UIColor = FavouriteListViewController.configuration.palette.primary) {
        icon.backgroundColor = .clear
        icon.tintColor = iconTintColor
        icon.image = UIImage(named: "historyItem", in: .module, with: nil)
        name.set(text: placemark.name, for: .body, textColor: FavouriteListViewController.configuration.palette.mainTexts)
        if placemark.address?.isEmpty == false {
            address.isHidden = false
            address.set(text: placemark.address, for: .footnote, textColor: FavouriteListViewController.configuration.palette.inactive)
        } else {
            address.isHidden = true
        }
    }
}
