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

protocol BookDelegate: class {
    func book(_ booking: CreateRide) -> Promise<Bool>
    func save(_ booking: CreateRide) -> Promise<Bool>
    func chooseDate(actualDate: Date, completion: @escaping ((Date) -> Void))
    func share(_ booking: CreateRide)
}

class ChooseOptionsView: UIView {
    public weak var searchMapDelegate: SearchRideDelegate?
    var mode: DisplayMode = .driver
    var availableOptions: [VehicleOption] = []
    
    internal enum OptionState: Int {
        case taxi = 0, passenger
        var next: OptionState? { OptionState(rawValue: rawValue + 1) }
        var previous: OptionState? { OptionState(rawValue: rawValue - 1) }
    }
    
    internal var state: OptionState! {
        willSet(newValue) {
            print("state == nil \(state == nil) -> \(newValue)")
            switch newValue {
            case .passenger:
                backButton.isHidden = false
                taxiContainer.isHidden = true
                passengerContainer.isHidden = false
                secondaryButton.isHidden = self.mode != .driver && self.groups.isEmpty == false
                mainButton.setTitle(self.mode == .driver ? "save for me".bundleLocale() : "book".bundleLocale(), for: .normal)
                
            case .taxi:
                backButton.isHidden = true
                taxiContainer.isHidden = false
                passengerContainer.isHidden = true
                secondaryButton.isHidden = true
                mainButton.setTitle("next".bundleLocale(), for: .normal)
                
            default: ()
            }
        }
        
        didSet {
            enableNextButton()
        }
    }
    @IBOutlet weak var title: UILabel!  {
        didSet {
            title.set(text: "Choose your options".bundleLocale().uppercased(), for: .title3, textColor: SearchMapController.configuration.palette.textOnPrimary)
        }
    }
    @IBOutlet weak var passengerContainer: UIStackView!  {
        didSet {
            passengerContainer.isHidden = true
        }
    }

    @IBOutlet weak var passengerDetailLabel: UILabel!  {
        didSet {
            passengerDetailLabel.set(text: "passenger details".bundleLocale().uppercased(), for: .callout, fontScale: 0.7, textColor: SearchMapController.configuration.palette.textOnPrimary)
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
            nameTextfield.textfield.attributedPlaceholder = "Passenger name".bundleLocale().uppercased().asAttributedString(for: .footnote, textColor: SearchMapController.configuration.palette.lightGray)
            nameTextfield.borderColor = SearchMapController.configuration.palette.lightGray
            nameTextfield.textfield.textColor = SearchMapController.configuration.palette.textOnPrimary
            nameTextfield.configure(FieldType.name)
            nameTextfield.textfield.delegate = self
        }
    }
    @IBOutlet weak var phoneTextfield: BorderedTextField!  {
        didSet {
            phoneTextfield.textfield.attributedPlaceholder = "Passenger phone".bundleLocale().uppercased().asAttributedString(for: .footnote, textColor: SearchMapController.configuration.palette.lightGray)
            phoneTextfield.borderColor = SearchMapController.configuration.palette.lightGray
            phoneTextfield.textfield.textColor = SearchMapController.configuration.palette.textOnPrimary
            phoneTextfield.configure(FieldType.phone)
            phoneTextfield.textfield.delegate = self
        }
    }
    @IBOutlet weak var passengerLabel: UILabel!  {
        didSet {
            passengerLabel.set(text: "nb passenger".bundleLocale().uppercased(), for: .callout, fontScale: 0.7, textColor: SearchMapController.configuration.palette.textOnPrimary)
        }
    }

