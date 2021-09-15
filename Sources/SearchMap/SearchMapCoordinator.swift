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
import ATAConfiguration
import ATAGroup
import PromiseKit
import MapExtension
import ATACommonObjects
import ATAViews

protocol SearchMapCoordinatorDelegate: NSObjectProtocol {
    func showSearch(_ booking: inout CreateRide, animated: Bool)
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

public protocol SearchRideDelegate: NSObjectProtocol {
    func book(_ booking: CreateRide) -> Promise<Bool>
    func save(_ booking: CreateRide)-> Promise<Bool>
    func share(_ booking: CreateRide, to groups: [Group])-> Promise<Bool>
    func showMenu()
    func back()
    func cards() -> [CreditCard]
    func willShowCards() -> Promise<Bool>
}

public protocol SearchMapDelegate: NSObjectProtocol {
    func view(for annotation: MKAnnotation) -> MKAnnotationView?
    func renderer(for overlay: MKOverlay) -> MKPolylineRenderer
    func annotations(for ride: CreateRide) -> [MKAnnotation]
    func overlays(for route: MKRoute) -> [MKOverlay]
    func routeReady(_ route: MKRoute)
}

public struct OptionConfiguration {
    public struct StepperConfiguration {
        var minValue: Int = 0
        var maxValue: Int = 10
    }
    public var passengerConfiguration: StepperConfiguration
    public var luggagesConfiguration: StepperConfiguration
    
    public static var `default`: OptionConfiguration = OptionConfiguration(passengerConfiguration: StepperConfiguration(minValue: 1, maxValue: 8),
                                                                    luggagesConfiguration: StepperConfiguration(minValue: 0, maxValue: 6))
}

public class SearchMapCoordinator<DeepLink>: Coordinator<DeepLink> {
    var standAloneMode: Bool = false
    public let searchMapController = SearchMapController.create()
    lazy var searchNavigationController = UINavigationController()
    var reverseGeocodingMap: ReverseGeocodingMap!
    var favCoordinator: FavouriteCoordinator<DeepLink>!
    public var handleFavourites: Bool = false
    public weak var delegate: SearchRideDelegate?
    var mode: DisplayMode = .driver
    var favDelegate: FavouriteDelegate!
    
    public init(router: RouterType?,
                delegate: SearchRideDelegate,
                searchMapDelegate: SearchMapDelegate,
                favDelegate: FavouriteDelegate? = nil,
                mode: DisplayMode = .driver,
                conf: ATAConfiguration,
                vehicleTypes: [VehicleType],
                vehicleOptions: [VehicleOption],
                groups: [Group] = [],
                passenger: BasePassenger? = nil,
                configurationOptions: OptionConfiguration = OptionConfiguration.default) {
        
        if favDelegate == nil, mode == .passenger {
            fatalError("You must provide a favDelegate when using SearchMap with a passenger mode")
        }
        
        var moduleRouter = router
        if moduleRouter == nil {
            standAloneMode = true
            moduleRouter = Router(navigationController: UINavigationController(rootViewController: searchMapController))
        }
        super.init(router: moduleRouter!)
        self.mode = mode
        favCoordinator = FavouriteCoordinator(router: Router(navigationController: self.searchNavigationController),
                                              favDelegate: favDelegate ?? self,
                                              mode: mode,
                                              conf: conf)
        SearchMapController.configuration = conf
        customize()
        self.favDelegate = favDelegate ?? self
//        handleFavourites = mode == .passenger
        reverseGeocodingMap = ReverseGeocodingMap.create(delegate: self, conf: conf)
        searchMapController.coordinatorDelegate = self
        searchMapController.mode = mode
        searchMapController.passenger = passenger
        searchMapController.availableOptions = vehicleOptions
        searchMapController.searchMapDelegate = searchMapDelegate
        searchMapController.vehicles = vehicleTypes
        searchMapController.groups = groups
        searchMapController.configurationOptions = configurationOptions
        searchMapController.delegate = delegate
        router?.navigationController.setNavigationBarHidden(true, animated: false)
        searchNavigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
    }
    
    public func updateUserpicture(with image: UIImage?) {
        searchMapController.updateUserpicture(with: image)
    }
    
    private func customize() {
        SelectableButton.selectedBackgroundColor = SearchMapController.configuration.palette.secondary
        SelectableButton.selectedBorderColor = SearchMapController.configuration.palette.secondary
        SelectableButton.selectedTextColor = SearchMapController.configuration.palette.textOnDark
        SelectableButton.unselectedBackgroundColor = SearchMapController.configuration.palette.background
        SelectableButton.unselectedTextColor = SearchMapController.configuration.palette.inactive
        SelectableButton.unselectedBorderColor = SearchMapController.configuration.palette.inactive
    }
    
    deinit {
        print("💀 DEINIT \(URL(fileURLWithPath: #file).lastPathComponent)")
        router.navigationController.navigationBar.barTintColor = SearchMapController.configuration.palette.background
        router.navigationController.navigationBar.isTranslucent = false
    }
    
    public override func toPresentable() -> UIViewController {
        return standAloneMode ? router.navigationController : searchMapController
    }
}

extension SearchMapCoordinator: FavouriteDelegate {
    public func loadFavourites() -> [PlacemarkSection : [Placemark]] { [:] }
    public func reloadFavourites(completion: @escaping (([PlacemarkSection : [Placemark]]) -> Void)) {}
    
    public func didAddFavourite(_: Placemark) -> Promise<Placemark> {
        fatalError()
    }
    
    public func didUpdateFavourite(_: Placemark) -> Promise<Bool> {
        fatalError()
    }
    
    public func didDeleteFavourite(_: Placemark) -> Promise<Bool> {
        fatalError()
    }
}

extension SearchMapCoordinator: SearchMapCoordinatorDelegate {
    func showSearch(_ booking: inout CreateRide, animated: Bool) {
        let ctrl = SearchViewController.create(booking: &booking, searchDelegate: self)
        ctrl.mode = mode
        ctrl.favDelegate = favDelegate
        ctrl.viewModel.favourtiteViewModel.coordinatorDelegate = favCoordinator
        ctrl.viewModel.handleFavourites = handleFavourites
        if CLLocationCoordinate2DIsValid(searchMapController.map.userLocation.coordinate) {
            ctrl.userCoordinates = searchMapController.map.userLocation.coordinate
        }
        searchNavigationController.setViewControllers([ctrl], animated: false)
        searchNavigationController.modalPresentationStyle = .fullScreen
        searchNavigationController.modalTransitionStyle = .crossDissolve
        searchNavigationController.navigationBar.shadowImage = UIImage()
        (router.navigationController.topViewController ?? searchMapController).present(searchNavigationController, animated: animated)
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
    public func geocodingComplete(_: Swift.Result<CLPlacemark, Error>) {
        
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
