//
//  File.swift
//  
//
//  Created by GG on 12/02/2021.
//

import UIKit
import LabelExtension
import ATAGroup

class ChooseGroupCell: UICollectionViewCell {
    @IBOutlet weak var card: UIView! {
        didSet {
//            card.addShadow(roundCorners: false)
            card.layer.borderWidth = 1.0
            card.layer.borderColor = SearchMapController.configuration.palette.inactive.cgColor
            card.layer.cornerRadius = 5.0
        }
    }

    @IBOutlet weak var check: UIImageView!  {
        didSet {
            check.layer.cornerRadius = check.bounds.midX
        }
    }
    @IBOutlet weak var groupTypeContainer: UIView!  {
        didSet {
            groupTypeContainer.cornerRadius = 5.0
        }
    }

    @IBOutlet weak var groupType: UILabel!
    @IBOutlet weak var groupName: UILabel!
    @IBOutlet weak var members: UILabel!
    
    func updateCheck() {
        check.layer.borderWidth = isSelected ? 0 : 2
        check.layer.borderColor = SearchMapController.configuration.palette.secondary.cgColor
        check.backgroundColor = !isSelected ? SearchMapController.configuration.palette.textOnPrimary : SearchMapController.configuration.palette.secondary
        check.tintColor = !isSelected ? SearchMapController.configuration.palette.secondary : SearchMapController.configuration.palette.textOnPrimary
        check.image =  isSelected ? UIImage(named: "ok") : nil
    }
    
    
    func configure(_ group: Group, isSelected: Bool) {
        self.isSelected = isSelected
        updateCheck()
        groupTypeContainer.backgroundColor = group.type.color
        groupType.set(text: group.type.name.uppercased(), for: .caption2, textColor: .white)
        groupName.set(text: group.name, for: .body, textColor: SearchMapController.configuration.palette.mainTexts)
        members.set(text: "\(group.activeMembers.count) \("members".bundleLocale())", for: .caption1, textColor: SearchMapController.configuration.palette.inactive)
    }
}