    @IBOutlet weak var passengerStepper: ATAStepper!  {
        didSet {
//            passengerStepper.largeComponent = false
            passengerStepper.addTarget(self, action: #selector(stepperChanged(_:)), for: .valueChanged)
            passengerStepper.limitHitAnimationColor = SearchMapController.configuration.palette.lightGray
            passengerStepper.cornerRadius = 10.0
            passengerStepper.stepperColor = .white
            passengerStepper.stepperTextColor = SearchMapController.configuration.palette.mainTexts
        }
    }
    @IBOutlet weak var luggagesLabel: UILabel!  {
        didSet {
            luggagesLabel.set(text: "nb luggages".bundleLocale().uppercased(), for: .callout, fontScale: 0.7, textColor: SearchMapController.configuration.palette.textOnPrimary)
        }
    }

    @IBOutlet weak var luggagesStepper: ATAStepper!  {
        didSet {
//            luggagesStepper.largeComponent = false
            luggagesStepper.addTarget(self, action: #selector(stepperChanged(_:)), for: .valueChanged)
            luggagesStepper.limitHitAnimationColor = SearchMapController.configuration.palette.lightGray
            luggagesStepper.cornerRadius = 10.0
            luggagesStepper.stepperColor = .white
            luggagesStepper.stepperTextColor = SearchMapController.configuration.palette.mainTexts
        }
    }

    var vehicles: [VehicleType] = []  {
        didSet {
            vehicleTypeViewModel = ChooseVehicleTypeViewModel(vehicles: vehicles)
        }
    }
    
    var vehicleTypeViewModel: ChooseVehicleTypeViewModel!  {
        didSet {
            guard let datasource = vehicleTypeCollectionView?.dataSource as? ChooseVehicleTypeViewModel.DataSource else { return }
            vehicleTypeViewModel.applySnapshot(in: datasource)
        }
    }
    
    var vehicleOptionsViewModel: ChooseOptionsViewModel!  {
        didSet {
            guard let datasource = vehicleOptionCollectionView?.dataSource as? ChooseOptionsViewModel.DataSource else { return }
            vehicleOptionsViewModel.applySnapshot(in: datasource)
        }
    }

    @IBOutlet weak var vehicleTypeCollectionView: UICollectionView!  {
        didSet {
            vehicleTypeCollectionView.register(VehicleTypeCell.self, forCellWithReuseIdentifier: "VehicleTypeCell")
            vehicleTypeCollectionView.delegate = self
        }
    }
    @IBOutlet weak var taxiContainer: UIStackView!  {
        didSet {
            taxiContainer.isHidden = true
        }
    }

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var textView: GrowingTextView!  {
        didSet {
            textView.text = nil
            textView.placeholder = "enter your message here".bundleLocale().uppercased()
            textView.placeholderColor = SearchMapController.configuration.palette.lightGray
            textView.font = .applicationFont(forTextStyle: .footnote)
            textView.layer.borderColor = SearchMapController.configuration.palette.lightGray.cgColor
            textView.layer.borderWidth = 1
            textView.cornerRadius = 0
            textView.textColor = SearchMapController.configuration.palette.textOnPrimary
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

    @IBOutlet weak var chooseDateLabel: UILabel!  {
        didSet {
            chooseDateLabel.set(text: "departure date".bundleLocale().uppercased(), for: .callout, fontScale: 0.7, textColor: SearchMapController.configuration.palette.textOnPrimary)
        }
    }

    @IBOutlet weak var nowButton: SelectableButton!  {
        didSet {
            nowButton.titleLabel?.font = .applicationFont(forTextStyle: .footnote)
            nowButton.selectedColor = .white
            nowButton.unselectedColor = SearchMapController.configuration.palette.secondary
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
            laterButton.selectedColor = .white
            laterButton.unselectedColor = SearchMapController.configuration.palette.secondary
//            laterButton.buttonCornerRadius = 5.0
            laterButton.addTarget(self, action: #selector(chooseDate(sender:)), for: .touchUpInside)
            laterButton.titleLabel?.numberOfLines = 2
            laterButton.titleLabel?.textAlignment = .center
            laterButton.contentInsets = UIEdgeInsets(top: 15, left: 10, bottom: 15, right: 10)
        }
    }
    
    // vehicle options
    @IBOutlet weak var vehicleOptionsContainer: UIStackView!
    @IBOutlet weak var vehicleOptions: UILabel!  {
        didSet {
            vehicleOptions.set(text: "vehicle options".bundleLocale().uppercased(), for: .callout, fontScale: 0.7, textColor: SearchMapController.configuration.palette.textOnPrimary)
        }
    }

    @IBOutlet weak var vehicleOptionCollectionView: UICollectionView!  {
        didSet {
            vehicleOptionCollectionView.register(VehicleTypeCell.self, forCellWithReuseIdentifier: "VehicleTypeCell")
            vehicleOptionCollectionView.delegate = self
        }
    }
    
    @IBAction func back() {
        if let state = self.state.previous {
            self.state = state
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
    @IBOutlet weak var vehicleType: UILabel!  {
        didSet {
            vehicleType.set(text: "vehicle type".bundleLocale().uppercased(), for: .callout, fontScale: 0.7, textColor: SearchMapController.configuration.palette.textOnPrimary)
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
    
    var groups: [Group] = []
    var booking: CreateRide!
    fileprivate func handleVehicleType() {
        let datasource = vehicleTypeViewModel.dataSource(for: vehicleTypeCollectionView)
        vehicleTypeCollectionView.dataSource = datasource
        vehicleTypeCollectionView.collectionViewLayout = vehicleTypeViewModel.layout()
        vehicleTypeViewModel.applySnapshot(in: datasource)
    }
    fileprivate func handleVehicleOptions() {
        vehicleOptionsViewModel = ChooseOptionsViewModel(options: availableOptions, book: &booking)
        let datasource = vehicleOptionsViewModel.dataSource(for: vehicleOptionCollectionView)
        vehicleOptionCollectionView.dataSource = datasource
        vehicleOptionCollectionView.collectionViewLayout = vehicleOptionsViewModel.layout()
        vehicleOptionsViewModel.applySnapshot(in: datasource)
    }
    
    func configure(options configurationOptions: OptionConfiguration,
                   booking: inout CreateRide,
                   state: OptionState = .taxi) {
        self.booking = booking
        self.state = state
        handleVehicleType()
        handleVehicleOptions()
        nameTextfield.isHidden = mode == .passenger
        phoneTextfield.isHidden = mode == .passenger
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
    
    func enableNextButton() {
        switch state {
        case .passenger where mode == .driver:
            mainButton.isEnabled = nameTextfield.textfield.text?.isEmpty ?? true == false
                && phoneTextfield.textfield.text?.isEmpty ?? true == false
            
        default: mainButton.isEnabled = true
        }
        secondaryButton.isEnabled = mainButton.isEnabled
    }
    
    @IBAction func mainAction() {
        // booking
        guard let nextState = state.next else {
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
            return
        }
        state = nextState
    }
    
    @IBAction func secondaryAction() {
        secondaryButton.isLoading = true
        delegate?.share(booking)
    }
    
    func updateBooking() {
        
    }
    
    @objc func stepperChanged(_ stepper: ATAStepper) {
        if stepper === passengerStepper {
            booking.numberOfPassengers = Int(stepper.value)
        } else if stepper === luggagesStepper {
            booking.numberOfLuggages = Int(stepper.value)
        }
    }
}

extension ChooseOptionsView: UITextFieldDelegate {
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

extension ChooseOptionsView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView === vehicleTypeCollectionView {
            vehicleTypeViewModel.select(at: indexPath)
            booking.vehicleType = vehicleTypeViewModel.selectedType()
        } else if collectionView === vehicleOptionCollectionView {
            vehicleOptionsViewModel.select(at: indexPath)
        }
    }
}
