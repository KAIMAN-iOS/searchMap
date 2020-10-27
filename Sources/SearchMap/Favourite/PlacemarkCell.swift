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
        addDefaultSelectedBackground(#colorLiteral(red: 1, green: 0.192286253, blue: 0.2298730612, alpha: 1).withAlphaComponent(0.5))
    }
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var address: UILabel!
    
    
    func configure(_ model: PlacemarkCellType) {
        switch model {
        case .specificFavourite(let type, let place): configure(type, place: place)
        case .favourite(let place): configure(place)
        case .history(let place): configure(place, iconTintColor: #colorLiteral(red: 0.6176490188, green: 0.6521512866, blue: 0.7114837766, alpha: 1))
        case .search(let place): configure(place)
        }
    }
    
    
    func configure(_ favType: FavouriteType, place placemark: Placemark?) {
        icon.backgroundColor = #colorLiteral(red: 0.889537096, green: 0.9146017432, blue: 0.9526402354, alpha: 1)
        address.isHidden = true
        name.set(text: placemark?.name ?? favType.name, for: FontType.default, textColor: placemark == nil ? #colorLiteral(red: 0.6176490188, green: 0.6521512866, blue: 0.7114837766, alpha: 1) : #colorLiteral(red: 0.1234303191, green: 0.1703599989, blue: 0.2791167498, alpha: 1))
        icon.image = favType.icon
    }
    
    func configure(_ placemark: Placemark, iconTintColor: UIColor = #colorLiteral(red: 1, green: 0.192286253, blue: 0.2298730612, alpha: 1)) {
        icon.backgroundColor = .clear
        icon.tintColor = iconTintColor
        icon.image = UIImage(named: "historyItem", in: .module, with: nil)
        name.set(text: placemark.name, for: FontType.default, textColor: #colorLiteral(red: 0.1234303191, green: 0.1703599989, blue: 0.2791167498, alpha: 1))
        if placemark.address?.isEmpty == false {
            address.isHidden = false
            address.set(text: placemark.address, for: FontType.footnote, textColor: #colorLiteral(red: 0.6176490188, green: 0.6521512866, blue: 0.7114837766, alpha: 1))
        } else {
            address.isHidden = true
        }
    }
}
