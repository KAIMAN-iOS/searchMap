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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: true)
        loadSearchCard()
        checkAuthorization()
        map.showsUserLocation = false
        map.tintColor = #colorLiteral(red: 1, green: 0.192286253, blue: 0.2298730612, alpha: 1)
    }
    
    func loadSearchCard() {
        guard let view: MapLandingView = Bundle.module.loadNibNamed("MapLandingView", owner: nil)?.first as? MapLandingView else { return }
        view.delegate = self
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
    }
    
    @IBAction func changeUserLocationType() {
        switch map.userTrackingMode {
        case .none: map.userTrackingMode = .follow
        case .follow: map.userTrackingMode = .followWithHeading
        default: map.userTrackingMode = .none
        }
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
        // push the search view with no start position
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
    }
}
