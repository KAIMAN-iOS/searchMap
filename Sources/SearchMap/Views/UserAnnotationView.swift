//
//  File.swift
//  
//
//  Created by GG on 23/10/2020.
//

import UIKit
import MapKit
import LabelExtension
import Contacts
import FontExtension

class UserAnnotationView: MKAnnotationView {
    @IBOutlet weak var pickUpLabel: UILabel!
    @IBOutlet weak var destinationLabel: UILabel!
    @IBOutlet weak var card: UIView!  {
        didSet {
            card.layer.cornerRadius = 5.0
            card.clipsToBounds = true
        }
    }

    @IBOutlet weak var iconBackground: UIView!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        iconBackground.backgroundColor = tintColor ?? #colorLiteral(red: 1, green: 0.192286253, blue: 0.2298730612, alpha: 1)
    }
    
    var placemark: CLPlacemark!
    func configure(_ placemark: CLPlacemark) {
        self.placemark = placemark
        destinationLabel.set(text: placemark.formattedAddress, for:FontType.default, textColor: #colorLiteral(red: 0.1234303191, green: 0.1703599989, blue: 0.2791167498, alpha: 1))
    }
}

extension CLPlacemark {
    var formattedAddress: String? {
        guard let postalAddress = postalAddress else {
            return nil
        }
        let formatter = CNPostalAddressFormatter()
        return formatter.string(from: postalAddress).replacingOccurrences(of: "\n", with: ", ")
    }
}
