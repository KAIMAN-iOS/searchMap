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

class ChooseVehicleOptionsView: UIView {
    weak var nextDelegate: OptionViewDelegate!
    public weak var searchMapDelegate: SearchRideDelegate?
    var mode: DisplayMode = .driver
    var availableOptions: [VehicleOption] = []
    
    @IBOutlet weak var title: UILabel!  {
        didSet {
            title.set(text: "options".bundleLocale().capitalizingFirstLetter(), for: .title1, textColor: SearchMapController.configuration.palette.mainTexts)
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
    
    @IBOutlet weak var mainButton: ActionButton!  {
        didSet {
            mainButton.setTitle("next".bundleLocale(), for: .normal)
            mainButton.actionButtonType = .confirmation
        }
    }
    // vehicle options
    @IBOutlet weak var vehicleOptionsContainer: UIStackView!
    @IBOutlet weak var vehicleOptions: UILabel!  {
        didSet {
            vehicleOptions.set(text: "vehicle options".bundleLocale().uppercased(), for: .callout, fontScale: 0.7, textColor: SearchMapController.configuration.palette.secondaryTexts)
        }
    }

    @IBOutlet weak var vehicleOptionCollectionView: UICollectionView!  {
        didSet {
            vehicleOptionCollectionView.register(VehicleTypeCell.self, forCellWithReuseIdentifier: "VehicleTypeCell")
            vehicleOptionCollectionView.delegate = self
        }
    }
    @IBOutlet weak var vehicleType: UILabel!  {
        didSet {
            vehicleType.set(text: "vehicle type".bundleLocale().uppercased(), for: .callout, fontScale: 0.7, textColor: SearchMapController.configuration.palette.secondaryTexts)
        }
    }
    weak var delegate: BookDelegate!
    
    override func awakeFromNib() {
        super.awakeFromNib()    }
    
    var groups: [Group] = []
    var booking: CreateRide!
    fileprivate func handleVehicleType() {
        let datasource = vehicleTypeViewModel.dataSource(for: vehicleTypeCollectionView)
        vehicleTypeCollectionView.dataSource = datasource
        vehicleTypeCollectionView.collectionViewLayout = vehicleTypeViewModel.layout()
        vehicleTypeViewModel.select(booking.options.vehicleType)
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
                   booking: inout CreateRide) {
        self.booking = booking
        handleVehicleType()
        handleVehicleOptions()
    }
    
    @IBAction func mainAction() {
        nextDelegate.next()
    }
}

extension ChooseVehicleOptionsView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView === vehicleTypeCollectionView {
            vehicleTypeViewModel.select(at: indexPath)
            booking.options.vehicleType = vehicleTypeViewModel.selectedType()
        } else if collectionView === vehicleOptionCollectionView {
            vehicleOptionsViewModel.select(at: indexPath)
        }
    }
}
