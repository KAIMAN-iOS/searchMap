//
//  File.swift
//  
//
//  Created by GG on 23/10/2020.
//

import UIKit
import MapKit
import SnapKit
import CoreLocation
import UIViewExtension
import LocationExtension
import ATAConfiguration
import SwiftLocation
import AlertsAndPickers
import UIViewControllerExtension
import SwiftDate
import PromiseKit
import ATAGroup
import ATACommonObjects

public final class SearchMapController: UIViewController {
    var mode: DisplayMode = .driver
    var configurationOptions: OptionConfiguration!
    static var configuration: ATAConfiguration!
    static func create() -> SearchMapController {
        return UIStoryboard(name: "Map", bundle: .module).instantiateInitialViewController() as! SearchMapController
    }
    
    enum State {
        case search
        case bookingReady
        case shareWithGroup
        
        var backgroudColor: UIColor {
            switch self {
            case .search: return SearchMapController.configuration.palette.background
            case .bookingReady, .shareWithGroup: return SearchMapController.configuration.palette.background
            }
        }
    }
    var state: State = .search  {
        didSet {
            switch state {
            case .search: loadSearchCard()
            case .bookingReady, .shareWithGroup: ()
            }
            card.backgroundColor = state.backgroudColor
            cardContainer.backgroundColor = .clear
        }
    }
    var optionState: OptionState = .default
    var vehicles: [VehicleType] = []
    var groups: [Group] = []
    @IBOutlet weak var originLabel: UILabel!
    @IBOutlet weak var originIndicator: UIView!  {
        didSet {
            originIndicator.roundedCorners = true
            originIndicator.backgroundColor = SearchMapController.configuration.palette.confirmation
        }
    }
    @IBOutlet weak var destinationContainer: UIStackView!
    @IBOutlet weak var destinationLabel: UILabel!
    @IBOutlet weak var destinationIndicator: UIView! {
        didSet {
            destinationIndicator.roundedCorners = true
            destinationIndicator.backgroundColor = SearchMapController.configuration.palette.primary
        }
    }
    @IBOutlet weak var backOptionsButton: UIButton!  {
        didSet {
            backOptionsButton.roundedCorners = true
            backOptionsButton.isHidden = true
        }
    }

    var bookingWrapper = CreateRide()
    weak var coordinatorDelegate: SearchMapCoordinatorDelegate?
    weak var searchMapDelegate: SearchMapDelegate!
    public weak var delegate: SearchRideDelegate!
    private var locationRequest: GPSLocationRequest?
    var availableOptions: [VehicleOption] = []
    
    let geocoder = CLGeocoder()
    @IBOutlet private(set) public weak var map: MKMapView!  {
        didSet {
            map.delegate = self
            map.layoutMargins.bottom = 15
        }
    }
    @IBOutlet weak var dashView: DottedView!  {
        didSet {
            dashView.orientation = .vertical
            dashView.backgroundColor = .clear
            dashView.dashes = [4, 4]
            dashView.dotColor = SearchMapController.configuration.palette.inactive
        }
    }
    @IBOutlet weak var locatioButton: UIButton!  {
        didSet {
            locatioButton.layer.cornerRadius = 5.0
        }
    }
    @IBOutlet weak var userButton: UIButton!  {
        didSet {
            userButton.layer.cornerRadius = userButton.bounds.midX
            userButton.layer.borderColor = UIColor.white.cgColor
            userButton.layer.borderWidth = 2.0
        }
    }
    @IBOutlet public weak var card: UIView!
    @IBOutlet public weak var cardContainer: UIView!
    @IBOutlet weak var bookingTopView: UIView!  {
        didSet {
            bookingTopView.layer.cornerRadius = 25
            bookingTopView.addShadow(roundCorners: false, useMotionEffect: false)
            bookingTopView.backgroundColor = SearchMapController.configuration.palette.background
        }
    }
    
    var originObserver: NSKeyValueObservation?
    var destinationObserver: NSKeyValueObservation?
    
