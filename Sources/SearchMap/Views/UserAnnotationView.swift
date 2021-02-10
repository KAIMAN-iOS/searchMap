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
    @IBOutlet weak var pickUpLabel: UILabel!  {
        didSet {
            pickUpLabel.set(text: "pick up at".bundleLocale().uppercased(), for: .callout, fontScale: 0.8, textColor: SearchMapController.configuration.palette.inactive)
        }
    }

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
        iconBackground.backgroundColor = tintColor ?? SearchMapController.configuration.palette.primary
    }
    
    var placemark: Placemark!
    func configure(_ placemark: CLPlacemark) {
        self.placemark = placemark.asPlacemark
        destinationLabel.set(text: placemark.formattedAddress, for:.body, textColor: SearchMapController.configuration.palette.mainTexts)
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
