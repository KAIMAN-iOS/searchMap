//
//  File.swift
//  
//
//  Created by GG on 27/10/2020.
//

import UIKit
import KCoordinatorKit

public protocol FavouriteDelegate: class {
    func loadFavourites(completion: @escaping (([PlacemarkSection: [Placemark]]) -> Void))
    func didAddFavourite(_: Placemark)
    func didDeleteFavourite(_: Placemark)
}

public protocol FavouriteCoordinatorDelegate: class {
    func addNewFavourite()
    func editFavourite(_: Placemark)
    func deleteFavourite(_: Placemark)
    func showFavourites()
}

public class FavouriteCoordinator<DeepLink>: Coordinator<DeepLink> {
    var favouriteViewModel: FavouriteViewModel = FavouriteViewModel.shared
    lazy var  favListController: FavouriteListViewController = FavouriteListViewController.create()
    public init(router: RouterType,
                favDelegate: FavouriteDelegate? = nil,
                coordinatorDelegate: FavouriteCoordinatorDelegate? = nil) {
        super.init(router: router)
        if let delegate = favDelegate  {
            self.favouriteViewModel.favDelegate = delegate
        } else if FavouriteViewModel.shared.favDelegate == nil {
            fatalError("FavouriteViewModel.shared.favDelegate has to be set in order to use FavouriteCoordinator")
        }
        self.favouriteViewModel.coordinatorDelegate = coordinatorDelegate ?? self
    }
    
    public override func toPresentable() -> UIViewController {
        favListController
    }
}

extension FavouriteCoordinator: FavouriteCoordinatorDelegate {
    public func addNewFavourite() {
        let edit = FavouriteEditViewController.create()
        router.push(edit, animated: true, completion: nil)
    }
    
    public func editFavourite(_ place: Placemark) {
        let edit = FavouriteEditViewController.create(placeMark: place)
        router.push(edit, animated: true, completion: nil)
    }
    
    public func deleteFavourite(_: Placemark) {
        
    }
    
    public func showFavourites() {
        router.push(self, animated: true, completion: nil)
    }
}