    deinit {
        print("💀 DEINIT \(URL(fileURLWithPath: #file).lastPathComponent)")
        originObserver?.invalidate()
        destinationObserver?.invalidate()
        stopLocationUpdate()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        updateUserBackButton()
        hideBackButtonText = true
        startLocationUpdates()
        state = .search
        handleObservers()
        checkAuthorization()
        map.showsUserLocation = false
        map.tintColor = SearchMapController.configuration.palette.primary
        if mode == .driver {
            search(animated: true)
        }
    }
    
    func updateUserBackButton() {
        switch mode {
        case .driver:
            userButton.setImage(UIImage(named: "arrow", in: .module, compatibleWith: nil), for: .normal)
            userButton.backgroundColor = .clear
            userButton.layer.borderWidth = 0
            userButton.removeTarget(nil, action: nil, for: .touchUpInside)
            userButton.addTarget(delegate, action: #selector(back), for: .touchUpInside)
            
        default: ()
        }
    }
    
    func startLocationUpdates() {
        let serviceOptions = GPSLocationOptions()
        serviceOptions.subscription = .continous // continous updated until you stop it
        serviceOptions.accuracy = .house
        serviceOptions.minDistance = 5
        serviceOptions.activityType = .automotiveNavigation
        
        locationRequest = SwiftLocation.gpsLocationWith(serviceOptions)
        locationRequest?
            .then { [weak self] result in // you can attach one or more subscriptions via `then`.
                guard let self = self else { return }
                switch result {
                case .success(let newData):
                    self.geocoder.cancelGeocode()
                    self.geocoder.reverseGeocodeLocation(newData.coordinate.asLocation) { [weak self] (placemarks, error) in
                        guard let self = self, let placemark = placemarks?.first else { return }
                        if let userAnno = self.map.annotations.compactMap({ $0 as? UserAnnotation }).first {
                            userAnno.coordinate = newData.coordinate
                        } else {
                            self.map.addAnnotation(UserAnnotation(placemark: placemark))
                            self.map.setCenter(newData.coordinate, animated: true)
                        }
                    }
                    
                case .failure(let error):
                    print("An error has occurred: \(error.localizedDescription)")
                }
            }
    }
    
    func stopLocationUpdate() {
        locationRequest?.cancelRequest()
        locationRequest = nil
    }
    
    func handleObservers() {        
        originObserver?.invalidate()
        originObserver = bookingWrapper.observe(\.fromAddress, changeHandler: { [weak self] (booking, change) in
            self?.handleBookingCard()
        })
        destinationObserver?.invalidate()
        destinationObserver = bookingWrapper.observe(\.toAddress, changeHandler: { [weak self] (booking, change) in
            self?.handleBookingCard()
        })
    }
    
    func handleBookingCard() {
        defer {
            if bookingWrapper.fromAddress != nil && bookingWrapper.toAddress != nil {
                RideDirectionManager
                    .shared
                    .loadDirections(for: bookingWrapper) { [weak self] ride, routes in
                        guard let self = self else { return }
                        let anno = self.searchMapDelegate.annotations(for: self.bookingWrapper)
                        if anno.count > 0 {
                            self.map.removeAnnotations(self.map.annotations.filter({ $0 as? UserAnnotationView == nil }))
                            self.map.addAnnotations(anno)
                        }
                        // routes
                        if let route = routes.first?.route {
                            let overlays = self.searchMapDelegate.overlays(for: route)
                            if let overlay = overlays.first {
                                self.map.removeOverlays(self.map.overlays)
                                self.map.addOverlay(overlay)
                                self.map.setVisibleMapRect(route.polyline.boundingMapRect,
                                                           edgePadding: UIEdgeInsets(top: self.bookingTopView.frame.maxY + 30,
                                                                                     left: self.locatioButton.frame.width + 20,
                                                                                     bottom: self.locatioButton.frame.height + 30,
                                                                                     right: 50),
                                                           animated: true)
                            }
                        }
                    }
            }
        }
        guard bookingWrapper.fromAddress != nil else {
            state = .search
            return
        }
        DispatchQueue.main.async { [weak self]  in
            self?.loadOptionsCard()
        }
    }
    
    func loadOptionsCard() {
        defer {
            configureTopView()
        }
        // no need to reload the view if it is already the right one
        guard cardContainer.subviews.first as? ChooseOptionsView == nil else { return }
        guard let view: ChooseOptionsView = Bundle.module.loadNibNamed("ChooseOptionsView", owner: nil)?.first as? ChooseOptionsView else { return }
        state = .bookingReady
        optionState = .default
        backOptionsButton.isHidden = mode == .driver
        view.delegate = self
        view.nextDelegate = self
        view.availableOptions = availableOptions
        view.mode = mode
        view.searchMapDelegate = delegate
        addViewToCard(view)
        view.configure(options: configurationOptions, booking: &bookingWrapper)
        bookingTopView.isHidden = false
    }
    
    func loadVehicleOptionsCard() {
        // no need to reload the view if it is already the right one
        guard cardContainer.subviews.first as? ChooseVehicleOptionsView == nil else { return }
        guard let view: ChooseVehicleOptionsView = Bundle.module.loadNibNamed("ChooseVehicleOptionsView", owner: nil)?.first as? ChooseVehicleOptionsView else { return }
        optionState = .vehicleOptions
        backOptionsButton.isHidden = false
        view.delegate = self
        view.nextDelegate = self
        view.availableOptions = availableOptions
        view.vehicles = vehicles
        view.mode = mode
        view.groups = groups
        view.searchMapDelegate = delegate
        addViewToCard(view)
        view.configure(options: configurationOptions, booking: &bookingWrapper)
    }
    
    func loadPassengerOptionsCard() {
        // no need to reload the view if it is already the right one
        guard cardContainer.subviews.first as? ChoosePassengerOptionsView == nil else { return }
        guard let view: ChoosePassengerOptionsView = Bundle.module.loadNibNamed("ChoosePassengerOptionsView", owner: nil)?.first as? ChoosePassengerOptionsView else { return }
        optionState = .passenger
        view.delegate = self
        view.availableOptions = availableOptions
        view.mode = mode
        view.searchMapDelegate = delegate
        addViewToCard(view)
        view.configure(options: configurationOptions, booking: &bookingWrapper)
    }
    
    func loadCard(for state: OptionState) {
        switch state {
        case .default: loadOptionsCard()
        case .vehicleOptions: loadVehicleOptionsCard()
        case .passenger: loadPassengerOptionsCard()
        }
    }
    
    func configureTopView() {
        guard bookingWrapper.fromAddress != nil else { return }
        originLabel.set(text: bookingWrapper.fromAddress?.name, for: .body, textColor: SearchMapController.configuration.palette.mainTexts)
        let noDestination = bookingWrapper.toAddress?.name?.isEmpty ?? true == true
        destinationLabel.set(text: bookingWrapper.toAddress?.name ?? "no destination".bundleLocale(),
                             for: .body,
                             textColor: noDestination ? SearchMapController.configuration.palette.inactive : SearchMapController.configuration.palette.mainTexts)
    }
    
    func loadSearchCard() {
        // no need to reload the view if it is already the right one
        guard cardContainer.subviews.first as? MapLandingView == nil else { return }
        guard let view: MapLandingView = Bundle.module.loadNibNamed("MapLandingView", owner: nil)?.first as? MapLandingView else { return }
        view.delegate = self
        backOptionsButton.isHidden = true
        addViewToCard(view)
        bookingTopView.isHidden = true
    }
    
    func addViewToCard(_ view: UIView) {
        cardContainer.subviews.forEach({ $0.removeFromSuperview() })
        cardContainer.addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    let locationManager = CLLocationManager()
    fileprivate func checkAuthorization() {
        locationManager.delegate = self
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined: locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse: locatioButton.isHidden = false
        default: locatioButton.isHidden = true
        }
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        card.round(corners: [.topLeft, .topRight], radius: 25.0)
        card.addShadow(roundCorners: false, shadowOffset: CGSize(width: -5, height: 0))
        bookingTopView.layer.cornerRadius = 10.0
        bookingTopView.addShadow(roundCorners: false, shadowOffset: CGSize(width: -5, height: 0))
    }
    
    @IBAction func changeUserLocationType() {
        switch map.userTrackingMode {
        case .none: map.userTrackingMode = .follow
        case .follow: map.userTrackingMode = .followWithHeading
        default: map.userTrackingMode = .none
        }
    }
    
    @IBAction func showSearchController() {
        search(animated: true)
    }
    
    @IBAction func showMenu() {
        delegate.showMenu()
    }
}

extension SearchMapController: CLLocationManagerDelegate {
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse, .authorizedAlways:
            locatioButton.isHidden = false
            if mode == .driver {
                map.showsUserLocation = true
                map.tintColor = SearchMapController.configuration.palette.primary
            }
            
