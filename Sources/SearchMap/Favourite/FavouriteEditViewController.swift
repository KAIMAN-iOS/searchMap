//
//  File.swift
//  
//
//  Created by GG on 26/10/2020.
//

import UIKit
import TextFieldEffects
import LabelExtension
import FontExtension
import ReverseGeocodingMap
import CoreLocation
import ActionButton

class FavouriteEditViewController: UIViewController {
    static func create(placeMark: Placemark? = nil) -> FavouriteEditViewController {
        let ctrl: FavouriteEditViewController = UIStoryboard(name: "Favourite", bundle: .module).instantiateViewController(identifier: "FavouriteEditViewController") as! FavouriteEditViewController
        ctrl.placeMark = placeMark ?? Placemark(name: nil, address: nil, coordinates: kCLLocationCoordinate2DInvalid)
        return ctrl
    }
    
    var placeMark: Placemark!
    @IBOutlet weak var name: AkiraTextField!  {
        didSet {
            name.placeholder = "Place name".bundleLocale()
            name.font = FontType.default.font
            name.textColor = #colorLiteral(red: 0.1234303191, green: 0.1703599989, blue: 0.2791167498, alpha: 1)
            name.placeholderColor = #colorLiteral(red: 0.6176490188, green: 0.6521512866, blue: 0.7114837766, alpha: 1)
            name.borderColor = #colorLiteral(red: 0.6176490188, green: 0.6521512866, blue: 0.7114837766, alpha: 1)
            name.setContentCompressionResistancePriority(.required, for: .vertical)
        }
    }

    @IBOutlet weak var address: AkiraTextField!  {
        didSet {
            address.placeholder = "Place address".bundleLocale()
            address.font = FontType.default.font
            address.textColor = #colorLiteral(red: 0.1234303191, green: 0.1703599989, blue: 0.2791167498, alpha: 1)
            address.placeholderColor = #colorLiteral(red: 0.6176490188, green: 0.6521512866, blue: 0.7114837766, alpha: 1)
            address.borderColor = #colorLiteral(red: 0.6176490188, green: 0.6521512866, blue: 0.7114837766, alpha: 1)
            address.setContentCompressionResistancePriority(.required, for: .vertical)
        }
    }
    
    @IBOutlet weak var typeStackView: UIStackView!  {
        didSet {
            [FavouriteType.home, FavouriteType.work, nil].forEach { fav in
                guard let view: FavouriteTypeView = Bundle.module.loadNibNamed("FavouriteTypeView", owner: nil, options: nil)?.first as? FavouriteTypeView else { return }
                view.configure(fav)
                typeStackView.addArrangedSubview(view)
            }
        }
    }
    
    @IBOutlet weak var saveButton: ActionButton!
    @IBOutlet weak var pickMapButton: ActionButton!
    
    @IBAction func showMap() {
        let map = ReverseGeocodingMap.create(delegate: self, centerCoordinates: CLLocationCoordinate2DIsValid(placeMark.coordinates) ? placeMark.coordinates : nil)
        map.showSearchButton = false
        navigationController?.pushViewController(map, animated: true)
    }
    
    @IBAction func save() {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ActionButton.globalShape = .rounded(value: 5)
        navigationController?.navigationBar.prefersLargeTitles = false
        name.text = placeMark.name
        address.text = placeMark.address
        if #available(iOS 14.0, *) {
            self.navigationItem.backButtonDisplayMode = .minimal
        } else {
            navigationItem.backButtonTitle = ""
        }
    }
}

extension FavouriteEditViewController: ReverseGeocodingMapDelegate {
    func geocodingComplete(_: Result<CLPlacemark, Error>) {
        
    }
    
    func search() {
        
    }
    
    func didChoose(_ placemark: CLPlacemark) {
        navigationController?.popViewController(animated: true)
    }
}
