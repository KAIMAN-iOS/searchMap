//
//  File.swift
//  
//
//  Created by GG on 23/10/2020.
//

import KCoordinatorKit
import UIKit
import ReverseGeocodingMap
import MapKit
import IQKeyboardManagerSwift

protocol SearchMapCoordinatorDelegate: class {
    func showSearch(_ booking: inout BookingWrapper)
}

public class SearchMapCoordinator<DeepLink>: Coordinator<DeepLink> {
    var standAloneMode: Bool = false
    let searchMapController = SearchMapController.create()
    lazy var searchNavigationController = UINavigationController()
    lazy var reverseGeocodingMap = ReverseGeocodingMap.create(delegate: self)
    lazy var favCoordinator: FavouriteCoordinator<DeepLink> = FavouriteCoordinator(router: Router(navigationController: self.searchNavigationController))
    public var handleFavourites: Bool = true
    
    public override init(router: RouterType?) {
        var moduleRouter = router
        if moduleRouter == nil {
            standAloneMode = true
            moduleRouter = Router(navigationController: UINavigationController(rootViewController: searchMapController))
        }
        super.init(router: moduleRouter!)
        searchMapController.coordinatorDelegate = self
        IQKeyboardManager.shared.enable = true
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
    }
    
    public override func toPresentable() -> UIViewController {
        return standAloneMode ? router.navigationController : searchMapController
    }
}

extension SearchMapCoordinator: SearchMapCoordinatorDelegate {
    func showSearch(_ booking: inout BookingWrapper) {
        let ctrl = SearchViewController.create(booking: &booking, searchDelegate: self)
        ctrl.viewModel.favourtiteViewModel.coordinatorDelegate = favCoordinator
        ctrl.viewModel.handleFavourites = handleFavourites
        if CLLocationCoordinate2DIsValid(searchMapController.map.userLocation.coordinate) {
            ctrl.userCoordinates = searchMapController.map.userLocation.coordinate
        }
        searchNavigationController.setViewControllers([ctrl], animated: false)
        searchNavigationController.modalPresentationStyle = .fullScreen
        searchNavigationController.modalTransitionStyle = .crossDissolve
        searchNavigationController.navigationBar.isTranslucent = false
        searchNavigationController.navigationBar.tintColor = #colorLiteral(red: 0.1234303191, green: 0.1703599989, blue: 0.2791167498, alpha: 1)
        router.present(searchNavigationController, animated: true)
    }
}

extension SearchMapCoordinator: SearchViewControllerDelegate {
    func showMapPicker(for location: BookingPlaceType) {
        searchNavigationController.pushViewController(reverseGeocodingMap, animated: true)
    }
    
    func close() {
        router.dismissModule(animated: true, completion: nil)
    }
}

extension SearchMapCoordinator: ReverseGeocodingMapDelegate {
    public func geocodingComplete(_: Result<CLPlacemark, Error>) {
        
    }
    
    public func search() {
        searchNavigationController.popViewController(animated: true)
    }
    
    public func didChoose(_ placemark: CLPlacemark) {
        guard let search = searchNavigationController.viewControllers.first as? SearchViewController else { return }
        search.didChoose(placemark)
        searchNavigationController.popViewController(animated: true)
    }
}

extension String {
    func bundleLocale() -> String {
        NSLocalizedString(self, bundle: .module, comment: self)
    }
}