        default:
            locatioButton.isHidden = true
        }
    }
}

class UserAnnotation: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    var placemark: CLPlacemark!
    init(placemark: CLPlacemark) {
        self.placemark = placemark
        coordinate = placemark.location?.coordinate ?? kCLLocationCoordinate2DInvalid
    }
}

extension SearchMapController: MapLandingViewDelegate {
    func search(animated: Bool ) {
        coordinatorDelegate?.showSearch(&bookingWrapper, animated: animated)
    }
}

extension SearchMapController: BookDelegate, ChooseDateDelegate {
    func book(_ booking: CreateRide) -> Promise<Bool> {
        guard let delegate = delegate else {
            return Promise<Bool>.init { (resolver) in
                resolver.fulfill(false)
            }
        }
        return delegate.book(booking)
    }
    
    func save(_ booking: CreateRide) -> Promise<Bool> {
        guard let delegate = delegate else {
            return Promise<Bool>.init { (resolver) in
                resolver.fulfill(false)
            }
        }
        return delegate.save(booking)
    }
    
    func chooseDate(actualDate: Date, completion: @escaping ((Date) -> Void)) {
        let alertController = UIAlertController(title: "departure date".bundleLocale(), message: nil, preferredStyle: .actionSheet)
        alertController.addDatePicker(mode: .dateAndTime,
                                      date: actualDate,
                                      minimumDate: Date(),
                                      maximumDate: nil,
                                      minuteInterval: 5) {date in
            completion(date)
        }
        alertController.addAction(title: "OK".bundleLocale(), style: .cancel)
        alertController.view.tintColor = SearchMapController.configuration.palette.mainTexts
        present(alertController, animated: true, completion: nil)
    }
    
