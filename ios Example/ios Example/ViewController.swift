//
//  ViewController.swift
//  ios Example
//
//  Created by GG on 23/10/2020.
//

import UIKit
import SearchMap
import KCoordinatorKit
import CoreLocation
import ATAConfiguration
import Ampersand
import ActionButton

class Configuration: ATAConfiguration {
    var logo: UIImage? { nil }
    var palette: Palettable { Palette() }
}

class Palette: Palettable {
    var action: UIColor { #colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1) }
    var confirmation: UIColor { #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1) }
    var alert: UIColor { #colorLiteral(red: 0.8604696393, green: 0, blue: 0.1966537535, alpha: 1) }
    var primary: UIColor { #colorLiteral(red: 0.8604696393, green: 0, blue: 0.1966537535, alpha: 1) }
    var secondary: UIColor { #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1) }
    var mainTexts: UIColor { #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) }
    var secondaryTexts: UIColor { #colorLiteral(red: 0.3137255013, green: 0.4039215744, blue: 0.5333333611, alpha: 1) }
    var textOnPrimary: UIColor { #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) }
    var inactive: UIColor { #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1) }
    var placeholder: UIColor { #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1) }
    var lightGray: UIColor { #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1) }
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let configurationURL = Bundle.main.url(forResource: "Poppins", withExtension: "json")!
        UIFont.registerApplicationFont(withConfigurationAt: configurationURL)
        ActionButton.primaryColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    }

    lazy var coord: SearchMapCoordinator<Int> = SearchMapCoordinator(router: Router(navigationController: self.navigationController!), conf: Configuration(), vehicleTypes: [])
    @IBAction func show(_ sender: Any) {
        FavouriteViewModel.shared.favDelegate = self
        navigationController?.pushViewController(coord.toPresentable(), animated: true)
    }
    
}

extension ViewController: FavouriteDelegate {
    func didAddFavourite(_: Placemark) {
        
    }
    
    func didDeleteFavourite(_: Placemark) {
        
    }
    
    func loadFavourites(completion: @escaping (([PlacemarkSection : [Placemark]]) -> Void)) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion([.favourite : [Placemark(name: "Test", address: "test address", coordinates: CLLocationCoordinate2D(latitude: 4.897982, longitude: 23.89798769868))],
                        .specificFavourite : [Placemark(name: "Test home", address: "test address home", coordinates: kCLLocationCoordinate2DInvalid, specialFavourite: .home)],
                        .history : [Placemark(name: "Test H", address: "test address H", coordinates: kCLLocationCoordinate2DInvalid),
                                    Placemark(name: "Test H2", address: "test address H2", coordinates: kCLLocationCoordinate2DInvalid)]])
        }
    }
}

