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

class SearchMapController: UIViewController {
    var mode: DisplayMode = .driver
    var configurationOptions: OptionConfiguration!
    static var configuration: ATAConfiguration!
    static func create() -> SearchMapController {
        return UIStoryboard(name: "Map", bundle: .module).instantiateInitialViewController() as! SearchMapController
    }
    
    enum State {
        case search
        case bookingReady
        
        var backgroudColor: UIColor {
            switch self {
            case .search: return .white
            case .bookingReady: return SearchMapController.configuration.palette.secondary
            }
        }
    }
    var state: State = .search  {
        didSet {
            switch state {
            case .search: loadSearchCard()
            case .bookingReady: ()
            }
            card.backgroundColor = state.backgroudColor
            cardContainer.backgroundColor = .clear
        }
    }
    var vehicles: [VehicleTypeable] = []
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
    var bookingWrapper = BookingWrapper()
    weak var coordinatorDelegate: SearchMapCoordinatorDelegate?
    weak var searchMapDelegate: SearchMapDelegate!
    public weak var delegate: SearchRideDelegate!
    private var locationRequest: GPSLocationRequest?
    
    let geocoder = CLGeocoder()
    @IBOutlet weak var map: MKMapView!  {
        didSet {
            map.delegate = self
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
    @IBOutlet weak var card: UIView!
    @IBOutlet weak var cardContainer: UIView!
    @IBOutlet weak var bookingTopView: UIView!  {
        didSet {
            bookingTopView.layer.cornerRadius = 25
            bookingTopView.addShadow(roundCorners: false)
            bookingTopView.backgroundColor = SearchMapController.configuration.palette.secondary
        }
    }

    @IBOutlet weak var topViewTopContraint: NSLayoutConstraint!
    
    var originObserver: NSKeyValueObservation?
    var destinationObserver: NSKeyValueObservation?
    
    deinit {
        print("💀 DEINIT \(URL(fileURLWithPath: #file).lastPathComponent)")
        originObserver?.invalidate()
        destinationObserver?.invalidate()
        stopLocationUpdate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideBackButtonText = true
        userButton.isHidden = mode.hideUserIcon
        startLocationUpdates()
        state = .search
        handleObservers()
        checkAuthorization()
        map.showsUserLocation = false
        map.tintColor = SearchMapController.configuration.palette.primary
        
        if mode == .driver {
            showSearchController()
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
        originObserver = bookingWrapper.observe(\.origin, changeHandler: { [weak self] (booking, change) in
            self?.handleBookingCard()
        })
        destinationObserver?.invalidate()
        destinationObserver = bookingWrapper.observe(\.destination, changeHandler: { [weak self] (booking, change) in
            self?.handleBookingCard()
        })
    }
    
    func handleBookingCard() {
        defer {
            if bookingWrapper.origin != nil && bookingWrapper.destination != nil {
                searchMapDelegate
                    .loadRoutes(for: bookingWrapper)
                    .done { [weak self] response in
                        guard let self = self else { return }
                        let anno = self.searchMapDelegate.annotations(for: self.bookingWrapper)
                        if anno.count > 0 {
                            self.map.removeAnnotations(self.map.annotations.filter({ $0 as? UserAnnotationView == nil }))
                            self.map.addAnnotations(anno)
                        }
                        // routes
                        if let route = response.directions.values.first {
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
                    .catch { _ in }
            }
        }
        guard bookingWrapper.origin != nil else {
            state = .search
            return
        }
        DispatchQueue.main.async { [weak self]  in
            self?.loadBookingReadyCard()
        }
    }
    
    func loadBookingReadyCard() {
        defer {
            configureTopView()
        }
        // no need to reload the view if it is already the right one
        guard cardContainer.subviews.first as? ChooseOptionsView == nil else { return }
        guard let view: ChooseOptionsView = Bundle.module.loadNibNamed("ChooseOptionsView", owner: nil)?.first as? ChooseOptionsView else { return }
        state = .bookingReady
        view.delegate = self
        view.vehicles = vehicles
        view.mode = mode
        view.groups = groups
        view.searchMapDelegate = delegate
        addViewToCard(view)
        view.configure(options: configurationOptions, booking: &bookingWrapper)
        topViewTopContraint.constant = 0
    }
    
    func configureTopView() {
        guard bookingWrapper.origin != nil else { return }
        originLabel.set(text: bookingWrapper.origin?.name, for: .body, textColor: SearchMapController.configuration.palette.textOnPrimary)
        let noDestination = bookingWrapper.destination?.name?.isEmpty ?? true == true
        destinationLabel.set(text: bookingWrapper.destination?.name ?? "no destination".bundleLocale(),
                             for: .body,
                             textColor: noDestination ? SearchMapController.configuration.palette.inactive : SearchMapController.configuration.palette.textOnPrimary)
    }
    
    func loadSearchCard() {
        // no need to reload the view if it is already the right one
        guard cardContainer.subviews.first as? MapLandingView == nil else { return }
        guard let view: MapLandingView = Bundle.module.loadNibNamed("MapLandingView", owner: nil)?.first as? MapLandingView else { return }
        view.delegate = self
        addViewToCard(view)
        topViewTopContraint.constant = -200
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
        card.round(corners: [.topLeft, .topRight], radius: 20.0)
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
        search()
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
    func search() {
        coordinatorDelegate?.showSearch(&bookingWrapper)
    }
}

extension SearchMapController: BookDelegate {
    func book(_ booking: BookingWrapper) -> Promise<Bool> {
        guard let delegate = delegate else {
            return Promise<Bool>.init { (resolver) in
                resolver.fulfill(false)
            }
        }
        return delegate.book(booking)
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
    
    func share(_ booking: BookingWrapper) {
        let choose = ChooseGroupsView.create(booking: booking, groups: groups, delegate: delegate)
        addViewToCard(choose)
    }
}

extension SearchMapController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
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
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let view = view as? UserAnnotationView, mode != .driver else { return }
        // push the search view with departure selected
        map.deselectAnnotation(view.annotation, animated: false)
        bookingWrapper.origin = view.placemark
        search()
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer { searchMapDelegate.renderer(for: overlay) }
}
