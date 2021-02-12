//
//  File.swift
//  
//
//  Created by GG on 11/02/2021.
//

import UIKit
import ATAViews
import LabelExtension
import Ampersand
import ActionButton
import AlertsAndPickers
import DateExtension

protocol BookDelegate: class {
    func book()
    func chooseDate(actualDate: Date, completion: @escaping ((Date) -> Void))
}

class ChooseOptionsView: UIView {
    @IBOutlet weak var title: UILabel!  {
        didSet {
            title.set(text: "Choose your options".bundleLocale(), for: .title2, textColor: SearchMapController.configuration.palette.mainTexts)
        }
    }
    @IBOutlet weak var passengerContainer: UIStackView!
    @IBOutlet weak var passengerDetailLabel: UILabel!  {
        didSet {
            passengerDetailLabel.set(text: "passenger details".bundleLocale().uppercased(), for: .callout, fontScale: 0.7, textColor: SearchMapController.configuration.palette.inactive)
        }
    }
    @IBOutlet weak var nameTextfield: BorderedTextField!  {
        didSet {
            nameTextfield.textfield.placeholder = "Passenger name".bundleLocale()
        }
    }
    @IBOutlet weak var phoneTextfield: BorderedTextField!  {
        didSet {
            phoneTextfield.textfield.placeholder = "Passenger phone".bundleLocale()
        }
    }
    @IBOutlet weak var stepper: StepperView!
    @IBOutlet weak var vehicleTypeCollectionView: UICollectionView!  {
        didSet {
            vehicleTypeCollectionView.register(VehicleTypeCell.self, forCellWithReuseIdentifier: "VehicleTypeCell")
        }
    }

    @IBOutlet weak var bookButton: ActionButton!  {
        didSet {
            bookButton.setTitle("book".bundleLocale(), for: .normal)
            bookButton.actionButtonType = .primary
        }
    }

    @IBOutlet weak var chooseDateLabel: UILabel!  {
        didSet {
            chooseDateLabel.set(text: "departure date".bundleLocale().uppercased(), for: .callout, fontScale: 0.7, textColor: SearchMapController.configuration.palette.inactive)
        }
    }

    @IBOutlet weak var nowButton: SelectableButton!  {
        didSet {
            nowButton.titleLabel?.font = .applicationFont(forTextStyle: .footnote)
            nowButton.setTitle("now".bundleLocale(), for: .normal)
            nowButton.isSelected = true
            nowButton.buttonCornerRadius = 5.0
            nowButton.addTarget(self, action: #selector(chooseDate(sender:)), for: .touchUpInside)
            nowButton.contentInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        }
    }

    @IBOutlet weak var laterButton: SelectableButton!  {
        didSet {
            laterButton.titleLabel?.font = .applicationFont(forTextStyle: .footnote)
            laterButton.setTitle("later".bundleLocale(), for: .normal)
            laterButton.buttonCornerRadius = 5.0
            laterButton.addTarget(self, action: #selector(chooseDate(sender:)), for: .touchUpInside)
            laterButton.titleLabel?.numberOfLines = 2
            laterButton.titleLabel?.textAlignment = .center
            laterButton.contentInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        }
    }

    private var bookDate: Date = Date()
    var dateWrapper: DateWrapper = .now  {
        didSet {
            switch dateWrapper {
            case .now:
                nowButton.isSelected = true
                
            case .date(let date):
                bookDate = date
                nowButton.isSelected = false
                laterButton.setTitle("""
                                        \(DateFormatter.readableDateFormatter.string(from: date))
                                        \(DateFormatter.timeOnlyFormatter.string(from: date))
                                        """, for: .normal)
            }
            laterButton.isSelected = !nowButton.isSelected
        }
    }
    @IBOutlet weak var vehicleType: UILabel!  {
        didSet {
            vehicleType.set(text: "vehicle type".bundleLocale().uppercased(), for: .callout, fontScale: 0.7, textColor: SearchMapController.configuration.palette.inactive)
        }
    }


    weak var delegate: BookDelegate!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        BorderedTextField.borderColor = SearchMapController.configuration.palette.inactive
        StepperView.stepperColor = SearchMapController.configuration.palette.secondary
        StepperView.stepperTextColor = SearchMapController.configuration.palette.textOnPrimary
        SelectableButton.selectedColor = SearchMapController.configuration.palette.secondary
        SelectableButton.unselectedColor = SearchMapController.configuration.palette.textOnPrimary
    }
    
    func configure() {
        nameTextfield.textfield.placeholder = "Passenger name".bundleLocale()
        stepper.title.set(text: "nb passenger".bundleLocale().uppercased(), for: .callout, fontScale: 0.7, textColor: SearchMapController.configuration.palette.inactive)
        stepper.subtitle.set(text: "max available".bundleLocale(), for: .callout, textColor: SearchMapController.configuration.palette.mainTexts)
        stepper.stepper.limitHitAnimationColor = SearchMapController.configuration.palette.mainTexts
    }
    
    @objc func chooseDate(sender: SelectableButton) {
        if sender === nowButton {
            dateWrapper = .now
        } else {
            dateWrapper = .date(bookDate)
            delegate?.chooseDate(actualDate: bookDate) { [weak self] date in
                self?.dateWrapper = .date(date)
            }
        }
    }
}
