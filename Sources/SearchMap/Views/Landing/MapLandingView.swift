//
//  File.swift
//  
//
//  Created by GG on 23/10/2020.
//

import UIKit
import FontExtension
import LabelExtension
import ActionButton
import CoreLocation.CLPlacemark
import ATACommonObjects

protocol MapLandingViewDelegate: NSObjectProtocol {
    func search(animated: Bool)
}

class MapLandingView: UIView {
    @IBOutlet weak var title: UILabel!  {
        didSet {
            title.set(text: "Welcome search title".bundleLocale(), for: .title1, textColor: SearchMapController.configuration.palette.mainTexts)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = SearchMapController.configuration.palette.background
    }

    @IBOutlet weak var subTitle: UILabel!  {
        didSet {
            subTitle.set(text: "Welcome search message".bundleLocale(), for: .body, textColor: SearchMapController.configuration.palette.mainTexts)
        }
    }

    @IBOutlet weak var bottomCard: UIView!  {
        didSet {
            bottomCard.backgroundColor = .white
            bottomCard.layer.cornerRadius = 5.0
            bottomCard.layer.borderWidth = 1.0
            bottomCard.layer.borderColor = SearchMapController.configuration.palette.lightGray.cgColor
        }
    }

    @IBOutlet weak var selectDestinationLabel: UILabel!  {
        didSet {
            selectDestinationLabel.set(text: "Enter destination".bundleLocale(), for: .body, textColor: SearchMapController.configuration.palette.inactive)
        }
    }

    @IBOutlet weak var searchImage: UIImageView!  {
        didSet {
            searchImage.tintColor = SearchMapController.configuration.palette.primary
        }
    }
    @IBOutlet weak var confirmButton: ActionButton!  {
        didSet {
            confirmButton.actionButtonType = .confirmation
            confirmButton.setTitle("confirm".bundleLocale(), for: .normal)
        }
    }
    weak var delegate: MapLandingViewDelegate?
    
    func updateAddress(with placemark: CLPlacemark) {
        selectDestinationLabel.set(text: placemark.formattedAddress, for: .body, textColor: SearchMapController.configuration.palette.secondaryTexts)
    }
    func updateAddress(with address: Address) {
        selectDestinationLabel.set(text: address.address, for: .body, textColor: SearchMapController.configuration.palette.secondaryTexts)
    }
    
    @IBAction func search() {
        delegate?.search(animated: true)
    }
}
