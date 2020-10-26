//
//  File.swift
//  
//
//  Created by GG on 26/10/2020.
//

import UIKit
import FontExtension
import LabelExtension

class BookingTopView: UIView {
    @IBOutlet weak var originLabel: UILabel!
    @IBOutlet weak var destinationLabel: UILabel!
    
    func configure(_ booking: BookingWrapper) {
        originLabel.set(text: booking.origin?.name, for: FontType.footnote, textColor: #colorLiteral(red: 0.1234303191, green: 0.1703599989, blue: 0.2791167498, alpha: 1))
        destinationLabel.set(text: booking.destination?.name, for: FontType.footnote, textColor: #colorLiteral(red: 0.1234303191, green: 0.1703599989, blue: 0.2791167498, alpha: 1))
    }
}
