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
    @IBOutlet weak var favButton: FavoriteButton!  {
        didSet {
            favButton.addTarget(self, action: #selector(favStateChanged), for: .touchUpInside)
        }
    }
    weak var refreshDelegate: RefreshFavouritesDelegate?
    weak var favDelegate: FavouriteDelegate!
    @objc func favStateChanged() {
        guard let placemark = placemark.placemark else { return }
        var forceSearch = true
        if case PlacemarkCellType.search(placemark) = self.placemark! {
            forceSearch = false
        }
        if favButton.isSelected {
            favDelegate
                .didDeleteFavourite(placemark)
                .done { [weak self] success in
                    if success {
                        self?.favButton.handleState()
                        self?.refreshDelegate?.refresh(force: forceSearch)
                    }
                }
                .catch({ _ in })
        } else {
            favDelegate
                .didAddFavourite(placemark)
                .done { [weak self] _ in
                    self?.favButton.handleState()
                    self?.refreshDelegate?.refresh(force: forceSearch)
                }
                .catch({ _ in })
        }
    }
    
    var placemark: PlacemarkCellType!
    func configure(_ model: PlacemarkCellType, displayMode: DisplayMode) {
        favButton.isHidden = displayMode != .passenger
        placemark = model
        switch model {
        case .specificFavourite(let type, let place): configure(type, place: place)
        case .favourite(let place): configure(place, favButtonSelected: true)
        case .history(let place): configure(place, iconTintColor: FavouriteListViewController.configuration.palette.inactive)
        case .search(let place): configure(place)
        }
    }
    
    func configure(_ favType: FavouriteType, place placemark: Placemark?) {
        favButton.isSelected = placemark != nil
        icon.backgroundColor = FavouriteListViewController.configuration.palette.lightGray
        icon.tintColor = FavouriteListViewController.configuration.palette.inactive
        address.isHidden = true
        name.set(text: placemark?.name ?? favType.name, for: .body, textColor: placemark == nil ? FavouriteListViewController.configuration.palette.inactive : FavouriteListViewController.configuration.palette.mainTexts)
        icon.image = favType.icon
    }
    
    func configure(_ placemark: Placemark, favButtonSelected: Bool = false, iconTintColor: UIColor = FavouriteListViewController.configuration.palette.primary) {
        favButton.isSelected = favButtonSelected
        icon.backgroundColor = .clear
        icon.tintColor = iconTintColor
        if let favType = placemark.specialFavourite {
            icon.backgroundColor = iconTintColor
            icon.tintColor = .white
            icon.image =  favType.icon ?? UIImage(named: "historyItem", in: .module, with: nil)
        } else {
            icon.image =  UIImage(named: "historyItem", in: .module, with: nil)
            icon.backgroundColor = .clear
            icon.tintColor = iconTintColor
        }
        name.set(text: placemark.name, for: .body, textColor: FavouriteListViewController.configuration.palette.mainTexts)
        if placemark.address?.isEmpty == false {
            address.isHidden = false
            address.set(text: placemark.address, for: .footnote, textColor: FavouriteListViewController.configuration.palette.inactive)
        } else {
            address.isHidden = true
        }
    }
}
