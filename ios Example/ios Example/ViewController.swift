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

class Configuration: ATAConfiguration {
    var logo: UIImage? { nil }
    var palette: Palettable { Palette() }
}

class Palette: Palettable {
    var primary: UIColor { #colorLiteral(red: 0.8604696393, green: 0, blue: 0.1966537535, alpha: 1) }
    var secondary: UIColor { #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1) }
    
    var mainTexts: UIColor { #colorLiteral(red: 0.1879811585, green: 0.1879865527, blue: 0.1879836619, alpha: 1) }
    
    var secondaryTexts: UIColor { #colorLiteral(red: 0.1565656662, green: 0.1736218631, blue: 0.2080874145, alpha: 1) }
    
    var textOnPrimary: UIColor { #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) }
    
    var inactive: UIColor { #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1) }
    
    var placeholder: UIColor { #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1) }
    var lightGray: UIColor { #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1) }
    
    
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    lazy var coord: SearchMapCoordinator<Int> = SearchMapCoordinator(router: Router(navigationController: self.navigationController!), conf: Configuration())
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

