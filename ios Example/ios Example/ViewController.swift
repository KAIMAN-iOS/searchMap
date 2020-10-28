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

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    lazy var coord: SearchMapCoordinator<Int> = SearchMapCoordinator(router: Router(navigationController: self.navigationController!))
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

