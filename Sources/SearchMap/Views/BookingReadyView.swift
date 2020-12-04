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
            title.set(text: "All set".bundleLocale(), for: .title1, textColor: SearchMapController.configuration.palette.mainTexts)
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
