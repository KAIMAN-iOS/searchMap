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

class SearchMapController: UIViewController {
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
    var bookingWrapper = BookingWrapper()
    weak var coordinatorDelegate: SearchMapCoordinatorDelegate?
    
    let geocoder = CLGeocoder()
    @IBOutlet weak var map: MKMapView!  {
        didSet {
            map.delegate = self
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
    @IBOutlet weak var bookingTopView: BookingTopView!
    @IBOutlet weak var topViewTopContraint: NSLayoutConstraint!
    
    var originObserver: NSKeyValueObservation?
    var destinationObserver: NSKeyValueObservation?
    
    deinit {
        print("💀 DEINIT \(URL(fileURLWithPath: #file).lastPathComponent)")
        originObserver?.invalidate()
        destinationObserver?.invalidate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: true)
        loadSearchCard()
        handleObservers()
        checkAuthorization()
        map.showsUserLocation = false
        map.tintColor = #colorLiteral(red: 1, green: 0.192286253, blue: 0.2298730612, alpha: 1)
        if #available(iOS 14.0, *) {
            self.navigationItem.backButtonDisplayMode = .minimal
        } else {
            navigationItem.backButtonTitle = ""
        }
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
        guard bookingWrapper.origin != nil, bookingWrapper.destination != nil else {
            loadSearchCard()
            return
        }
        loadBookingReadyCard()
    }
    
    func loadBookingReadyCard() {
        // no need to reload the view if it is already the right one
        guard cardContainer.subviews.first as? BookingReadyView == nil else { return }
        guard let view: BookingReadyView = Bundle.module.loadNibNamed("BookingReadyView", owner: nil)?.first as? BookingReadyView else { return }
        view.delegate = self
        addViewToCard(view)
        topViewTopContraint.constant = 0
        bookingTopView.configure(bookingWrapper)
    }
    
    func loadSearchCard() {
        // no need to reload the view if it is already the right one
        guard cardContainer.subviews.first as? MapLandingView == nil else { return }
        guard let view: MapLandingView = Bundle.module.loadNibNamed("MapLandingView", owner: nil)?.first as? MapLandingView else { return }
        view.delegate = self
        addViewToCard(view)
        topViewTopContraint.constant = -100
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
        map.showsUserLocation = false
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
            map.showsUserLocation = true
            
        default:
            locatioButton.isHidden = true
            map.showsUserLocation = false
        }
    }
}

class UserAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
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

extension SearchMapController: BookingReadyDelegate {
    func book() {
        
    }
}

extension SearchMapController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        geocoder.cancelGeocode()
        geocoder.reverseGeocodeLocation(userLocation.coordinate.asLocation) { [weak self] (placemarks, error) in
            guard let self = self, let placemark = placemarks?.first else { return }
            self.map.addAnnotation(UserAnnotation(placemark: placemark))
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? UserAnnotation,
              let view: UserAnnotationView = Bundle.module.loadNibNamed("UserAnnotationView", owner: nil)?.first as? UserAnnotationView else { return nil }
        view.configure(annotation.placemark)
        view.tintColor = #colorLiteral(red: 1, green: 0.192286253, blue: 0.2298730612, alpha: 1)
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
