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

public protocol FavouriteDelegate: NSObjectProtocol {
    func loadFavourites() -> [PlacemarkSection: [Placemark]]
    func reloadFavourites(completion: @escaping (([PlacemarkSection: [Placemark]]) -> Void))
    func didAddFavourite(_: Placemark) -> Promise<Placemark>
    func didUpdateFavourite(_: Placemark) -> Promise<Bool>
    func didDeleteFavourite(_: Placemark) -> Promise<Bool>
}

public protocol FavouriteCoordinatorDelegate: NSObjectProtocol {
    func addNewFavourite()
    func editFavourite(_: Placemark, type: FavouriteType?)
    func deleteFavourite(_: Placemark, type: FavouriteType?)
    func showFavourites()
}

public class FavouriteCoordinator<DeepLink>: Coordinator<DeepLink> {
    var favouriteViewModel: FavouriteViewModel = FavouriteViewModel.shared
    var favListController: FavouriteListViewController!
    public init(router: RouterType,
                favDelegate: FavouriteDelegate,
                mode: DisplayMode = .driver,
                coordinatorDelegate: FavouriteCoordinatorDelegate? = nil,
                conf: ATAConfiguration) {
        super.init(router: router)
        favListController = FavouriteListViewController.create(conf: conf, favDelegate: favDelegate, favCoordinatorDelegate: self)
        favListController.mode = mode
        favouriteViewModel.favDelegate = favDelegate
        favouriteViewModel.coordinatorDelegate = coordinatorDelegate ?? self
    }
    
    public override func toPresentable() -> UIViewController {
        favListController
    }
}

extension FavouriteCoordinator: FavouriteDelegate {
    public func loadFavourites() -> [PlacemarkSection: [Placemark]] { [:] }
    public func reloadFavourites(completion: @escaping (([PlacemarkSection : [Placemark]]) -> Void)) {}
    
    public func didAddFavourite(_ placemark: Placemark) -> Promise<Placemark> {
        favouriteViewModel
            .favDelegate
            .didAddFavourite(placemark)
            .get { [weak self] _ in
                self?.router.popModule(animated: true)
                self?.favListController.reload()
            }
    }
    
    public func didUpdateFavourite(_ placemark: Placemark) -> Promise<Bool> {
        favouriteViewModel
            .favDelegate
            .didUpdateFavourite(placemark)
            .get { [weak self] _ in
                self?.router.popModule(animated: true)
                self?.favListController.reload()
            }
    }
    
    public func didDeleteFavourite(_ placemark: Placemark) -> Promise<Bool> {
        favouriteViewModel
            .favDelegate
            .didDeleteFavourite(placemark)
            .get { [weak self] success in
                if success {
                    self?.router.popModule(animated: true)
                    self?.favListController.reload()
                }
            }
    }
}

extension FavouriteCoordinator: FavouriteCoordinatorDelegate {
    public func addNewFavourite() {
        let edit = FavouriteEditViewController.create(favType: nil, delegate: self, editMode: false)
        router.push(edit, animated: true, completion: nil)
    }
    
    public func editFavourite(_ place: Placemark, type: FavouriteType?) {
        let edit = FavouriteEditViewController.create(placeMark: place, favType: type, delegate: self, editMode: true)
        router.push(edit, animated: true, completion: nil)
    }
    
    public func deleteFavourite(_: Placemark, type: FavouriteType?) {
        
    }
    
    public func showFavourites() {
        router.push(self, animated: true, completion: nil)
    }
}
