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
        coord.favDelegate = self
        navigationController?.pushViewController(coord.toPresentable(), animated: true)
    }
    
}

extension ViewController: FavouriteDisplayDelegate {
    func loadFavourites(completion: @escaping (([SearchViewModel.SearchSection : [Placemark]]) -> Void)) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            completion([.favourite : [Placemark(name: "Test", address: "test address", coordinates: kCLLocationCoordinate2DInvalid)],
                        .specificFavourite : [Placemark(name: "Test home", address: "test address home", coordinates: kCLLocationCoordinate2DInvalid, specialFavourite: .home)],
                        .history : [Placemark(name: "Test H", address: "test address H", coordinates: kCLLocationCoordinate2DInvalid),
                                    Placemark(name: "Test H2", address: "test address H2", coordinates: kCLLocationCoordinate2DInvalid)]])
        }
    }
}

