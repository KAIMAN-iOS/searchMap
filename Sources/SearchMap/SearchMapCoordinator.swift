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
import ATAConfiguration

public protocol VehicleTypeable {
    var rawValue: Int { get }
    var displayText: String { get }
    var icon: UIImage? { get }
}

protocol SearchMapCoordinatorDelegate: class {
    func showSearch(_ booking: inout BookingWrapper)
}

public enum DisplayMode {
    case driver, passenger, business
    
    var hideUserIcon: Bool {
        switch self {
        case .driver: return true
        case .passenger: return false
        case .business: return false
        }
    }
}

public class SearchMapCoordinator<DeepLink>: Coordinator<DeepLink> {
    var standAloneMode: Bool = false
    let searchMapController = SearchMapController.create()
    lazy var searchNavigationController = UINavigationController()
    var reverseGeocodingMap: ReverseGeocodingMap!
    var favCoordinator: FavouriteCoordinator<DeepLink>!
    public var handleFavourites: Bool = false
    
    public init(router: RouterType?,
                mode: DisplayMode = .driver,
                conf: ATAConfiguration,
                vehicleTypes: [VehicleTypeable]) {
        var moduleRouter = router
        if moduleRouter == nil {
            standAloneMode = true
            moduleRouter = Router(navigationController: UINavigationController(rootViewController: searchMapController))
        }
        super.init(router: moduleRouter!)
        favCoordinator = FavouriteCoordinator(router: Router(navigationController: self.searchNavigationController), conf: conf)
        reverseGeocodingMap = ReverseGeocodingMap.create(delegate: self, conf: conf)
        searchMapController.coordinatorDelegate = self
        searchMapController.mode = mode
        SearchMapController.configuration = conf
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
    func showMapPicker(for location: BookingPlaceType, coordinates: CLLocationCoordinate2D?) {
        reverseGeocodingMap.centerCoordinates = coordinates
        reverseGeocodingMap.placemarkIcon = UIImage(named: location == .origin ? "startMapIcon" : "endMapIcon", in: .module, compatibleWith: nil)!
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
