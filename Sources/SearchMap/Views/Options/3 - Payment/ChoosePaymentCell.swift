//
//  File.swift
//  
//
//  Created by GG on 12/02/2021.
//

import UIKit
import LabelExtension
import ATAGroup

class ChoosePaymentCell: UICollectionViewCell {
    @IBOutlet weak var card: UIView! {
        didSet {
//            card.addShadow(roundCorners: false)
            card.layer.borderWidth = 1.0
            card.layer.borderColor = SearchMapController.configuration.palette.inactive.cgColor
            card.layer.cornerRadius = 5.0
        }
    }
    @IBOutlet weak var icon: UIImageView!  {
        didSet {
            icon.tintColor = SearchMapController.configuration.palette.secondary
        }
    }

    @IBOutlet weak var check: UIImageView!  {
        didSet {
            check.layer.cornerRadius = check.bounds.midX
        }
    }
    @IBOutlet weak var paymentTypeContainer: UIView!  {
        didSet {
            paymentTypeContainer.cornerRadius = 5.0
        }
    }

    @IBOutlet weak var paymentType: UILabel!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var subtitle: UILabel!
    
    func updateCheck() {
        check.layer.borderWidth = isSelected ? 0 : 1
        check.layer.borderColor = type.isActive ? SearchMapController.configuration.palette.secondary.cgColor : SearchMapController.configuration.palette.inactive.cgColor
        check.backgroundColor = !isSelected ? SearchMapController.configuration.palette.textOnPrimary : SearchMapController.configuration.palette.secondary
        check.tintColor = !isSelected ? SearchMapController.configuration.palette.secondary : SearchMapController.configuration.palette.textOnPrimary
        check.image =  isSelected ? UIImage(named: "ok") : nil
    }
    
    var type: ChoosePaymentViewModel.CellType!
    func configure(_ paymentType: ChoosePaymentViewModel.CellType, isSelected: Bool) {
        type = paymentType
        self.isSelected = isSelected
        updateCheck()
        icon.image = paymentType.image
        icon.alpha = type.isActive ? 1 : 0.2
        paymentTypeContainer.backgroundColor = paymentType.color
        self.paymentType.set(text: paymentType.typeTitle, for: .caption2, textColor: .white)
        title.set(text: paymentType.title, for: .footnote, textColor: SearchMapController.configuration.palette.secondaryTexts)
        subtitle.set(text: paymentType.subtitle, for: .caption1, textColor: SearchMapController.configuration.palette.inactive)
        subtitle.isHidden = paymentType.subtitle == nil
    }
}
