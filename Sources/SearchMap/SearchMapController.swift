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
//import AlertsAndPickers
import UIViewControllerExtension
import SwiftDate
import PromiseKit
import ATAGroup
import ATACommonObjects

public final class SearchMapController: UIViewController {
    var passenger: BasePassenger?
    var mode: DisplayMode = .driver
    var configurationOptions: OptionConfiguration!
    static var configuration: ATAConfiguration!
    static func create() -> SearchMapController {
        return UIStoryboard(name: "Map", bundle: .module).instantiateInitialViewController() as! SearchMapController
    }
    
    public enum State: Int, Comparable {
        public static func < (lhs: SearchMapController.State, rhs: SearchMapController.State) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
        
        case search = 0
        case bookingReady
        case shareWithGroup
        case lookingForDriver
        case rideStarted
        case rideEnded
        
        var backgroudColor: UIColor {
            switch self {
            case .search: return SearchMapController.configuration.palette.background
            default: return SearchMapController.configuration.palette.background
            }
        }
        
        var showBackButton: Bool {
            switch self {
            case .bookingReady, .shareWithGroup: return true
            default: return false
            }
        }
    }
    var state: State = .search  {
        didSet {
            switch state {
            case .search: loadSearchCard()
            default: ()
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
            destinationIndicator.backgroundColor = SearchMapController.configuration.palette.map.destination
        }
    }
    @IBOutlet weak var backOptionsButton: UIButton!  {
        didSet {
            backOptionsButton.addShadow()
            backOptionsButton.isHidden = true
        }
    }

    lazy var bookingWrapper = CreateRide(passenger: self.passenger)
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
            locatioButton.addShadow()
        }
    }
    @IBOutlet weak var leadingUserButtonConstraint: NSLayoutConstraint!
    @IBOutlet weak var trailingUserButtonConstraint: NSLayoutConstraint!
    @IBOutlet weak var userButton: UIButton!  {
        didSet {
            userButton.roundedCorners = true
            userButton.addShadow()
            userButton.backgroundColor = SearchMapController.configuration.palette.secondary
            userButton.tintColor = SearchMapController.configuration.palette.background
        }
    }
    
    func updateUserpicture(with image: UIImage?) {
        guard userButton != nil else { return }
        userButton.contentMode = .scaleAspectFill
        userButton.setImage(image ?? UIImage(named: "passenger", in: .module, compatibleWith: nil), for: .normal)
        userButton.layer.borderWidth = 1.0
        userButton.layer.borderColor = SearchMapController.configuration.palette.secondary.cgColor
    }
    @IBOutlet public weak var card: UIView!
    @IBOutlet public weak var cardContainer: UIView!  {
        didSet {
            cardContainer.clipsToBounds = true
        }
    }
    @IBOutlet weak var bookingTopView: UIView!  {
        didSet {
            bookingTopView.layer.cornerRadius = 25
            bookingTopView.addShadow(roundCorners: false, useMotionEffect: false)
            bookingTopView.backgroundColor = SearchMapController.configuration.palette.background
            bookingTopView.isHidden = true
        }
    }
    @IBOutlet weak var cardBottomConstraint: NSLayoutConstraint!
    
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
        card.cornerRadius = 20.0
        cardContainer.cornerRadius = 20.0
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    var handleKeyboard: Bool = true
    @objc func adjustForKeyboard(notification: Notification) {
        guard handleKeyboard, state > .search else { return }
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        if notification.name == UIResponder.keyboardWillHideNotification {
            print("⌨ OFFSET ZERO")
            cardContainer.updateConstraints(animated: true, duration: 0.3, useSpringWithDamping: 0.8, initialVelocity: 0.2) { [weak self] in
                self?.cardBottomConstraint.constant = 8
            }
            showTopElements(true)
        } else {
            print("⌨ OFFSET \(keyboardScreenEndFrame.height - view.safeAreaInsets.bottom)")
            showTopElements(false)
            cardContainer.setNeedsLayout()
            cardContainer.updateConstraints(animated: true, duration: 0.3, useSpringWithDamping: 0.8, initialVelocity: 0.2) { [weak self] in
                guard let self = self else { return }
                self.cardBottomConstraint.constant = 8 + keyboardScreenEndFrame.height - self.view.safeAreaInsets.bottom
            }
        }
    }
    
    public func showAddresses(_ show: Bool) {
        bookingTopView.isHidden = !show
    }
    
    func showTopElements(_ show: Bool) {
        bookingTopView.isHidden = !show
        userButton.isHidden = !show
    }
    
    @objc func navigationBack() {
        delegate.back()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        handleKeyboard = true
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        handleKeyboard = false
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        card.addShadow(roundCorners: false, shadowOffset: CGSize(width: -5, height: 0))
        bookingTopView.layer.cornerRadius = 10.0
        bookingTopView.addShadow(roundCorners: false, shadowOffset: CGSize(width: -5, height: 0))
    }
    
    func updateUserBackButton() {
        switch mode {
        case .driver:
            userButton.setImage(UIImage(named: "back", in: .module, compatibleWith: nil)?.withAlignmentRectInsets(UIEdgeInsets(top: 0, left: -25, bottom: 0, right: 0)), for: .normal)
            userButton.backgroundColor = .clear
            userButton.layer.borderWidth = 0
            userButton.removeTarget(nil, action: nil, for: .allTouchEvents)
            userButton.tintColor = SearchMapController.configuration.palette.mainTexts
            userButton.addTarget(self, action: #selector(navigationBack), for: .touchUpInside)
            leadingUserButtonConstraint.constant = 0
            trailingUserButtonConstraint.constant = 4
            
        default: ()
        }
    }
    
    var userAddress: Address?
    func startLocationUpdates() {
        guard mode == .passenger else { return }
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
                        guard let self = self,
                              let placemark = placemarks?.first else { return }
//                        self.cardContainer.subViews(type: MapLandingView.self).first?.updateAddress(with: placemark)
                        if let coord = placemark.location?.coordinate {
                            self.userAddress = Address(name: placemark.name, address: placemark.formattedAddress, coordinates: coord)
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
        originObserver = bookingWrapper.ride.observe(\.fromAddress, changeHandler: { [weak self] (booking, change) in
            self?.handleBookingCard()
        })
        destinationObserver?.invalidate()
        destinationObserver = bookingWrapper.ride.observe(\.toAddress, changeHandler: { [weak self] (booking, change) in
            self?.handleBookingCard()
        })
    }
    
    func handleBookingCard() {
        defer {
            if bookingWrapper.ride.fromAddress != nil && bookingWrapper.ride.toAddress != nil {
                RideDirectionManager
                    .shared
                    .loadDirections(for: bookingWrapper.ride, sortCriteria: .shortestDistance) { [weak self] ride, routes in
                        guard let self = self else { return }
                        let anno = self.searchMapDelegate.annotations(for: self.bookingWrapper)
                        if anno.count > 0 {
                            self.map.removeAnnotations(self.map.annotations.filter({ $0 as? UserAnnotationView == nil }))
                            self.map.addAnnotations(anno)
                        }
                        // routes
                        if let route = routes.first(where: { $0.routeType == .ride })?.route {
                            self.searchMapDelegate.routeReady(route)
                            let overlays = self.searchMapDelegate.overlays(for: route)
                            if let overlay = overlays.first {
                                self.map.removeOverlays(self.map.overlays)
                                self.map.addOverlay(overlay)
                                self.map.setVisibleMapRect(route.polyline.boundingMapRect,
                                                           edgePadding: UIEdgeInsets(top: self.bookingTopView.frame.maxY,
                                                                                     left: self.locatioButton.frame.width + 20,
                                                                                     bottom: self.locatioButton.frame.height + 30,
                                                                                     right: 50),
                                                           animated: true)
                            }
                        }
                    }
            }
        }
        guard bookingWrapper.ride.fromAddress != nil else {
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
    
    func loadPaymentOptionsCard() {
        // no need to reload the view if it is already the right one
        guard cardContainer.subviews.first as? ChoosePaymentView == nil else { return }
        
        delegate
            .willShowCards()
            .done({ [weak self] cardAdded in
            guard let self = self, cardAdded == true else { return }
            let view: ChoosePaymentView = ChoosePaymentView.create(booking: &self.bookingWrapper, searchDelegate: self.delegate, delegate: self)
            self.optionState = .payment
    //        view.delegate = self
            self.addViewToCard(view)
            })
            .catch { _ in }
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
        view.configure(options: configurationOptions, booking: &bookingWrapper, passenger: passenger)
    }
    
    func loadCard(for state: OptionState) {
        switch state {
        case .default: loadOptionsCard()
        case .vehicleOptions: loadVehicleOptionsCard()
        case .payment: loadPaymentOptionsCard()
        case .passenger: loadPassengerOptionsCard()
        }
    }
    
    func configureTopView() {
        guard bookingWrapper.ride.fromAddress != nil else { return }
        originLabel.set(text: bookingWrapper.ride.fromAddress?.address, for: .footnote, textColor: SearchMapController.configuration.palette.mainTexts)
        let noDestination = bookingWrapper.ride.toAddress?.address?.isEmpty ?? true == true
        destinationLabel.set(text: bookingWrapper.ride.toAddress?.address ?? "no destination".bundleLocale(),
                             for: .footnote,
                             textColor: noDestination ? SearchMapController.configuration.palette.inactive : SearchMapController.configuration.palette.mainTexts)
    }
    
    func loadSearchCard() {
        // no need to reload the view if it is already the right one
        guard cardContainer.subviews.first as? MapLandingView == nil else { return }
        guard let view: MapLandingView = Bundle.module.loadNibNamed("MapLandingView", owner: nil)?.first as? MapLandingView else { return }
        view.delegate = self
        view.confirmButton.isHidden = mode == .driver
        map.removeOverlays(map.overlays)
        map.removeAnnotations(map.annotations)
        zoomOnUser()
        backOptionsButton.isHidden = true
        addViewToCard(view)
        bookingTopView.isHidden = true
//        if let adr = userAddress {
//            view.updateAddress(with: adr)
//        }
    }
    
    func addViewToCard(_ view: UIView) {
        cardContainer.subviews.forEach({ $0.removeFromSuperview() })
        cardContainer.addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    // for passenger purposes...
    public func update(state: State, with card: UIView) {
        self.state = state
        addViewToCard(card)
        backOptionsButton.isHidden = !state.showBackButton
        bookingTopView.isHidden = true
    }
    // when ride is done
    public func resetState() {
        state = .search
        loadSearchCard()
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
    
    @IBAction func changeUserLocationType() {
        switch map.userTrackingMode {
        case .none: map.userTrackingMode = .follow
        case .follow: map.userTrackingMode = .followWithHeading
        default: map.userTrackingMode = .none
        }
    }
    
    @IBAction func showSearchController() {
        coordinatorDelegate?.showSearch(&bookingWrapper, animated: true)
    }
    
    @IBAction func showMenu() {
        delegate.showMenu()
    }
    
    internal func zoomOnUser(location: CLLocationCoordinate2D? = nil) {
        guard CLLocationManager.authorizationStatus() == .authorizedWhenInUse else { return }
        let coordinates = location ?? map.userLocation.coordinate
        if CLLocationCoordinate2DIsValid(coordinates) {
            map.setRegion(MKCoordinateRegion(center: coordinates, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)), animated: true)
        }
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
        if let adr = userAddress {
            bookingWrapper.ride.fromAddress = adr
        }
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
        state = .shareWithGroup
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
        bookingWrapper.ride.fromAddress = view.placemark
        search(animated: true)
    }
    
    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer { searchMapDelegate.renderer(for: overlay) }
}

extension SearchMapController: OptionViewDelegate {
    func next() {
        guard let state = optionState.next(for: mode) else {
            return
        }
        loadCard(for: state)
    }
}

extension SearchMapController: ChooseGroupNavigationDelegate {
    @IBAction func back() {
        guard self.state != .shareWithGroup else {
            state = .bookingReady
            loadCard(for: .passenger)
            return
        }
        guard let state = optionState.previous(for: mode) else {
            if mode == .passenger {
                loadSearchCard()
            }
            return
        }
        loadCard(for: state)
    }
}
