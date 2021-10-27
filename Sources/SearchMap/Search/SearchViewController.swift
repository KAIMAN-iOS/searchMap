//
//  File.swift
//  
//
//  Created by GG on 25/10/2020.
//

import UIKit
import UIViewExtension
import MapKit
import CoreLocation
import ActionButton
import ATACommonObjects
import TextFieldExtension

protocol SearchViewControllerDelegate: NSObjectProtocol {
    func showMapPicker(for location: BookingPlaceType, coordinates: CLLocationCoordinate2D?)
    func close()
}

extension Address {
    var asPlacemark: Placemark { Placemark(name: name, address: address, coordinates: coordinates, countryCode: countryCode, cp: cp) }
}

class SearchViewController: UIViewController {
    var mode: DisplayMode = .driver
    weak var favDelegate: FavouriteDelegate?  {
        didSet {
            viewModel.favDelegate = favDelegate
        }
    }

    static func create(booking: inout CreateRide,
                       userAddress: Address? = nil,
                       searchDelegate: SearchViewControllerDelegate) -> SearchViewController {
        let ctrl: SearchViewController =  UIStoryboard(name: "Map", bundle: .module).instantiateViewController(identifier: "SearchViewController") as! SearchViewController
        ctrl.booking = booking
        ctrl.startAddress = userAddress?.asPlacemark
        ctrl.booking.ride.fromAddress = userAddress?.asPlacemark
        ctrl.searchDelegate = searchDelegate
        return ctrl
    }
    weak var searchDelegate: SearchViewControllerDelegate?
    var userCoordinates: CLLocationCoordinate2D?
    
