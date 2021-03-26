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
import GrowingTextView
import SwiftDate
import ATAGroup
import PromiseKit
import ATACommonObjects

class ChoosePassengerOptionsView: UIView {
    public weak var searchMapDelegate: SearchRideDelegate?
    var mode: DisplayMode = .driver
    var availableOptions: [VehicleOption] = []
    
    @IBOutlet weak var title: UILabel!  {
        didSet {
            title.set(text: "Choose your options".bundleLocale().uppercased(), for: .title3, textColor: SearchMapController.configuration.palette.mainTexts)
        }
    }
    @IBOutlet weak var passengerContainer: UIStackView!
    @IBOutlet weak var passengerDetailLabel: UILabel!  {
        didSet {
            passengerDetailLabel.set(text: "passenger details".bundleLocale().uppercased(), for: .callout, fontScale: 0.7, textColor: SearchMapController.configuration.palette.inactive)
        }
    }
    enum FieldType: FieldTypeConfigurable {
        var configuration: FieldTypeConfiguration {
            switch self {
            case .name: return .text
            case .phone: return .phone
            }
        }
        
        var isMandatory: Bool { true }
        
        case name, phone
    }
    @IBOutlet weak var nameTextfield: BorderedTextField!  {
        didSet {
            nameTextfield.textfield.attributedPlaceholder = "Passenger name".bundleLocale().uppercased().asAttributedString(for: .footnote, textColor: SearchMapController.configuration.palette.inactive)
            nameTextfield.borderColor = SearchMapController.configuration.palette.lightGray
            nameTextfield.textfield.textColor = SearchMapController.configuration.palette.secondaryTexts
            nameTextfield.configure(FieldType.name)
            nameTextfield.textfield.delegate = self
        }
    }
    @IBOutlet weak var phoneTextfield: BorderedTextField!  {
        didSet {
            phoneTextfield.textfield.attributedPlaceholder = "Passenger phone".bundleLocale().uppercased().asAttributedString(for: .footnote, textColor: SearchMapController.configuration.palette.inactive)
            phoneTextfield.borderColor = SearchMapController.configuration.palette.lightGray
            phoneTextfield.textfield.textColor = SearchMapController.configuration.palette.secondaryTexts
            phoneTextfield.configure(FieldType.phone)
            phoneTextfield.textfield.delegate = self
        }
    }
    @IBOutlet weak var textView: GrowingTextView!  {
        didSet {
            textView.text = nil
            textView.placeholder = "enter your message here".bundleLocale().uppercased()
            textView.placeholderColor = SearchMapController.configuration.palette.inactive
            textView.font = .applicationFont(forTextStyle: .footnote)
            textView.layer.borderColor = SearchMapController.configuration.palette.lightGray.cgColor
            textView.layer.borderWidth = 1
            textView.cornerRadius = 0
            textView.textColor = SearchMapController.configuration.palette.secondaryTexts
            textView.backgroundColor = .clear
            textView.minHeight = 100
            textView.maxHeight = 100
        }
    }
    
    @IBOutlet weak var mainButton: ActionButton!  {
        didSet {
            mainButton.setTitle("next".bundleLocale(), for: .normal)
            mainButton.actionButtonType = .confirmation
        }
    }
    
    @IBOutlet weak var secondaryButton: ActionButton!  {
        didSet {
            secondaryButton.setTitle("share to groups".bundleLocale(), for: .normal)
            secondaryButton.actionButtonType = .complementary
            secondaryButton.isHidden = true
        }
    }
    weak var delegate: BookDelegate!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        BorderedTextField.borderColor = SearchMapController.configuration.palette.inactive
    }
    
    var booking: CreateRide!
    
    func configure(options configurationOptions: OptionConfiguration,
                   booking: inout CreateRide) {
        self.booking = booking
    }
    
    func enableNextButton() {
        if mode == .driver {
            mainButton.isEnabled = nameTextfield.textfield.text?.isEmpty ?? true == false
                && phoneTextfield.textfield.text?.isEmpty ?? true == false
        } else {
            mainButton.isEnabled = true
        }
        secondaryButton.isEnabled = mainButton.isEnabled
    }
    
    @IBAction func mainAction() {
        // booking
        mainButton.isLoading = true
        switch mode {
        case .driver:
            delegate?
                .save(booking)
                .ensure { [weak self] in
                    self?.mainButton.isLoading = false
                }
                .done({ _ in })
                .catch({ _ in })
            
        case .passenger:
            delegate?.book(booking)
                .ensure { [weak self] in
                    self?.mainButton.isLoading = false
                }
                .done({ _ in })
                .catch({ _ in })
            
        case .business:
            delegate?.book(booking)
                .ensure { [weak self] in
                    self?.mainButton.isLoading = false
                }
                .done({ _ in })
                .catch({ _ in })
        }
    }
    
    @IBAction func secondaryAction() {
        secondaryButton.isLoading = true
        delegate?.share(booking)
    }
    
    func updateBooking() {
        
    }
}

extension ChoosePassengerOptionsView: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        enableNextButton()
        var passenger: Passenger = booking.passenger ?? Passenger()
        if textField === nameTextfield.textfield {
            passenger.lastname = textField.text ?? ""
        } else if textField === phoneTextfield.textfield {
            passenger.phone = textField.text ?? ""
        }
        booking.passenger = passenger
    }
}
