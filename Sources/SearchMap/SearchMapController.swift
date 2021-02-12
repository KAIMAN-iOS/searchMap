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

class SearchMapController: UIViewController {
    var mode: DisplayMode = .driver
    static var configuration: ATAConfiguration!
    static func create() -> SearchMapController {
        return UIStoryboard(name: "Map", bundle: .module).instantiateInitialViewController() as! SearchMapController
    }
    
    enum State {
        case search
        case bookingReady
    }
    var state: State = .search  {
        didSet {
            switch state {
            case .search: loadSearchCard()
            case .bookingReady: ()
            }
        }
    }
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
            bookingTopView.layer.cornerRadius = 10
            bookingTopView.addShadow(roundCorners: false)
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
        userButton.isHidden = mode.hideUserIcon
        navigationController?.setNavigationBarHidden(true, animated: true)
        startLocationUpdates()
        loadSearchCard()
        handleObservers()
        checkAuthorization()
        map.showsUserLocation = false
        map.tintColor = SearchMapController.configuration.palette.primary
        if #available(iOS 14.0, *) {
            self.navigationItem.backButtonDisplayMode = .minimal
        } else {
            navigationItem.backButtonTitle = ""
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
        guard bookingWrapper.origin != nil else {
            loadSearchCard()
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
        view.delegate = self
        addViewToCard(view)
        view.configure()
        topViewTopContraint.constant = 0
    }
    
    func configureTopView() {
        guard bookingWrapper.origin != nil else { return }
        originLabel.set(text: bookingWrapper.origin?.name, for: .body, textColor: SearchMapController.configuration.palette.mainTexts)
        let noDestination = bookingWrapper.destination?.name?.isEmpty ?? true == true
        destinationLabel.set(text: bookingWrapper.destination?.name ?? "no destination".bundleLocale(),
                             for: .body,
                             textColor: noDestination ? SearchMapController.configuration.palette.lightGray : SearchMapController.configuration.palette.secondaryTexts)
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
    func book() {
        
    }
    
    func chooseDate(actualDate: Date, completion: @escaping ((Date) -> Void)) {
        
        let alertController = UIAlertController(title: "departure date".local(), message: nil, preferredStyle: .actionSheet)
        alertController.addDatePicker(mode: .dateAndTime, date: actualDate, minimumDate: Date(), maximumDate: nil) { [weak self] date in
            completion(date)
        }
        alertController.addAction(title: "OK".bundleLocale(), style: .cancel)
        alertController.view.tintColor = SearchMapController.configuration.palette.mainTexts
        present(alertController, animated: true, completion: nil)
    }
}

extension SearchMapController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? UserAnnotation,
              let view: UserAnnotationView = Bundle.module.loadNibNamed("UserAnnotationView", owner: nil)?.first as? UserAnnotationView else { return nil }
        view.configure(annotation.placemark)
        view.tintColor = SearchMapController.configuration.palette.primary
        view.layoutIfNeeded()
        view.centerOffset = CGPoint(x: 0, y: -view.bounds.midY)
        return view
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let view = view as? UserAnnotationView else { return }
        // push the search view with departure selected
        map.deselectAnnotation(view.annotation, animated: false)
        bookingWrapper.origin = view.placemark
        search()
    }
}
