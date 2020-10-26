//
//  File.swift
//  
//
//  Created by GG on 23/10/2020.
//

import UIKit
import FontExtension
import LabelExtension

protocol MapLandingViewDelegate: class {
    func search()
}

class MapLandingView: UIView {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var subTitle: UILabel!
    @IBOutlet weak var bottomCard: UIView!  {
        didSet {
            bottomCard.backgroundColor = .white
            bottomCard.layer.cornerRadius = 5.0
            bottomCard.layer.borderWidth = 1.0
            bottomCard.layer.borderColor = #colorLiteral(red: 0.889537096, green: 0.9146017432, blue: 0.9526402354, alpha: 1).cgColor
        }
    }

    @IBOutlet weak var selectDestinationLabel: UILabel!  {
        didSet {
            selectDestinationLabel.set(text: "Enter destination".bundleLocale(), for: FontType.default, textColor: #colorLiteral(red: 0.6176490188, green: 0.6521512866, blue: 0.7114837766, alpha: 1))
        }
    }

    @IBOutlet weak var searchImage: UIImageView!
    weak var delegate: MapLandingViewDelegate?
    
    @IBAction func search() {
        delegate?.search()
    }
}