    var lastTypeDate: Date = Date()
    lazy var dispatchItem = DispatchWorkItem { [weak self] in
        if abs(self?.lastTypeDate.timeIntervalSinceNow ?? 0) > 0.45 {
            self?.performSearch()
        }
    }
    @IBOutlet weak var closeButton: UIButton!
    lazy var mapButton: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "map", in: .module, compatibleWith: nil), for: .normal)
        btn.addTarget(self, action: #selector(showMap), for: .touchUpInside)
        btn.tintColor = SearchMapController.configuration.palette.mainTexts
        return btn
    } ()
    @IBOutlet weak var validateButton: ActionButton!  {
        didSet {
            validateButton.shape = .rounded(value: 10.0)
            validateButton.setTitle("validate".bundleLocale().uppercased(), for: .normal)
            validateButton.actionButtonType = .primary
        }
    }

    @IBOutlet weak var validateContainer: UIView!
    @IBOutlet weak var originTextField: UITextField!  {
        didSet {
            originTextField.text = ""
            originTextField.placeholder = "Enter origin".bundleLocale()
            originTextField.delegate = self
            originTextField.tintColor = SearchMapController.configuration.palette.primary
            originTextField.addKeyboardControlView(target: originTextField, buttonStyle: .footnote)
        }
    }
    @IBOutlet weak var originIndicator: UIView!  {
        didSet {
            originIndicator.roundedCorners = true
            originIndicator.backgroundColor = SearchMapController.configuration.palette.confirmation
        }
    }

    @IBOutlet weak var destinationTextField: UITextField!  {
        didSet {
            destinationTextField.text = ""
            destinationTextField.placeholder = "Enter destination".bundleLocale()
            destinationTextField.delegate = self
            destinationTextField.tintColor = SearchMapController.configuration.palette.primary
            destinationTextField.addKeyboardControlView(target: destinationTextField, buttonStyle: .footnote)
        }
    }
    @IBOutlet weak var destinationIndicator: UIView! {
        didSet {
            destinationIndicator.roundedCorners = true
            destinationIndicator.backgroundColor = SearchMapController.configuration.palette.map.destination
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

    @IBOutlet weak var tableView: UITableView!  {
        didSet {
            tableView.tableFooterView = UIView()
            tableView.register(UINib(nibName: "PlacemarkCell", bundle: .module), forCellReuseIdentifier: "PlacemarkCell")
        }
    }
    @IBOutlet weak var card: UIView!
    var isLoading: Bool = false  {
        didSet {
            switch (isLoading, textFieldHasFocus) {
            case (true, _):
                let loader = UIActivityIndicatorView(style: .medium)
                loader.color = SearchMapController.configuration.palette.primary
                loader.startAnimating()
                navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loader)
                
            case (false, false):
                navigationItem.rightBarButtonItem = nil
                
            case (false, true):
                navigationItem.rightBarButtonItem = UIBarButtonItem(customView: mapButton)
                navigationItem.rightBarButtonItem?.tintColor = SearchMapController.configuration.palette.mainTexts
            }
        }
    }

    
    var booking: CreateRide!
    var searchType: BookingPlaceType? = nil
    var originObserver: NSKeyValueObservation?
    var destinationObserver: NSKeyValueObservation?
    let viewModel = SearchViewModel()
    weak var coordinatorDelegate: SearchMapCoordinatorDelegate?  {
        didSet {
            viewModel.coordinatorDelegate = coordinatorDelegate
        }
    }
    
    deinit {
        print("💀 DEINIT \(URL(fileURLWithPath: #file).lastPathComponent)")
        originObserver?.invalidate()
        destinationObserver?.invalidate()
        startAddress = nil
        endAddress = nil
        booking.ride.toAddress = nil
        booking.ride.fromAddress = nil
    }
    
    @IBAction func close() {
        searchDelegate?.close()
    }
    
    @IBAction func validate() {
        guard startAddress != endAddress else {
            alertSameAddress()
            return
        }
        guard let list = CityCode.citycodesForCountry(country: "FR") else {
            return
        }
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: startAddress?.coordinates.latitude ?? 0.0, longitude: startAddress?.coordinates.longitude ?? 0.0)) { [weak self] items, error in
            guard let self = self else {return}
            guard error == nil, let locality = items?.first?.locality else {
                self.alertBadAddress()
                return
            }
            let filteredList: [CityCode] = list.filter({ $0.name.range(of: locality, options: [.caseInsensitive, .diacriticInsensitive]) != nil })
            self.startAddress?.code = filteredList.first?.code
            self.booking.ride.fromAddress = self.startAddress
            self.booking.ride.toAddress = self.endAddress
            self.searchDelegate?.close()
        }
    }
    
    private func alertSameAddress() {
        let alertController = UIAlertController(title: "Attention".local(), message: "Addresses can't be the same".bundleLocale(), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK".local(), style: .cancel, handler: { _ in }))
        alertController.view.tintColor = SearchMapController.configuration.palette.primary
        present(alertController, animated: true, completion: nil)
    }
    
    private func alertBadAddress() {
        let alertController = UIAlertController(title: "Attention".local(), message: "Erreur code INSEE", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK".local(), style: .cancel, handler: { _ in }))
        alertController.view.tintColor = SearchMapController.configuration.palette.primary
        present(alertController, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
        DispatchQueue.main.async { [weak self] in
            if self?.startAddress != nil {
                self?.destinationTextField.becomeFirstResponder()
            } else {
                self?.originTextField.becomeFirstResponder()
            }
        }
    }
    
    var textFieldHasFocus: Bool = false  {
        didSet {
            switch textFieldHasFocus {
            case true:
                navigationItem.rightBarButtonItem = UIBarButtonItem(customView: mapButton)
                
            case false:
//                if viewModel.items[.search] == nil {
//                    viewModel.clear(dataSource: datasource)
//                }
                navigationItem.rightBarButtonItem = nil
            }
        }
    }
    
    @IBAction func showMap() {
        guard let searchType = searchType else { return }
        searchDelegate?.showMapPicker(for: searchType,
                                      coordinates: searchType == .origin ? startAddress?.asCoordinates2D : endAddress?.asCoordinates2D)
    }
    
    @objc dynamic var startAddress: Placemark?
    @objc dynamic var endAddress: Placemark?
    func didChoose(_ placemark: CLPlacemark) {
        guard let searchType = searchType else { return }
        switch searchType {
        case .origin: startAddress = placemark.asPlacemark
        case .destination: endAddress = placemark.asPlacemark
        }
    }
    
    lazy var datasource = viewModel.dataSource(for: tableView)
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.displayMode = mode
        view.backgroundColor = SearchMapController.configuration.palette.background
        tableView.backgroundColor = SearchMapController.configuration.palette.background
        hideBackButtonText = true
        handleValidateButton()
        handleObservers()
        handleKeyboard()
        handleTableView()
        
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navBarAppearance.backgroundColor = SearchMapController.configuration.palette.background
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
    }
    
    func handleTableView() {
        tableView.dataSource = datasource
        tableView.delegate = self
        viewModel.refreshDelegate = self
    }
    
    func handleObservers() {
        if let adr = startAddress {
            originTextField.text = adr.address
        } else if let adr = booking.ride.fromAddress?.asPlacemark {
            originTextField.text = adr.address
            startAddress = adr
            handleValidateButton()
        }
        if let adr = endAddress {
            destinationTextField.text = adr.address
        } else if let adr = booking.ride.toAddress?.asPlacemark {
            destinationTextField.text = adr.address
            endAddress = adr
            handleValidateButton()
        }
        //destinationTextField.text = booking.ride.toAddress?.address
        
        originObserver?.invalidate()
        originObserver = self.observe(\.startAddress, changeHandler: { [weak self] (booking, change) in
            self?.handleValidateButton()
            guard let origin = self?.startAddress else { return }
            self?.originTextField.text = origin.address
        })
        destinationObserver?.invalidate()
        destinationObserver = self.observe(\.endAddress, changeHandler: { [weak self] (booking, change) in
            self?.handleValidateButton()
            guard let destination = self?.endAddress else { return }
            self?.destinationTextField.text = destination.address
        })
    }
    
    func handleKeyboard() {
        NotificationCenter.default.addObserver(forName: UIApplication.keyboardWillShowNotification, object: nil, queue: nil) { [weak self] notification in
            guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            self?.tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: frame.height, right: 0)
            self?.textFieldHasFocus = true
        }
        NotificationCenter.default.addObserver(forName: UIApplication.keyboardWillHideNotification, object: nil, queue: nil) { [weak self] _ in
            self?.tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
            self?.textFieldHasFocus = false
        }
    }
    
    func handleValidateButton() {
        validateContainer.isHidden = startAddress == nil || endAddress == nil
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        card.layer.cornerRadius = 20.0
        card.addShadow(roundCorners: false, shadowColor: SearchMapController.configuration.palette.mainTexts.cgColor, shadowOffset: CGSize(width: 5, height: 5), shadowRadius: 5, shadowOpacity: 0.2, useMotionEffect: true)
    }
    
    var search: MKLocalSearch!
    func performSearch() {
        guard let text = searchType == .origin ? originTextField.text : destinationTextField.text else {
            // clear TV
            return
        }
        isLoading = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = text
        request.resultTypes = [.pointOfInterest, .address]
        if let coord = userCoordinates {
            request.region = MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10))
        }
        search = MKLocalSearch(request: request)
        search.start { [weak self] response, _ in
            guard let self = self else { return }
            var items: [Placemark] = []
            defer {
                self.viewModel.applySearchSnapshot(in: self.datasource, results: items, animatingDifferences: true)
                self.isLoading = false
            }
            guard let response = response else {
                return
            }
            items = response.mapItems.compactMap { item -> Placemark in
                item.placemark.asPlacemark
            }
        }
    }
    
    func clearBooking() {
//        guard let searchType = searchType else { return }
        switch searchType {
        case .origin: startAddress = nil
        case .destination: endAddress = nil
        default : ()
        }
    }
    
    func updateBooking(_ place: Placemark) {
        guard let searchType = searchType else { return }
        switch searchType {
        case .origin: startAddress = place
        case .destination: endAddress = place
        }
    }
}

