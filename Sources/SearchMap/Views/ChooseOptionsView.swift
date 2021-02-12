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

protocol BookDelegate: class {
    func book()
    func chooseDate(actualDate: Date, completion: @escaping ((Date) -> Void))
}

class ChooseOptionsView: UIView {
    var mode: DisplayMode = .driver
    
    enum OptionState: Int {
        case taxi = 0, passenger
        var next: OptionState? { OptionState(rawValue: rawValue + 1) }
        var previous: OptionState? { OptionState(rawValue: rawValue - 1) }
    }
    
    var state: OptionState! {
        willSet(newValue) {
            let animator = UIViewPropertyAnimator(duration: 0.1, curve: .easeInOut) { [weak self] in
                guard let self = self else { return }
                switch newValue {
                case .passenger:
                    self.backButton.isHidden = false
                    self.taxiContainer.isHidden = true
                    self.passengerContainer.isHidden = false
                    self.secondaryButton.isHidden = self.mode != .driver
                    self.mainButton.setTitle(self.mode == .driver ? "save for me".bundleLocale() : "book".bundleLocale(), for: .normal)
                    
                case .taxi:
                    self.backButton.isHidden = true
                    self.taxiContainer.isHidden = false
                    self.passengerContainer.isHidden = true
                    self.secondaryButton.isHidden = true
                    self.mainButton.setTitle("next".bundleLocale(), for: .normal)
                    
                default: ()
                }
            }
            animator.startAnimation()
        }
    }
    @IBOutlet weak var title: UILabel!  {
        didSet {
            title.set(text: "Choose your options".bundleLocale(), for: .title2, textColor: SearchMapController.configuration.palette.mainTexts)
        }
    }
    @IBOutlet weak var passengerContainer: UIStackView!  {
        didSet {
            passengerContainer.isHidden = true
        }
    }

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
    @IBOutlet weak var passengerStepper: StepperView!  {
        didSet {
//            passengerStepper.largeComponent = false
            passengerStepper.stepper.limitHitAnimationColor = SearchMapController.configuration.palette.mainTexts
            passengerStepper.title.set(text: "nb passenger".bundleLocale().uppercased(), for: .callout, fontScale: 0.7, textColor: SearchMapController.configuration.palette.inactive)
            passengerStepper.subtitle.set(text: "max available".bundleLocale(), for: .callout, textColor: SearchMapController.configuration.palette.mainTexts)
        }
    }
    @IBOutlet weak var luggagesStepper: StepperView!  {
        didSet {
//            luggagesStepper.largeComponent = false
            luggagesStepper.stepper.limitHitAnimationColor = SearchMapController.configuration.palette.mainTexts
            luggagesStepper.title.set(text: "nb luggages".bundleLocale().uppercased(), for: .callout, fontScale: 0.7, textColor: SearchMapController.configuration.palette.inactive)
            luggagesStepper.subtitle.set(text: "max available".bundleLocale(), for: .callout, textColor: SearchMapController.configuration.palette.mainTexts)
        }
    }

    var vehicles: [VehicleTypeable] = []  {
        didSet {
            viewModel = ChooseOptionsViewModel(vehicles: vehicles)
        }
    }

    var viewModel: ChooseOptionsViewModel!  {
        didSet {
            guard let datasource = vehicleTypeCollectionView?.dataSource as? ChooseOptionsViewModel.DataSource else { return }
            viewModel.applySnapshot(in: datasource)
        }
    }

    @IBOutlet weak var vehicleTypeCollectionView: UICollectionView!  {
        didSet {
            vehicleTypeCollectionView.register(VehicleTypeCell.self, forCellWithReuseIdentifier: "VehicleTypeCell")
            vehicleTypeCollectionView.delegate = self
        }
    }
    @IBOutlet weak var taxiContainer: UIStackView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var textView: GrowingTextView!  {
        didSet {
            textView.text = nil
            textView.placeholder = "enter your message here".local()
            textView.placeholderColor = SearchMapController.configuration.palette.inactive
            textView.font = .applicationFont(ofSize: 17, weight: .regular)
            textView.textColor = SearchMapController.configuration.palette.secondaryTexts
            textView.backgroundColor = SearchMapController.configuration.palette.lightGray
            textView.cornerRadius = 10
            textView.minHeight = 100
            textView.maxHeight = 100
        }
    }
    
    @IBOutlet weak var mainButton: ActionButton!  {
        didSet {
            mainButton.setTitle("next".bundleLocale(), for: .normal)
            mainButton.actionButtonType = .primary
        }
    }
    
    @IBOutlet weak var secondaryButton: ActionButton!  {
        didSet {
            secondaryButton.setTitle("share to groups".bundleLocale(), for: .normal)
            secondaryButton.actionButtonType = .smoked
            secondaryButton.isHidden = true
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
        state = .taxi
        nameTextfield.textfield.placeholder = "Passenger name".bundleLocale()
        let datasource = viewModel.dataSource(for: vehicleTypeCollectionView)
        vehicleTypeCollectionView.dataSource = datasource
        vehicleTypeCollectionView.collectionViewLayout = viewModel.layout()
        viewModel.applySnapshot(in: datasource)
        nameTextfield.isHidden = mode == .passenger
        phoneTextfield.isHidden = mode == .passenger
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
        // booking
        guard let nextState = state.next else {
            return
        }
        state = nextState
    }
    
    @IBAction func secondaryAction() {
        
    }
}

extension ChooseOptionsView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.select(at: indexPath)
    }
}