    func share(_ booking: CreateRide) {
        let choose = ChooseGroupsView.create(booking: booking, groups: groups, delegate: delegate)
        choose.navDelegate = self
        addViewToCard(choose)
    }
}

extension SearchMapController: MKMapViewDelegate {
    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let view = searchMapDelegate.view(for: annotation) else {
            guard mode != .driver,
                  let annotation = annotation as? UserAnnotation,
                  let view: UserAnnotationView = Bundle.module.loadNibNamed("UserAnnotationView", owner: nil)?.first as? UserAnnotationView else { return nil }
            view.configure(annotation.placemark)
            view.tintColor = SearchMapController.configuration.palette.primary
            view.layoutIfNeeded()
            view.centerOffset = CGPoint(x: 0, y: -view.bounds.midY)
            return view
        }
        return view
    }
    
    public func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let view = view as? UserAnnotationView, mode != .driver else { return }
        // push the search view with departure selected
        map.deselectAnnotation(view.annotation, animated: false)
        bookingWrapper.fromAddress = view.placemark
        search(animated: true)
    }
    
    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer { searchMapDelegate.renderer(for: overlay) }
}

extension SearchMapController: OptionViewDelegate {
    func next() {
        guard let state = optionState.next else {
            return
        }
        loadCard(for: state)
    }
}

extension SearchMapController: ChooseGroupNavigationDelegate {
    @IBAction func back() {
        guard let state = optionState.previous else {
            if mode == .passenger {
                loadSearchCard()
            }
            return
        }
        loadCard(for: state)
    }
}
