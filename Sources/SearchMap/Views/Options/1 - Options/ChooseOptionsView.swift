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

protocol BookDelegate: NSObjectProtocol {
    func book(_ booking: CreateRide) -> Promise<Bool>
    func save(_ booking: CreateRide) -> Promise<Bool>
    func share(_ booking: CreateRide)
}

protocol ChooseDateDelegate: NSObjectProtocol {
    func chooseDate(actualDate: Date, completion: @escaping ((Date) -> Void))
}

protocol OptionViewDelegate: NSObjectProtocol {
    func next() 
}

internal enum OptionState: Int {
    case `default` = 0, vehicleOptions, payment, passenger
    func next(for mode: DisplayMode) -> OptionState? {
        switch (mode, self) {
        case (.driver, .vehicleOptions): return .passenger
        default: return OptionState(rawValue: rawValue + 1)
        }
    }
    
    func previous(for mode: DisplayMode) -> OptionState? {
        switch (mode, self) {
        case (.driver, .passenger): return .vehicleOptions
        default: return OptionState(rawValue: rawValue - 1)
        }
    }
}

class ChooseOptionsView: UIView {
    public weak var searchMapDelegate: SearchRideDelegate?
    weak var nextDelegate: OptionViewDelegate!
    var mode: DisplayMode = .driver
    var availableOptions: [VehicleOption] = []
    weak var delegate: ChooseDateDelegate!
    
    @IBOutlet weak var title: UILabel!  {
        didSet {
            title.set(text: "Choose your options".bundleLocale().capitalizingFirstLetter(), for: .title1, textColor: SearchMapController.configuration.palette.mainTexts)
        }
    }
    @IBOutlet weak var passengerLabel: UILabel!  {
        didSet {
            passengerLabel.set(text: "nb passenger".bundleLocale().uppercased(), for: .callout, fontScale: 0.7, textColor: SearchMapController.configuration.palette.secondaryTexts)
        }
    }

    @IBOutlet weak var passengerStepper: ATAStepper!  {
        didSet {
//            passengerStepper.largeComponent = false
            passengerStepper.addTarget(self, action: #selector(stepperChanged(_:)), for: .valueChanged)
            passengerStepper.limitHitAnimationColor = SearchMapController.configuration.palette.lightGray
            passengerStepper.cornerRadius = 10.0
//            passengerStepper.stepperColor = SearchMapController.configuration.palette.secondary
//            passengerStepper.stepperTextColor = SearchMapController.configuration.palette.textOnDark
        }
    }
    @IBOutlet weak var luggagesLabel: UILabel!  {
        didSet {
            luggagesLabel.set(text: "nb luggages".bundleLocale().uppercased(), for: .callout, fontScale: 0.7, textColor: SearchMapController.configuration.palette.secondaryTexts)
        }
    }

    @IBOutlet weak var luggagesStepper: ATAStepper!  {
        didSet {
//            luggagesStepper.largeComponent = false
            luggagesStepper.addTarget(self, action: #selector(stepperChanged(_:)), for: .valueChanged)
            luggagesStepper.limitHitAnimationColor = SearchMapController.configuration.palette.lightGray
            luggagesStepper.cornerRadius = 10.0
//            luggagesStepper.stepperColor = SearchMapController.configuration.palette.secondary
//            luggagesStepper.stepperTextColor = SearchMapController.configuration.palette.textOnDark
        }
    }
    @IBOutlet weak var mainButton: ActionButton!  {
        didSet {
            mainButton.setTitle("next".bundleLocale(), for: .normal)
            mainButton.actionButtonType = .confirmation
        }
    }
    @IBOutlet weak var chooseDateLabel: UILabel!  {
        didSet {
            chooseDateLabel.set(text: "departure date".bundleLocale().uppercased(), for: .callout, fontScale: 0.7, textColor: SearchMapController.configuration.palette.secondaryTexts)
        }
    }

    @IBOutlet weak var nowButton: SelectableButton!  {
        didSet {
            nowButton.titleLabel?.font = .applicationFont(forTextStyle: .footnote)
//            nowButton.selectedColor = SearchMapController.configuration.palette.secondary
//            nowButton.unselectedColor = SearchMapController.configuration.palette.textOnDark
            nowButton.setTitle("now".bundleLocale(), for: .normal)
            nowButton.isSelected = true
//            nowButton.buttonCornerRadius = 5.0
            nowButton.addTarget(self, action: #selector(chooseDate(sender:)), for: .touchUpInside)
            nowButton.contentInsets = UIEdgeInsets(top: 15, left: 10, bottom: 15, right: 10)
        }
    }

    @IBOutlet weak var laterButton: SelectableButton!  {
        didSet {
            laterButton.titleLabel?.font = .applicationFont(forTextStyle: .footnote)
            laterButton.setTitle("later".bundleLocale(), for: .normal)
//            laterButton.selectedColor = SearchMapController.configuration.palette.secondary
//            laterButton.unselectedColor = SearchMapController.configuration.palette.textOnDark
//            laterButton.buttonCornerRadius = 5.0
            laterButton.addTarget(self, action: #selector(chooseDate(sender:)), for: .touchUpInside)
            laterButton.titleLabel?.numberOfLines = 2
            laterButton.titleLabel?.textAlignment = .center
            laterButton.contentInsets = UIEdgeInsets(top: 15, left: 10, bottom: 15, right: 10)
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
                nowButton.contentInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
                laterButton.contentInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
            }
            laterButton.isSelected = !nowButton.isSelected
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        StepperView.stepperColor = SearchMapController.configuration.palette.secondary
        StepperView.stepperTextColor = SearchMapController.configuration.palette.textOnPrimary
    }
    
    var booking: CreateRide!
    func configure(options configurationOptions: OptionConfiguration,
                   booking: inout CreateRide) {
        self.booking = booking
        passengerStepper.value = Double(booking.ride.numberOfPassengers)
        luggagesStepper.value = Double(booking.ride.numberOfLuggages)
        if let start = booking.ride.startDate?.value {
            dateWrapper = start.timeIntervalSinceNow < 60 ? .now : .date(start)
        } else {
            dateWrapper = .now
        }
        passengerStepper.minimumValue = Double(configurationOptions.passengerConfiguration.minValue)
        passengerStepper.maximumValue = Double(configurationOptions.passengerConfiguration.maxValue)
        luggagesStepper.minimumValue = Double(configurationOptions.luggagesConfiguration.minValue)
        luggagesStepper.maximumValue = Double(configurationOptions.luggagesConfiguration.maxValue)
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
    
    @IBAction func mainAction() {
        switch dateWrapper {
        case .now:
            booking.ride.startDate = CustomDate<GMTISODateFormatterDecodable>(date: Date())
            booking.ride.isImmediate = true
            booking.ride.state = .pending
        case .date(let date):
            booking.ride.startDate = CustomDate<GMTISODateFormatterDecodable>(date: date)
            booking.ride.isImmediate = false
            booking.ride.state = .booked
        }
        nextDelegate?.next()
    }
    
    @objc func stepperChanged(_ stepper: ATAStepper) {
        if stepper === passengerStepper {
            booking.ride.numberOfPassengers = Int(stepper.value)
        } else if stepper === luggagesStepper {
            booking.ride.numberOfLuggages = Int(stepper.value)
        }
    }
}