extension SearchViewController: RefreshFavouritesDelegate {
    func refresh(force: Bool) {
        // reload only if there are no search
        if (viewModel.items[.search] == nil && textFieldHasFocus) || force {
            reload(force: force)
        }
    }
    
    func reload(force: Bool = false) {
        viewModel.reload(withFavourites: force)
        viewModel.applyPendingSnapshot(in: datasource)
    }
}

extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // nothing if no textfield is selected
        guard destinationTextField.isFirstResponder || originTextField.isFirstResponder else { return }
        guard let place = viewModel.placemark(at: indexPath) else { return }
        updateBooking(place)
        
        if searchType == .origin && endAddress == nil {
            destinationTextField.becomeFirstResponder()
            searchType = .destination
            refresh(force: false)
        } else {
            view.endEditing(true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 2
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return viewModel.contextMenuConfigurationForRow(at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return viewModel.swipeActionsConfigurationForRow(at: indexPath, in: tableView)
    }
}

extension SearchViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // reset booking since user typed
        clearBooking()
        search?.cancel()
        // reload history if no search
        if let text = textField.text,
              let textRange = Range(range, in: text),
              text.replacingCharacters(in: textRange, with: string).isEmpty {
            reload()
        } else {
            lastTypeDate = Date()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: dispatchItem)
        }
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.searchType = textField == originTextField ? .origin : .destination
        clearBooking()
        search?.cancel()
        reload()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
//        searchType = nil
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.searchType = textField === originTextField ? .origin : .destination
        if textField.text?.isEmpty ?? true == true {
            reload()
        }
    }
}
