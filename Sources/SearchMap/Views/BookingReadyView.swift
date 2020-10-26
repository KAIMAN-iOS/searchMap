//
//  File.swift
//  
//
//  Created by GG on 24/10/2020.
//

import UIKit
import ActionButton
import FontExtension
import LabelExtension

protocol BookingReadyDelegate: class {
    func book()
}

class BookingReadyView: UIView {
    @IBOutlet weak var title: UILabel!  {
        didSet {
            title.set(text: "All set".bundleLocale(), for: FontType.title, textColor: #colorLiteral(red: 0.1234303191, green: 0.1703599989, blue: 0.2791167498, alpha: 1))
        }
    }

    @IBOutlet weak var bookButton: ActionButton!  {
        didSet {
            bookButton.shape = .rounded(value: 10.0)
            bookButton.setTitle("Launch search".bundleLocale().uppercased(), for: .normal)
        }
    }
    weak var delegate: BookingReadyDelegate?
    
    @IBAction func book() {
        delegate?.book()
    }
}
