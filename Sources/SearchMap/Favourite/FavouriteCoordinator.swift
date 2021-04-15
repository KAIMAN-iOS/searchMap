//
//  File.swift
//  
//
//  Created by GG on 27/10/2020.
//

import UIKit
import KCoordinatorKit
import ATAConfiguration
import PromiseKit

public protocol FavouriteDelegate: class {
    func loadFavourites(completion: @escaping (([PlacemarkSection: [Placemark]]) -> Void))
    func didAddFavourite(_: Placemark) -> Promise<Bool>
    func didDeleteFavourite(_: Placemark) -> Promise<Bool>
}

public protocol FavouriteCoordinatorDelegate: class {
    func addNewFavourite()
    func editFavourite(_: Placemark)
    func deleteFavourite(_: Placemark)
    func showFavourites()
}

public class FavouriteCoordinator<DeepLink>: Coordinator<DeepLink> {
    var favouriteViewModel: FavouriteViewModel = FavouriteViewModel.shared
    var favListController: FavouriteListViewController
    public init(router: RouterType,
                favDelegate: FavouriteDelegate,
                mode: DisplayMode = .driver,
                coordinatorDelegate: FavouriteCoordinatorDelegate? = nil,
                conf: ATAConfiguration) {
        favListController = FavouriteListViewController.create(conf: conf, favDelegate: favDelegate)
        favListController.mode = mode
        super.init(router: router)
        favouriteViewModel.favDelegate = favDelegate
        favouriteViewModel.coordinatorDelegate = coordinatorDelegate ?? self
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
